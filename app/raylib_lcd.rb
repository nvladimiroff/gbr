class RaylibLCD

  attr_writer(:fps)

  SCALE = 4


  def initialize
    @fps = 60
    @last_frame_time = Time.at(0)
    @texture = nil
  end


  def open_window(title)
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(PPU::WIDTH*SCALE, PPU::HEIGHT*SCALE, "GBR - #{title}")
    image = Raylib.GenImageColor(PPU::WIDTH, PPU::HEIGHT, Raylib::RAYWHITE)
    image.format = Raylib::PIXELFORMAT_UNCOMPRESSED_R8G8B8A8
    @texture = Raylib.LoadTextureFromImage(image)
  end


  def render_frame(pixels)
    return unless Time.now - @last_frame_time > 1.0/@fps

    if Raylib.WindowShouldClose
      Raylib.CloseWindow
      exit
    end

    Raylib.BeginDrawing
      Raylib.ClearBackground(Raylib::RAYWHITE)
      Raylib.UpdateTexture(@texture, pixels.pack('N*'))
      Raylib.DrawTextureEx(@texture, Raylib::Vector2.create(0, 0), 0.0, SCALE, Raylib::RAYWHITE)
    Raylib.EndDrawing

    @last_frame_time = Time.now
  end

end
