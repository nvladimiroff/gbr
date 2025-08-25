class Gameboy

  include CPU::Registers, Opcodes

  attr_reader(:mmu)
  reg_8_bit(:a, :b, :c, :d, :e, :f, :h, :l)
  reg_16_bit(:af, :bc, :de, :hl)


  def initialize(rom)
    @mmu = MMU.new(rom)
    @pc = 0x0100
    @sp = 0xfffe
    @ticks = 0

    @a = 0
    @b = 0
    @c = 0
    @d = 0
    @e = 0
    @f = 0
    @h = 0
    @l = 0

    @halted = false
    @ime = true
  end


  def send_interrupt(type)
    return unless interrupt_enabled(type)

    case type
    when :vblank
      @mmu[0xFF0F] |= 0x01
    when :lcd_stat
      @mmu[0xFF0F] |= 0x02
    when :timer_overflow
      @mmu[0xFF0F] |= 0x04
    when :serial
      @mmu[0xFF0F] |= 0x08
    when :joypad
      @mmu[0xFF0F] |= 0x10
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

      out.section("INTERRUPTS") do
        out.line("Pending interrupts: #{pending_interrupts}")
      end

      out.section("MEMORY") do
        memory_range.each_slice(16) do |group|
          out.row(*group.map { |addr| @mmu[addr].to_hex })
        end
      end
    end
  end


  def step
    pending_interrupts.each do |interrupt|
      next unless @ime
      handle_interrupt(interrupt)
    end

    unless @halted
      @op = @mmu[@pc]
      @pc += 1
      decode_and_execute(@op)
    else
      @ticks += 4
    end
  rescue => e
    $logger.error("Error during instruction: #{@op.to_hex}", :exception => e)
  end


  private

    def decode_and_execute(opcode)
      instructions = MAPPING[opcode]

      raise "Unimplemented opcode" unless instructions

      send(*instructions)
    end


    def pending_interrupts
      interrupts = []

      if @mmu[0xFF0F] & 0x01 == 1
        interrupts << :vblank
      end

      if @mmu[0xFF0F] & 0x02 == 1
        interrupts << :lcd_stat
      end

      if @mmu[0xFF0F] & 0x04 == 1
        interrupts << :timer_overflow
      end

      if @mmu[0xFF0F] & 0x08 == 1
        interrupts << :serial
      end

      if @mmu[0xFF0F] & 0x10 == 1
        interrupts << :joypad
      end

      interrupts
    end


    def interrupt_enabled(type)
      true
    end


    def handle_interrupt(type)
      case type
      when :vblank
        addr = 0x40
        @mmu[0xFF0F] &= 0b1111_1110
      when :lcd_stat
        addr = 0x48
        @mmu[0xFF0F] &= 0b1111_1101
      when :timer_overflow
        addr = 0x50
        @mmu[0xFF0F] &= 0b1111_1011
      when :serial
        addr = 0x58
        @mmu[0xFF0F] &= 0b1111_0111
      when :joypad
        addr = 0x60
        @mmu[0xFF0F] &= 0b1110_1111
      end

      @sp -= 2
      @mmu.write_word(@sp, @pc)
      @pc = addr
      @ime = false
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


    def halt
      @halted = true
    end


    def reti
      @ime = true
      @pc = @mmu.read_word(@sp)
      @sp += 2
    end


    def di
      @ime = false
    end


    def ei
      @ime = true
    end

end
