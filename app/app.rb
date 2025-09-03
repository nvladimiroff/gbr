class App

  def run
    rom = File.read(ARGV[0]).bytes
    ppu = RaylibPPU.new
    gb = Gameboy.new(rom, ppu)
    ppu.open_window

    loop do
      gb.step
    end
  end

end
