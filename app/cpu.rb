class CPU

  include CPU::Decoder

  attr_accessor(:r, :mmu)


  def initialize(rom)
    @cycles = 0
    @r = Registers.new
    @halted = false
    @mmu = MMU.new(rom)
    load_opcodes
  end


  def run
    loop do
      @cycles += decode_and_execute(current_op)
      next_instruction

      break  if @halted
    end
  rescue => e
    $logger.error("Error during instruction: 0x#{current_op.to_s(16)}", :exception => e, :registers => @r)
  end


  def register(name)
    @r.send("#{name.downcase}")
  end


  def set_register(name, value)
    @r.send("#{name.downcase}=", value)
  end


  def current_op
    @mmu[@r.pc]
  end


  def next_instruction
    @r.pc += 1
  end


  def halt!
    @halted = true
  end

end
