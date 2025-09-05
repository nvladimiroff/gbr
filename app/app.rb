class App

  def run
    rom = File.read(ARGV[0]).bytes
    gb = Gameboy.new(rom)
    renderer = Renderer.new(gb.ppu)
    renderer.open_window

    loop do
      gb.step
      renderer.render_frame
    end
  end

end
