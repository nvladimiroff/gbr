class PPU

  attr_accessor(:scy, :scx, :wx, :wy)
  attr_reader(:pixels, :ly, :lyc, :lcdc, :lcdc_stat)

  WIDTH = 160
  HEIGHT = 144
  # Borrowed the palette from Gambatte: https://github.com/libretro/gambatte-libretro/blob/13b7af780e9893ae62cc24d567591b5eb6a6dd72/libgambatte/libretro/gbcpalettes.h#L32
  COLOR_MAP = {
    0 => 0x578200FF,
    1 => 0x317400FF,
    2 => 0x005121FF,
    3 => 0x00420CFF
  }


  def initialize(cpu)
    @cpu = cpu
    @mode = :oam
    @clock = 0
    @pixels = Array.new(WIDTH*HEIGHT, COLOR_MAP[0])
    @vram = Array.new(0x2000, 0)
    @oam = Array.new(0xA0, 0xFF)
    @lcdc = 0x91
    @lcd_stat = 0x05

    @scx = 0
    @scy = 0

    @wx = 0
    @wy = 0

    @ly = 0
    @lyc = 0

    @internal_pixel = 0
  end


  def step(by)
    return  unless lcd_enabled?

    @clock += by

    case @mode
    when :oam
      transition(:draw) if elapsed(80)
    when :draw
      if elapsed(172)
        render_scanline
        transition(:hblank)
        @cpu.interrupt(:lcd_stat) if @ly == @lyc
      end
    when :hblank
      if elapsed(204)
        @ly += 1
        @cpu.interrupt(:lcd_stat) if @ly == @lyc

        if last_visible_line?
          @cpu.interrupt(:vblank)
          transition(:vblank)
        else
          transition(:oam)
        end
      end
    when :vblank
      if elapsed(456)
        @ly += 1
        @cpu.interrupt(:lcd_stat) if @ly == @lyc

        if last_line?
          @ly = 0
          transition(:oam)
        end
      end
    end
  end


  def [](addr)
    case addr
    when 0x8000..0x9FFF
      # VRAM
      @vram[addr - 0x8000]
    when 0xFE00..0xFE9F
      # Sprites
      @oam[addr - 0xFE00]
    when 0xFF40
      @lcdc
    when 0xFF41
      @lcd_stat
    when 0xFF42
      @scy
    when 0xFF43
      @scx
    when 0xFF44
      @ly
    when 0xFF45
      @lyc
    when 0xFF47
      # TODO: BGP
      0xFF
    when 0xFF48
      # TODO: OBGP0
      0xFF
    when 0xFF49
      # TODO: OBGP1
      0xFF
    when 0xFF4A
      @wy
    when 0xFF4B
      @wx
    end
  end


  def []=(addr, value)
    case addr
    when 0x8000..0x9FFF
      # VRAM
      @vram[addr - 0x8000] = value
    when 0xFE00..0xFE9F
      # Sprites
      @oam[addr - 0xFE00] = value
    when 0xFF40
      @lcdc = value
    when 0xFF41
      @lcd_stat = value
    when 0xFF42
      @scy = value
    when 0xFF43
      @scx = value
    when 0xFF44
      # LY isn't writable.
    when 0xFF45
      @lyc = value
    when 0xFF47
      # TODO: BGP
    when 0xFF48
      # TODO: OBGP0
    when 0xFF49
      # TODO: OBGP1
    when 0xFF4A
      @wy = value
    when 0xFF4B
      @wx = value
    end
  end


  private

    def elapsed(cycles)
      if @clock >= cycles
        @clock -= cycles
        true
      else
        false
      end
    end


    def transition(mode)
      @mode = mode
    end


    def last_visible_line?
      @ly == 144
    end


    def last_line?
      @ly == 154
    end


    def render_scanline
      return unless lcd_enabled?

      render_tiles
      render_sprite_scanline if sprites_enabled?
    end


    def render_tiles
      return unless window_enabled? || background_enabled?

      tile_y = case current_layer
      when :background
        ((@ly + @scy) & 0xFF) >> 3
      when :window
        (@ly - @wy) / 8
      end

      (0..WIDTH - 1).each do |pixel|
        @internal_pixel = pixel
        tile_x = case current_layer
        when :background
          (pixel + @scx) / 8
        when :window
          (pixel - (@wx - 7)) / 8
        end
        tile_x &= 0x1F

        tile_address = tile_map_start + tile_y * 32 + tile_x
        tile_index = @vram[tile_address]

        tile_location = if tile_data_signed?
          tile_data_start + (to_signed_byte(tile_index) + 128) * 16
        else
          tile_data_start + tile_index * 16
        end

        offset = case current_layer
        when :window
          2 * ((@ly - @wy) % 8)
        when :background
          2 * ((@ly + @scy) % 8)
        end

        byte_1 = @vram[tile_location + offset]
        byte_2 = @vram[tile_location + offset + 1]

        pixel_index = 7 - ((pixel + @scx) % 8)
        color = byte_1[pixel_index] | (byte_2[pixel_index] << 1)
        @pixels[@ly * WIDTH + pixel] = COLOR_MAP[color]
      end

    end


    def render_sprite_scanline
      sprites_per_line = 0
      40.times do |index|
        # Read the sprite
        y = @oam[index * 4] - 16
        x = @oam[index * 4 + 1] - 8
        tile = @oam[index * 4 + 2]
        attributes = @oam[index * 4 + 3]

        # Is this sprite on the current scanline?
        if @ly >= y && @ly < (y + 8)
          break if sprites_per_line >= 10
          line = @ly - y

          byte_1 = @vram[tile * 16 + line * 2]
          byte_2 = @vram[tile * 16 + line * 2 + 1]

          (0..7).each do |pixel|
            pixel_index = if attributes[5] == 0
              7 - pixel
            else
              pixel
            end
            color = byte_1[pixel_index] | (byte_2[pixel_index] << 1)
            current_pixel = @ly * WIDTH + x + pixel

            if attributes[7] == 0 || @pixels[current_pixel] == COLOR_MAP[0]
              @pixels[current_pixel] = COLOR_MAP[color] unless color == 0
            end
          end

          sprites_per_line += 1
        end
      end
    end


    def read_sprite(index)
      y = @oam[index * 4] - 16
      x = @oam[index * 4 + 1] - 8
      tile = @oam[index * 4 + 2]
      attributes = @oam[index * 4 + 3]

      {
        x:,
        y:,
        tile:,
        attributes:
      }
    end


    def to_signed_byte(byte)
      byte &= 0xff
      byte > 127 ? byte - 256 : byte
    end


    def background_enabled?
      @lcdc[0] == 1
    end


    def sprites_enabled?
      @lcdc[1] == 1
    end


    # TODO: what does this do?
    def sprite_size
      @lcdc[2]
    end


    def bg_tile_map_start
      @lcdc[3] == 1 ? 0x1C00 : 0x1800
    end


    def tile_data_start
      @lcdc[4] == 1 ? 0x0000 : 0x0800
    end


    def tile_data_signed?
      @lcdc[4] != 1
    end


    def window_enabled?
      @lcdc[5] == 1
    end


    def window_tile_map_start
      @lcdc[6] == 1 ? 0x1C00 : 0x1800
    end


    def lcd_enabled?
      @lcdc[7] == 1
    end


    def current_layer
      if window_enabled? && @wy <= @ly && @wx <= @internal_pixel
        :window
      else
        :background
      end
    end


    def tile_map_start
      case current_layer
      when :background
        @lcdc[3] == 1 ? 0x1C00 : 0x1800
      when :window
        @lcdc[6] == 1 ? 0x1C00 : 0x1800
      end
    end

end
