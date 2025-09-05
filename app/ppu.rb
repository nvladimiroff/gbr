class PPU

  attr_reader(:pixels, :ly)

  WIDTH = 160
  HEIGHT = 144
  COLOR_MAP = {
    0 => 0xFFFFFFFF,
    1 => 0xFFAAAAAA,
    2 => 0xFF555555,
    3 => 0xFF000000
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
      bg_map_row = y / 32

      WIDTH.times do |pixel|
        x = pixel + @scx
        bg_map_col = x / 32
        tile_index = @vram[0x1800 + bg_map_row * 32 + bg_map_col]

        line = (y % 8) * 2

        byte_1 = @vram[tile_index * 16 + line]
        byte_2 = @vram[tile_index * 16 + line + 1]

        color = byte_1[pixel % 8] + byte_2[pixel % 8]
        #puts "COLO #{color} FROM #{tile_index} IT'S #{byte_1.to_hex} #{byte_2.to_hex} at #{pixel}x#{@ly}"
        @pixels[@ly * WIDTH + pixel] = COLOR_MAP[color]
      end
    end

end
