class CPU

  include CPU::Registers, CPU::Opcodes, CPU::Instructions, CPU::PrefixedInstructions

  attr_accessor(:sp)
  attr_reader(:pc, :op, :last_ticks)
  reg_8_bit(:a, :b, :c, :d, :e, :f, :h, :l)
  reg_16_bit(:af, :bc, :de, :hl)


  def initialize(mmu, interrupts)
    @mmu = mmu
    @interrupts = interrupts

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
      @pc = (@pc + 1) & 0xFFFF
      $logger.debug("Running instruction", :payload => {
        :op => MAPPING[@op],
        :pc => @pc.to_hex
      })
      decode_and_execute(@op)
    else
      @total_ticks += 4
    end
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
