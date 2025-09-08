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
      reg.to_s.length > 1 && reg != :n8
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


    def to_signed_byte(byte)
      byte &= 0xff
      byte > 127 ? byte - 256 : byte
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
      src_value = load(src)
      result = (dest_value | src_value) & 0xFF

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
      location = args.length == 1 ? args.first : args.second
      increment = to_signed_byte(load(location))

      @pc = increment + @pc if condition_met?(args.first)
    end


    def jp(*args)
      location = args.length == 1 ? args.first : args.second
      address = load(location)

      @pc = address if condition_met?(args.first)
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
      @interrupts.ime = false
    end


    def ei
      @interrupts.ime = true
    end


    def call(*args)
      location = args.length == 1 ? args.first : args.second
      address = load(location)

      if condition_met?(args.first)
        @sp -= 2
        @mmu.write_word(@sp, @pc)
        @pc = address
      end
    end


    def ret(*args)
      if condition_met?(args.first)
        @pc = @mmu.read_word(@sp)
        @sp += 2
      end
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
      if reg_is_16bit?(dest)
        inc16(dest)
      else
        inc8(dest)
      end
    end


    def inc8(dest)
      value = load(dest)
      new_value = (value + 1) & 0xFF
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.half_carry_flag = (value & 0xF) + 1 > 0xF;
    end


    def inc16(dest)
      value = load(dest)
      new_value = (value + 1) & 0xFFFF
      assign(dest, new_value)
    end


    def dec(dest)
      if reg_is_16bit?(dest)
        dec16(dest)
      else
        dec8(dest)
      end
    end


    def dec8(dest)
      value = load(dest)
      new_value = (value - 1) & 0xFF
      assign(dest, new_value)

      self.zero_flag = (new_value & 0xFF) == 0
      self.subtract_flag = true
      self.half_carry_flag = (value & 0xF) - 1 > 0xF;
    end


    def dec16(dest)
      value = load(dest)
      new_value = (value - 1) & 0xFFFF
      assign(dest, new_value)
    end


    def push(src)
      @sp -= 2
      value = load(src)
      @mmu.write_word(@sp, value)
    end


    def pop(dst)
      value = @mmu.read_word(@sp)
      assign(dst, value)
      @sp += 2
    end


    def rr(dest)
      dest_value = load(dest)
      new_value = dest_value >> 1
      new_value |= self.carry_flag ? 0x80 : 0x00

      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.half_carry_flag = false
      self.carry_flag = dest_value[0] == 1
    end


    def rra
      rr(:a)

      # this is always false for RRA for whatever reason.
      self.zero_flag = false
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


    def rlca
      new_value = a << 1

      self.carry_flag = a & 0x80 == 0x80
      self.a = new_value

      self.zero_flag = false
      self.subtract_flag = false
      self.half_carry_flag = false
    end


    def stop(*args)
      # Stop is confusing, but no licensed game uses it.
    end


    def rst(address)
      @sp -= 2
      @mmu.write_word(@sp, @pc)
      @pc = address
    end


    def rrca
      new_value = a >> 1

      self.carry_flag = a & 0x01 == 0x01
      self.a = new_value

      self.zero_flag = false
      self.subtract_flag = false
      self.half_carry_flag = false
    end


    def ldh(dest, src)
      src_value = case src
      when :a then a
      when [:c] then @mmu[0xFF00 + c]
      when [:n8] then @mmu[0xFF00 + n8]
      end

      case dest
      when :a then self.a = src_value
      when [:c] then @mmu[0xFF00 + c] = src_value
      when [:n8] then @mmu[0xFF00 + n8] = src_value
      end
    end


    def ldd(dest, src)
      ld(dest, src)
      self.hl = hl - 1
    end


    def ldi(dest, src)
      ld(dest, src)
      self.hl = hl + 1
    end


    def cpl
      self.a = ~a & 0xFF

      self.subtract_flag = true
      self.half_carry_flag = true
    end


    def swap(dest)
      dest_value = load(dest)
      upper = dest_value >> 4
      lower = dest_value & 0x0F
      new_value = (lower << 4) | upper

      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.half_carry_flag = false
      self.carry_flag = false
    end


    def scf
      self.subtract_flag = false
      self.half_carry_flag = false
      self.carry_flag = true
    end


    def srl(dest)
      dest_value = load(dest)
      new_value = dest_value >> 1
      assign(dest, new_value)

      self.zero_flag = new_value == 0
      self.subtract_flag = false
      self.half_carry_flag = false
      self.carry_flag = dest_value & 0x01 > 0
    end


    def ccf
      self.subtract_flag = false
      self.half_carry_flag = false
      self.carry_flag = !carry_flag
    end

end
