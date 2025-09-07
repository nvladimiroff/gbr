class Gameboy

  include CPU::Registers, CPU::Opcodes, CPU::Instructions, CPU::PrefixedInstructions

  attr_reader(:mmu, :ppu)
  attr_accessor(:sp)
  reg_8_bit(:a, :b, :c, :d, :e, :f, :h, :l)
  reg_16_bit(:af, :bc, :de, :hl)


  def initialize(rom)
    @cartridge = Cartridge.new(rom)
    @interrupts = Interrupts.new
    @ppu = PPU.new(@interrupts)
    @mmu = MMU.new(@cartridge, @ppu, @interrupts)
    @pc = 0x0100
    @sp = 0xfffe
    @ticks = 0

    # DMG initial values
    @a = 0x01
    @b = 0x00
    @c = 0x13
    @d = 0x00
    @e = 0xD8
    @f = 0xB0
    @h = 0x01
    @l = 0x4D

    @halted = false
  end


  def fire_interrupt(type)
    @interrupts.fire(type)
  end


  def dump_state(memory_range = 0x100..0x14F)
    Console.new.display_until_quit do |out|
      out.section("REGISTERS") do
        out.row(*%w(PC SP A B C D E F H L))
        out.row(*[@pc, @sp, @a, @b, @c, @d, @e, @f, @h, @l].map(&:to_hex))
      end

      out.section("INSTRUCTIONS") do
        out.line("Last instruction executed: #{MAPPING[@op]}")
        out.line("Next instruction: #{MAPPING[@mmu[@pc+1]]}")
      end

      out.section("INTERRUPTS") do
        out.line("Pending interrupts: #{@interrupts.pending_byte}")
      end

      out.section("MEMORY") do
        memory_range.each_slice(16) do |group|
          out.row(*group.map { |addr| @mmu[addr].to_hex })
        end
      end
    end
  end


  def step
    @interrupts.handle do |type, addr|
      @sp -= 2
      @mmu.write_word(@sp, @pc)
      @pc = addr
      @halted = false
    end

    unless @halted
      @op = @mmu[@pc]
      @pc += 1
      # $logger.debug("Running instruction", :payload => {
      #   :op => MAPPING[@op],
      #   :pc => @pc.to_hex
      # })
      decode_and_execute(@op)
    else
      @ticks += 4
    end

    @ppu.step(by: 4)
  rescue => e
    $logger.error("Error during instruction: #{@op.to_hex}", :exception => e)
    #raise
  end


  private

    def decode_and_execute(opcode)
      instructions = MAPPING[opcode]

      raise "Unimplemented opcode" unless instructions

      send(*instructions)
    end

end
