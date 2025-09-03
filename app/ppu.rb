class PPU

  attr_reader(:pixels)

  WIDTH = 160
  HEIGHT = 144
  SCALE = 5

  def initialize
    @mode = :oam
    @clock = 0
    @pixels = Array.new(WIDTH * HEIGHT, 1)
    @vram = Array.new(0x2000, 0)

    @scx = 0
    @scy = 0

    @wx = 0
    @wy = 0

    # Complicated sprite stuff

    @ly = 0
  end


  def step(**opts)
    @clock += opts[:by]

    case @mode
    when :oam
      # Duration: 80
      transition(:draw)
    when :draw
      # Duration: 174?
      render
      transition(:hblank)
      # draw scanline
    when :hblank
      # Duration: 204
      if last_line?
        transition(:vblank)
      else
        transition(:oam)
      end
    when :vblank
      # Duration: 4560
      # fire interrupt handler
      transition(:oam)
    end
  end


  def [](addr)
    @vram[addr]
  end


  def []=(addr, value)
    @vram[addr] = value
  end


  private

    def transition(mode)
      @mode = mode
    end


    def last_line?
      true
    end


    def render
      in_render_loop do
        # Background
        (0x1800..0x1BFF).each_with_index do |addr, i|
          draw_tile(i % 32, (i / 32).floor, @vram[addr])
        end
      end
    end


    def draw_tile(x, y, tile)
      8.times do |row|
        byte_1 = @vram[tile * 16 + row * 2]
        byte_2 = @vram[tile * 16 + row * 2 + 1]

        8.times do |i|
          color = byte_1[i] + byte_2[i]
          draw_pixel(x*8+i, y*8+row, color)
        end
      end
    end


    def draw_pixel(x, y, byte_color)
      # Override in subclasses
    end


    def in_render_loop
      # Override in subclasses
      yield
    end

end
