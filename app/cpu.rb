class CPU

  include CPU::Registers, CPU::Opcodes, CPU::Instructions, CPU::PrefixedInstructions, CPU::Interrupts

  attr_accessor(:sp)
  attr_reader(:pc, :op, :last_ticks)
  reg_8_bit(:a, :b, :c, :d, :e, :h, :l) # F gets special handling
  reg_16_bit(:bc, :de, :hl) # AF gets special handling


  def initialize(mmu)
    @mmu = mmu

    @pc = 0x0100
    @sp = 0xfffe
    @total_ticks = 0
    @last_ticks = 4

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
  end


  def step
    handle_interrupts

    if @enable_ime_next_step
      @enable_ime_next_step = false
      @ime = true
    end

    @total_ticks += 4 # TODO: real timing
    return if @halted

    @prev_op = @op
    @op = @mmu[@pc]
    @pc = (@pc + 1) & 0xFFFF
    $logger.debug("Running instruction", :payload => {
      :op => MAPPING[@op],
      :pc => @pc.to_hex
    })
    decode_and_execute(@op)
  rescue => e
    $logger.error("Error during instruction: #{@op&.to_hex}", :exception => e)
  end


  private

    def decode_and_execute(opcode)
      instructions = MAPPING[opcode]

      raise "Unimplemented opcode" unless instructions

      send(*instructions)
    end

end
