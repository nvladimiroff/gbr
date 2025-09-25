class CPU

  include CPU::Registers, CPU::Opcodes, CPU::Instructions, CPU::PrefixedInstructions, CPU::Interrupts, CPU::Timing

  attr_accessor(:sp, :pc, :ie, :if)
  attr_reader(:op, :last_cycles)


  def initialize(mmu)
    @mmu = mmu

    @pc = 0x0100
    @sp = 0xfffe
    @last_cycles = 0

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
    @ime = true
    @ie = 0x00
    @if = 0x00
  end


  def step
    @last_cycles = 0
    handle_interrupts

    if @enable_ime_next_step
      @enable_ime_next_step = false
      @ime = true
    end

    if @halted
      @last_cycles += 4
      return
    end


    @prev_op = @op
    @op = @mmu[@pc]
    @pc = (@pc + 1) & 0xFFFF
    decode_and_execute(@op)

    @last_cycles += TIMING[@op].first # TODO: timing for instructions with varying cycles
  rescue => e
    $logger.error("Error during instruction: #{@op&.to_hex}", :exception => e)
  end


  private

    def decode_and_execute(opcode)
      send(*MAPPING[opcode])
    end

end
