class PPU

  attr_accessor(:scy, :scx, :wx, :wy)
  attr_reader(:pixels, :ly)

  WIDTH = 160
  HEIGHT = 144
  # Borrowed the palette from Gambatte: https://github.com/libretro/gambatte-libretro/blob/13b7af780e9893ae62cc24d567591b5eb6a6dd72/libgambatte/libretro/gbcpalettes.h#L32
  COLOR_MAP = {
    0 => 0x578200FF,
    1 => 0x317400FF,
    2 => 0x005121FF,
    3 => 0x00420CFF
  }


  def initialize(interrupts)
    @interrupts = interrupts
    @mode = :oam
    @clock = 0
    @pixels = Array.new(WIDTH*HEIGHT, 0)
    @vram = Array.new(0x2000, 0)
    @oam = Array.new(0xA0, 0xFF)
    @lcdc = 0x91
    @stat = 0x05

    @scx = 0
    @scy = 0

    @wx = 0
    @wy = 0

    @ly = 0
  end


  def step(**opts)
    return  unless lcd_enabled?

    @clock += opts[:by]

    case @mode
    when :oam
      transition(:draw) if elapsed(cycles: 80)
    when :draw
      if elapsed(cycles: 172)
        render_scanline
        transition(:hblank)
      end
    when :hblank
      if elapsed(cycles: 204)
        @ly += 1

        if last_visible_line?
          @interrupts.fire(:vblank)
          transition(:vblank)
        else
          transition(:oam)
        end
      end
    when :vblank
      if elapsed(cycles: 456)
        @ly += 1

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
      # TODO: LCD status
      0xFF
    when 0xFF42
      @scy
    when 0xFF43
      @scx
    when 0xFF44
      @ly
    when 0xFF45
      # TODO: LYC
      0xFF
    when 0xFF46
      # TODO: DMA (does this belong here?)
      0xFF
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
      @lcdc
    when 0xFF41
      # TODO: LCD status
    when 0xFF42
      @scy = value
    when 0xFF43
      @scx = value
    when 0xFF44
      # LY isn't writable.
    when 0xFF45
      # TODO: LYC
    when 0xFF46
      # TODO: DMA (does this belong here?)
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

    def elapsed(**opts)
      if @clock >= opts[:cycles]
        @clock -= opts[:cycles]
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
      puts "LCDC: #{@lcdc.to_s(2)}"
      render_bg_scanline if background_enabled?
      render_sprite_scanline if sprites_enabled?
    end


    def render_bg_scanline
      y = (@ly + @scy) & 0xFF
      tile_row = (y / 8) * 32

      WIDTH.times do |pixel|
        x = pixel + @scx

        tile_col = x / 8
        tile_map_address = tile_map_start + tile_row + tile_col
        if tile_data_signed?
          tile_map_address = to_signed_byte(tile_map_address)
        end
        tile_index = @vram[tile_map_address]

        line = (y % 8) * 2

        byte_1 = @vram[tile_index * 16 + line]
        byte_2 = @vram[tile_index * 16 + line + 1]

        color = byte_1[7 - (pixel % 8)] + byte_2[7 - (pixel % 8)]
        @pixels[@ly * WIDTH + pixel] = COLOR_MAP[color]
      end
    end


    def render_sprite_scanline
      40.times do |sprite_index|
        sprite = read_sprite(sprite_index)

        # Is this sprite on the current scanline?
        if @ly >= sprite[:y] && @ly < (sprite[:y] + 8)
          line = @ly - sprite[:y]

          byte_1 = @vram[sprite[:tile] * 16 + line]
          byte_2 = @vram[sprite[:tile] * 16 + line + 1]

          8.times do |pixel|
            color = byte_1[7 - (pixel % 8)] + byte_2[7 - (pixel % 8)]
            @pixels[@ly * WIDTH + pixel] = COLOR_MAP[color]
          end
        end
      end
    end


    def read_sprite(index)
      y = @oam[index * 4] - 16
      x = @oam[index * 4 + 1] - 8
      tile = @oam[index * 4 + 2]
      _attributes = @oam[index * 4 + 3]

      {
        x:,
        y:,
        tile:
      }
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


    def tile_map_start
      # TODO: support window here too
      @lcdc[3] == 1 ? 0x1C00 : 0x1800
    end


    def tile_data_start
      @lcdc[4] == 1 ? 0x0000 : 0x0800
    end


    def tile_data_signed?
      @lcdc[4] != 1
    end


    def window_enabled?
      @lcdc[6] == 1
    end


    def lcd_enabled?
      @lcdc[7] == 1
    end


end
