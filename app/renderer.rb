class Renderer

  attr_writer(:fps)

  SCALE = 4


  def initialize(ppu)
    @ppu = ppu
    @fps = 60
    @last_frame_time = Time.at(0)
    @texture = nil
  end


  def open_window
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(PPU::WIDTH*SCALE, PPU::HEIGHT*SCALE, 'GBR')
    image = Raylib.GenImageColor(PPU::WIDTH, PPU::HEIGHT, Raylib::RAYWHITE)
    image.format = Raylib::PIXELFORMAT_UNCOMPRESSED_R8G8B8
    @texture = Raylib.LoadTextureFromImage(image)
  end


  def render_frame
    return unless Time.now - @last_frame_time > 1.0/@fps

    if Raylib.WindowShouldClose
      Raylib.CloseWindow
      exit
    end

    Raylib.BeginDrawing
      Raylib.ClearBackground(Raylib::RAYWHITE)
      Raylib.UpdateTexture(@texture, @ppu.pixels.pack('C*'))
      Raylib.DrawTextureEx(@texture, Raylib::Vector2.create(0, 0), 0.0, SCALE, Raylib::RAYWHITE)
    Raylib.EndDrawing

    @last_frame_time = Time.now
  end

end
