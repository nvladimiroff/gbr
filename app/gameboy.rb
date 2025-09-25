class Gameboy

  attr_reader(:cpu, :mmu, :ppu, :lcd, :cartridge, :input, :joypad)
  delegate(*%i(a b c d e f l bc de hl), to: :@cpu)
  delegate(*%i(save load), to: :@cartridge)


  def initialize(rom, **opts)
    @lcd = opts[:lcd] || HeadlessLCD.new
    @joypad = Joypad.new
    @timers = Timers.new
    @cartridge = Cartridge.new(rom)
    @mmu = opts[:mmu] || MMU.new
    @cpu = CPU.new(@mmu)
    @ppu = PPU.new(@cpu)

    # TODO: this makes a cycle. Am I ok with that?
    @mmu.wire(@cpu, @cartridge, @ppu, @timers, @joypad)
    @lcd.ppu = @ppu
  end


  def step
    @cpu.step
    @ppu.step(@cpu.last_cycles)
    @timers.step(@cpu.last_cycles)
  end


  def fire_interrupt(type)
    @cpu.interrupt(type)
  end


  def cycles
    @cpu.last_cycles
  end


  private

    def print_debug_info
      puts "#{@cartridge.title} - TYPE: #{@cartridge.type.to_hex}"
    end

end
