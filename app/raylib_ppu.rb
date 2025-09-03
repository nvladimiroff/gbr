class RaylibPPU < PPU

  COLOR_MAP = {
    0 => Raylib::RAYWHITE,
    1 => Raylib::LIGHTGRAY,
    2 => Raylib::DARKGRAY,
    3 => Raylib::BLACK
  }


  def open_window
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(WIDTH*SCALE, HEIGHT*SCALE, 'GBR')
  end


  def in_render_loop
    if Raylib.WindowShouldClose
      Raylib.CloseWindow
      exit
    end

    Raylib.BeginDrawing
      Raylib.ClearBackground(Raylib::RAYWHITE)
      yield
    Raylib.EndDrawing

  end


  def draw_pixel(x, y, byte_color)
    color = COLOR_MAP[byte_color]
    Raylib.DrawRectangle(x * SCALE, y * SCALE, SCALE, SCALE, color)
  end

end
