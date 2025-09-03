class PPU

  attr_reader(:pixels)

  WIDTH = 160
  HEIGHT = 144
  SCALE = 5
  COLOR_MAP = {
    0 => Raylib::RAYWHITE,
    1 => Raylib::LIGHTGRAY,
    2 => Raylib::DARKGRAY,
    3 => Raylib::BLACK
  }


  def initialize
    @mode = :draw
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


  def open_window
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(WIDTH*SCALE, HEIGHT*SCALE, 'GBR')
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
      if Raylib.WindowShouldClose
        Raylib.CloseWindow
        exit
      end

      Raylib.BeginDrawing
        Raylib.ClearBackground(Raylib::RAYWHITE)
        draw_all
      Raylib.EndDrawing
    end


    def draw_all
      # Background
      y = 0
      (0x1800..0x1BFF).each_slice(32) do |row|
        x = 0
        row.each do |addr|
          draw_tile(x, y, @vram[addr])
          x += 1
        end
        y += 1
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
      color = COLOR_MAP[byte_color]
      Raylib.DrawRectangle(x * SCALE, y * SCALE, SCALE, SCALE, color)
    end

end
