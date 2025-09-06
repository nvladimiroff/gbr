class PPU

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


  def initialize
    @mode = :oam
    @clock = 0
    @disabled = false
    @pixels = Array.new(WIDTH*HEIGHT, 0)
    @vram = Array.new(0x2000, 0)

    @scx = 0
    @scy = 0

    @wx = 0
    @wy = 0

    # Complicated sprite stuff

    @ly = 0
  end


  def step(**opts)
    return  if @disabled

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
          # trigger vblank interrupt too
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
    @vram[addr]
  end


  def []=(addr, value)
    @vram[addr] = value
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
      render_bg_scanline
    end


    def render_bg_scanline
      y = @ly + @scy
      tile_row = (y / 8) * 32

      WIDTH.times do |pixel|
        x = pixel + @scx

        tile_col = x / 8
        tile_index = @vram[0x1800 + tile_row + tile_col]

        line = (y % 8) * 2

        byte_1 = @vram[tile_index * 16 + line]
        byte_2 = @vram[tile_index * 16 + line + 1]

        color = byte_1[7 - (pixel % 8)] + byte_2[7 - (pixel % 8)]
        @pixels[@ly * WIDTH + pixel] = COLOR_MAP[color]
      end
    end

end
