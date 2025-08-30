class App

  def run
    rom = File.read(ARGV[0]).bytes
    gb = Gameboy.new(rom)

    loop do
      gb.step
    rescue
      break
    end
  end


  def open_window
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(800, 640, 'Hello world')
    Raylib.SetTargetFPS(60)
  end

end
