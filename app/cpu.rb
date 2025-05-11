class CPU

  attr_accessor(:clock, :r, :ram)


  def initialize(rom)
    @cycles = 0
    @decoder = Decoder.new(self)
    @r = Registers.new
    @rom = rom
    @ram = Array.new(0x8000, 0)
    @halted = false
  end


  def run
    loop do
      @cycles += @decoder.decode_and_execute(current_op)

      @r.pc += 1

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
    @rom[@r.pc]
  end


  def next
    @r.pc += 1
  end


  def halt!
    @halted = true
  end

end
