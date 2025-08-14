class Gameboy

  include CPU::Registers

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


  private

    def step
      op = @mmu[@pc]
      @pc += 1
      decode_and_execute(op)
    rescue => e
      $logger.error("Error during instruction: 0x#{@mmu[@pc].to_s(16)}", :exception => e)
    end


    def halt
      @halted = true
    end


    def ld(dest, src)
      value = load(src)

      if dest.start_with?('at_')
        location = send(dest[3..])
        @mmu[location] = value
      else
        send("#{dest}=", value)
      end

    end


    def load(sym)
      if sym.start_with?('at_')
        sym = sym[3..]
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


    def add(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = value + old_value

      if dest.start_with?('at_')
        location = send(dest[3..])
        @mmu[location] = new_value
      else
        send("#{dest}=", new_value)
      end

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.carry_flag = new_value > self.a
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def adc(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = value + old_value + (self.carry_flag ? 1 : 0)

      if dest.start_with?('at_')
        location = send(dest[3..])
        @mmu[location] = new_value
      else
        send("#{dest}=", new_value)
      end

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.carry_flag = new_value > self.a
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def sub(dest, src)
      value = load(src)
      old_value = load(dest)
      new_value = old_value - value

      if dest.start_with?('at_')
        location = send(dest[3..])
        @mmu[location] = new_value
      else
        send("#{dest}=", new_value)
      end

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < self.a
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def sbc(value)
      new_value = a - value - (self.carry_flag ? 1 : 0)
      self.a = new_value

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < self.a
      self.half_carry_flag = (a & 0xF) + (value & 0xF) > 0xF;
    end


    def decode_and_execute(opcode)
      case opcode
      when 0x00
        # no-op
      when 0x01
        ld(:bc, :n16)
      when 0x02
        ld(:at_bc, :a)
      when 0x03
        inc(:bc)
      when 0x04
        inc(:b)
      when 0x05
        dec(:b)
      when 0x06
        ld(:b, :n8)
      when 0x07
        rlca
      when 0x08
        ld(:at_n16, :sp)
      when 0x09
        add(:hl, :bc)
      when 0x0A
        ld(:b, :at_bc)
      when 0x0B
        dec(:bc)
      when 0x0C
        inc(:c)
      when 0x0D
        dec(:c)
      when 0x0E
        ld(:c, :n8)
      when 0x0F
        rrca
      when 0x10
        halt
      when 0x11
        ld(:de, :n16)
      when 0x12
        ld(:at_de, :a)
      when 0x13
        inc(:de)
      when 0x14
        inc(:d)
      when 0x15
        dec(:d)
      when 0x16
        ld(:d, :n8)
      when 0x17
        rla
      when 0x18
        jump(:n8)
      when 0x19
        add(:hl, :de)
      when 0x1a
        ld(:a, :at_de)
      when 0x1b
        dec(:de)
      when 0x1c
        inc(:e)
      when 0x1d
        dec(:e)
      when 0x1e
        ld(:e, :n8)
      when 0x1f
        rra
      when 0x20
        jump(:n8, cond: :nz)
      when 0x21
        ld(:hl, :n16)
      when 0x22
        ld(:at_hl_plus, :a)
      when 0x23
        inc(:hl)
      when 0x24
        inc(:h)
      when 0x25
        dec(:h)
      when 0x26
        ld(:h, :n8)
      when 0x27
        daa
      when 0x28
        jump(:n8, cond: :z)
      when 0x29
        add(:hl, :de)
      when 0x2a
        ld(:a, :at_de)
      when 0x2b
        ld(:a, :at_de)
      when 0x2c
        inc(:l)
      when 0x2d
        dec(:l)
      when 0x2e
        ld(:e, :n8)
      when 0x2f
        cpl
      when 0x30
        jump(:n8, cond: :nc)
      when 0x31
        ld(:sp, :n16)
      when 0x32
        ld(:at_hl_minus, :a)
      when 0x33
        inc(:sp)
      when 0x34
        inc(:at_hl)
      when 0x35
        dec(:at_hl)
      when 0x36
        ld(:at_hl, :n8)
      when 0x37
        scf
      when 0x38
        jump(:n8, cond: :c)
      when 0x39
        add(:hl, :sp)
      when 0x3a
        ld(:a, :at_hl_minus)
      when 0x3b
        dec(:sp)
      when 0x3c
        inc(:a)
      when 0x3d
        dec(:a)
      when 0x3e
        ld(:a, :n8)
      when 0x3f
        ccf
      when 0x40
        ld(:b, :b)
      when 0x41
        ld(:b, :c)
      when 0x42
        ld(:b, :d)
      when 0x43
        ld(:b, :e)
      when 0x44
        ld(:b, :h)
      when 0x45
        ld(:b, :l)
      when 0x46
        ld(:b, :at_hl)
      when 0x47
        ld(:b, :a)
      when 0x48
        ld(:c, :b)
      when 0x49
        ld(:c, :c)
      when 0x4a
        ld(:c, :d)
      when 0x4b
        ld(:c, :e)
      when 0x4c
        ld(:c, :h)
      when 0x4d
        ld(:c, :l)
      when 0x4e
        ld(:c, :at_hl)
      when 0x4f
        ld(:c, :a)
      when 0x50
        ld(:d, :b)
      when 0x51
        ld(:d, :c)
      when 0x52
        ld(:d, :d)
      when 0x53
        ld(:d, :e)
      when 0x54
        ld(:d, :h)
      when 0x55
        ld(:d, :l)
      when 0x56
        ld(:d, :at_hl)
      when 0x57
        ld(:d, :a)
      when 0x58
        ld(:e, :b)
      when 0x59
        ld(:e, :c)
      when 0x5a
        ld(:e, :d)
      when 0x5b
        ld(:e, :e)
      when 0x5c
        ld(:e, :h)
      when 0x5d
        ld(:e, :l)
      when 0x5e
        ld(:e, :at_hl)
      when 0x5f
        ld(:e, :a)
      when 0x60
        ld(:h, :b)
      when 0x61
        ld(:h, :c)
      when 0x62
        ld(:h, :d)
      when 0x63
        ld(:h, :e)
      when 0x64
        ld(:h, :h)
      when 0x65
        ld(:h, :l)
      when 0x66
        ld(:h, :at_hl)
      when 0x67
        ld(:h, :a)
      when 0x68
        ld(:l, :b)
      when 0x69
        ld(:l, :c)
      when 0x6a
        ld(:l, :d)
      when 0x6b
        ld(:l, :e)
      when 0x6c
        ld(:l, :h)
      when 0x6d
        ld(:l, :l)
      when 0x6e
        ld(:l, :at_hl)
      when 0x6f
        ld(:l, :a)
      when 0x70
        ld(:at_hl, :b)
      when 0x71
        ld(:at_hl, :c)
      when 0x72
        ld(:at_hl, :d)
      when 0x73
        ld(:at_hl, :e)
      when 0x74
        ld(:at_hl, :h)
      when 0x75
        ld(:at_hl, :l)
      when 0x76
        halt
      when 0x77
        ld(:at_hl, :a)
      when 0x78
        ld(:a, :b)
      when 0x79
        ld(:a, :c)
      when 0x7a
        ld(:a, :d)
      when 0x7b
        ld(:a, :e)
      when 0x7c
        ld(:a, :h)
      when 0x7d
        ld(:a, :l)
      when 0x7e
        ld(:a, :at_hl)
      when 0x7f
        ld(:a, :a)
      when 0x80
        add(:a, :b)
      when 0x81
        add(:a, :c)
      when 0x82
        add(:a, :d)
      when 0x83
        add(:a, :e)
      when 0x84
        add(:a, :h)
      when 0x85
        add(:a, :l)
      when 0x86
        add(:a, :at_hl)
      when 0x87
        add(:a, :a)
      when 0x88
        adc(:a, :b)
      when 0x89
        adc(:a, :c)
      when 0x8a
        adc(:a, :d)
      when 0x8b
        adc(:a, :e)
      when 0x8c
        adc(:a, :h)
      when 0x8d
        adc(:a, :l)
      when 0x8e
        adc(:a, :at_hl)
      when 0x8f
        adc(:a, :a)
      when 0x90
        sub(:a, :b)
      when 0x91
      when 0x92
      when 0x93
      when 0x94
      when 0x95
      when 0x96
      when 0x97
      when 0x98
      when 0x99
      when 0x9a
      when 0x9b
      when 0x9c
      when 0x9d
      when 0x9e
      when 0x9f
      when 0xa0
      when 0xa1
      when 0xa2
      when 0xa3
      when 0xa4
      when 0xa5
      when 0xa6
      when 0xa7
      when 0xa8
      when 0xa9
      when 0xaa
      when 0xab
      when 0xac
      when 0xad
      when 0xae
      when 0xaf
      when 0xb0
      when 0xb1
      when 0xb2
      when 0xb3
      when 0xb4
      when 0xb5
      when 0xb6
      when 0xb7
      when 0xb8
      when 0xb9
      when 0xba
      when 0xbb
      when 0xbc
      when 0xbd
      when 0xbe
      when 0xbf
      when 0xc0
      when 0xc1
      when 0xc2
      when 0xc3
      when 0xc4
      when 0xc5
      when 0xc6
      when 0xc7
      when 0xc8
      when 0xc9
      when 0xca
      when 0xcb
      when 0xcc
      when 0xcd
      when 0xce
      when 0xcf
      when 0xd0
      when 0xd1
      when 0xd2
      when 0xd3
      when 0xd4
      when 0xd5
      when 0xd6
      when 0xd7
      when 0xd8
      when 0xd9
      when 0xda
      when 0xdb
      when 0xdc
      when 0xdd
      when 0xde
      when 0xdf
      when 0xe0
      when 0xe1
      when 0xe2
      when 0xe3
      when 0xe4
      when 0xe5
      when 0xe6
      when 0xe7
      when 0xe8
      when 0xe9
      when 0xea
      when 0xeb
      when 0xec
      when 0xed
      when 0xee
      when 0xef
      when 0xf0
      when 0xf1
      when 0xf2
      when 0xf3
      when 0xf4
      when 0xf5
      when 0xf6
      when 0xf7
      when 0xf8
      when 0xf9
      when 0xfa
      when 0xfb
      when 0xfc
      when 0xfd
      when 0xfe
      when 0xff
      else
      end
    end

end
