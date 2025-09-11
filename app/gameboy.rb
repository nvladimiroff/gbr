class Gameboy

  attr_reader(:cpu, :mmu, :ppu)
  delegate(*%i(a b c d e f l bc de hl), to: :@cpu)


  def initialize(rom, lcd = nil)
    @lcd = lcd || HeadlessLCD.new
    @timers = Timers.new
    @cartridge = Cartridge.new(rom)
    @mmu = MMU.new
    @cpu = CPU.new(@mmu)
    @ppu = PPU.new(@cpu)

    # TODO: this makes a cycle (mmu => cpu => ppu => mmu)
    # Am I ok with that?
    @mmu.wire(@cartridge, @timers, @ppu)
  end


  def run
    @lcd.open_window(@cartridge.title)
    print_debug_info

    loop do
      step
    end
  end


  def step
    @cpu.step
    @ppu.step(by: @cpu.last_ticks)
    @timers.step(by: @cpu.last_ticks)
    @lcd.render_frame(@ppu.pixels)
  end


  def fire_interrupt(type)
    @cpu.interrupt(type)
  end


  def dump_state(memory_range = 0x100..0x14F)
    Console.new.display_until_quit do |out|
      out.section("REGISTERS") do
        out.row(*%w(PC SP A B C D E F H L))
        out.row(*[@cpu.pc, @cpu.sp, @cpu.a, @cpu.b, @cpu.c, @cpu.d, @cpu.e, @cpu.f, @cpu.h, @cpu.l].map(&:to_hex))
      end

      out.section("INSTRUCTIONS") do
        out.line("Last instruction executed: #{CPU::Opcodes::MAPPING[@cpu.op]}")
        out.line("Next instruction: #{CPU::Opcodes::MAPPING[@mmu[@cpu.pc+1]]}")
      end

      out.section("INTERRUPTS") do
        out.line("Pending interrupts: #{@interrupts[0xFF0F].to_hex}")
      end

      out.section("MEMORY") do
        memory_range.each_slice(16) do |group|
          out.row(*group.map { |addr| @mmu[addr].to_hex })
        end
      end
    end
  end


  private

    def print_debug_info
      puts "#{@cartridge.title} - TYPE: #{@cartridge.type.to_hex}"
    end

end
