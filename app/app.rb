class App

  def run
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(800, 640, 'Hello world')
    Raylib.SetTargetFPS(60)

    until Raylib.WindowShouldClose()
      Raylib.BeginDrawing
      Raylib.ClearBackground(Raylib::RAYWHITE)
      Raylib.DrawText('Hello world', 190, 200, 20, Raylib::LIGHTGRAY)
      Raylib.EndDrawing
    end

    Raylib.CloseWindow
  end

end
