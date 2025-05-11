class App

  def run
    rom = File.read(ARGV[0]).bytes
    cpu = CPU.new(rom)
    cpu.run
  end


  def open_window
    Raylib.load_lib('libraylib')
    Raylib.InitWindow(800, 640, 'Hello world')
    Raylib.SetTargetFPS(60)
  end

end
