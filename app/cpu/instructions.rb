module CPU::Instructions

  private

    # Helpers

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


    def condition_met?(condition)
      case condition
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
    end


    # Instructions

    def nop
    end


    def ld(dest, src)
      value = load(src)
      assign(dest, value)
    end


    def and_(dest, src)
      dest_value = load(dest)
      src_value = load(dest)
      result = dest_value & src_value

      assign(dest, result)

      self.zero_flag = result == 0
      self.subtract_flag = false
      self.carry_flag = false
      self.half_carry_flag = true
    end


    def or_(dest, src)
      dest_value = load(dest)
      src_value = load(dest)
      result = dest_value | src_value

      assign(dest, result)

      self.zero_flag = result == 0
      self.subtract_flag = false
      self.carry_flag = false
      self.half_carry_flag = false
    end


    def xor(dest, src)
      dest_value = load(dest)
      src_value = load(src)
      result = dest_value ^ src_value

      assign(dest, result)

      self.zero_flag = result == 0
      self.subtract_flag = false
      self.carry_flag = false
      self.half_carry_flag = false
    end


    def jr(*args)
      increment = args.length == 1 ? args.first : args.second

      @pc = load(increment) + @pc if condition_met?(args.first)
    end


    def jp(*args)
      address = args.length == 1 ? args.first : args.second

      @pc = load(address) if condition_met?(args.first)
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


    def call(*args)
      if condition_met?(args.first)
        location = args.length == 1 ? args.first : args.second
        address = load(location)

        @sp -= 2
        @mmu.write_word(@sp, @pc)
        @pc = address
      end
    end


    def ret
      @pc = @mmu.read_word(@sp)
      @sp += 2
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
      src_value = load(src)
      dst_value = load(dest)
      new_value = src_value + dst_value + (self.carry_flag ? 1 : 0)
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.carry_flag = new_value > 0xFF
      self.half_carry_flag = (src_value & 0xF) + (dst_value & 0xF) + (self.carry_flag ? 1 : 0) > 0xF;
    end


    def sub(dest, src)
      src_value = load(src)
      dst_value = load(dest)
      new_value = dst_value - src_value
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < 0xFF
      self.half_carry_flag = (dst_value & 0xF) - (src_value & 0xF) > 0xF;
    end


    def sbc(dest, src)
      src_value = load(src)
      dst_value = load(dest)
      new_value = src_value - dst_value - (self.carry_flag ? 1 : 0)
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = new_value < 0xFF
      self.half_carry_flag = (src_value & 0xF) - (dst_value & 0xF) - (self.carry_flag ? 1 : 0) > 0xF;
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


    def push(src)
      value = load(src)
      @sp -= 2
      @mmu.write_word(@sp, value)
    end


    def pop(dst)
      value = @mmu.read_word(@sp)
      @sp += 2
      assign(dst, value)
    end


    def rra
      new_value = a >> 1
      new_value |= self.carry_flag ? 0x80 : 0x00

      self.carry_flag = a & 0x80 == 0x80
      self.a = new_value
    end


    def cp(dest, src)
      src_value = load(src)
      dst_value = load(dest)
      new_value = dst_value - src_value

      self.zero_flag = new_value == 0
      self.subtract_flag = true
      self.carry_flag = src_value > dst_value
      self.half_carry_flag = (dst_value & 0xF) - (src_value & 0xF) > 0xF;
    end

end
