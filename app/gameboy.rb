class Gameboy

  include CPU::Registers, Opcodes

  attr_reader(:mmu)
  reg_8_bit(:a, :b, :c, :d, :e, :f, :h, :l)
  reg_16_bit(:af, :bc, :de, :hl)


  def initialize(rom)
    @mmu = MMU.new(rom)
    @pc = 0x0100
    @sp = 0x0
    @cycles = 0

    @a = 0
    @b = 0
    @c = 0
    @d = 0
    @e = 0
    @f = 0
    @h = 0
    @l = 0
  end


  def run
    loop do
      step
    end
  end


  def run_for(**opts)
    opts[:limit].times do
      step
    end
  end


  def dump_state(memory_range = 0x100..0x14F)
    Console.new.display_until_quit do |out|
      out.section("REGISTERS") do
        out.row(*%w(PC SP A B C D E F H L))
        out.row(*[@pc, @sp, @a, @b, @c, @d, @e, @f, @h, @l].map(&:to_hex))
      end

      out.section("INSTRUCTIONS") do
        out.line("Last instruction executed: #{MAPPING[@op]}")
      end

      out.section("MEMORY") do
        memory_range.each_slice(16) do |group|
          out.row(*group.map { |addr| @mmu[addr].to_hex })
        end
      end
    end
  end


  private

    def step
      @op = @mmu[@pc]
      @pc += 1
      decode_and_execute(@op)
    rescue => e
      $logger.error("Error during instruction: #{@op.to_hex}", :exception => e)
      $logger.error(mmu.inspect)
    end


    def decode_and_execute(opcode)
      instructions = MAPPING[opcode]

      raise "Unimplemented opcode" unless instructions

      send(*instructions)
    end


    def load(sym)
      if sym.is_a?(Array)
        sym = sym[0]
        dereference = true
      end

      value = if sym == :n8
        n8
      elsif sym == :n16
        n16
      else
        send(sym)
      end

      if dereference
        value = @mmu[value]
      end

      value
    end


    def assign(sym, value)
      if sym.is_a?(Array)
        @mmu[load(sym[0])] = value
      else
        send("#{sym}=", value)
      end
    end


    def current_op
      @mmu[@pc]
    end


    def next_instruction
      @pc += 1
    end


    def n8
      value = @mmu[@pc]
      @pc += 1
      value
    end


    def n16
      lsb = @mmu[@pc]
      @pc += 1
      msb = @mmu[@pc]
      @pc += 1

      (msb << 8) + lsb
    end


    def lsb(word)
      word & 0x00FF
    end


    def msb(word)
      word & 0xFF00
    end


    def reg_is_16bit?(reg)
      reg.to_s.length > 1
    end


    def nop
    end


    def ld(dest, src)
      value = load(src)
      assign(dest, value)
    end


    def add(dest, src)
      src_value = load(src)
      dst_value = load(dest)
      new_value = src_value + dst_value
      assign(dest, new_value)

      if reg_is_16bit?(src)
        self.subtract_flag = false
        self.carry_flag = new_value > 0xFFFF
        self.half_carry_flag = (dst_value & 0xFFF) + (src_value & 0xFFF) > 0xFFF
      else
        self.zero_flag = new_value == 0
        self.subtract_flag = false
        self.carry_flag = new_value > 0xFF
        self.half_carry_flag = (dst_value & 0xF) + (src_value & 0xF) > 0xF
      end
    end


    def adc(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = value + old_value + (self.carry_flag ? 1 : 0)
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.carry_flag = new_value > 0xFF
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def sub(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = old_value - value
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < 0xFF
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def sbc(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = old_value - value - (self.carry_flag ? 1 : 0)
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < 0xFF
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def inc(dest)
      value = load(dest)
      new_value = value + 1
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.half_carry_flag = (value & 0xF) + 1 > 0xF;
    end


    def dec(dest)
      value = load(dest)
      new_value = value - 1
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.half_carry_flag = (value & 0xF) - 1 > 0xF;
    end


    def and_(dest, src)
      dest_value = load(dest)
      src_value = load(dest)
      result = dest_value & src_value

      assign(dest, result)

      self.zero_flag = result
      self.subtract_flag = false
      self.carry_flag = false
      self.half_carry_flag = true
    end


    def or_(dest, src)
      dest_value = load(dest)
      src_value = load(dest)
      result = dest_value | src_value

      assign(dest, result)

      self.zero_flag = result
      self.subtract_flag = false
      self.carry_flag = false
      self.half_carry_flag = false
    end


    def jr(*args)
      condition = case args.first
      when :z
        zero_flag
      when :nz
        !zero_flag
      when :c
        carry_flag
      when :nc
        !carry_flag
      else
        true
      end

      increment = args.length == 1 ? args.first : args.second

      @pc = load(increment) + @pc if condition
    end


    def jp(*args)
      condition = case args.first
      when :z
        zero_flag
      when :nz
        !zero_flag
      when :c
        carry_flag
      when :nc
        !carry_flag
      else
        true
      end

      address = args.length == 1 ? args.first : args.second

      @pc = load(address) if condition
    end

end
