module CPU::PrefixedInstructions

  def prefix
    instruction = CPU::Opcodes::CB_MAPPING[@mmu[@pc]]
    @pc = (@pc + 1) & 0xFFFF

    send(*instruction)
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


  def set(i, dst)
    value = load(dst)
    new_value = value | (1 << i)
    assign(dst, new_value)
  end


  def res(i, dst)
    value = load(dst)
    new_value = value & ~(1 << i)
    assign(dst, new_value)
  end


  def bit(i, src)
    value = load(src)
    self.zero_flag = value[i] == 0
    self.subtract_flag = false
    self.half_carry_flag = true
  end


  def rl(dest)
    value = load(dest)
    new_value = (value << 1) & 0xFF
    new_value |= self.carry_flag ? 1 : 0
    assign(dest, new_value)

    self.zero_flag = new_value == 0
    self.subtract_flag = false
    self.half_carry_flag = false
    self.carry_flag = value[7] == 1
  end


  def rlc(dest)
    dst_value = load(dest)
    new_value = (dst_value << 1) | (dst_value >> 7)
    new_value &= 0xFF

    self.carry_flag = dst_value[7] == 1
    assign(dest, new_value)

    self.zero_flag = new_value == 0
    self.subtract_flag = false
    self.half_carry_flag = false
  end


  def rrc(dest)
    dst_value = load(dest)
    new_value = ((dst_value >> 1) | (dst_value << 7)) & 0xFF

    self.carry_flag = dst_value[0] == 1
    assign(dest, new_value)

    self.zero_flag = new_value == 0
    self.subtract_flag = false
    self.half_carry_flag = false
  end


  def sra(dest)
    dst_value = load(dest)
    new_value = (dst_value >> 1) | (dst_value[7] << 7)
    assign(dest, new_value)

    self.zero_flag = new_value == 0
    self.subtract_flag = false
    self.carry_flag = dst_value[0] == 1
    self.half_carry_flag = false
  end


  def srl(dest)
    dest_value = load(dest)
    new_value = (dest_value >> 1)
    assign(dest, new_value)

    self.zero_flag = new_value == 0
    self.subtract_flag = false
    self.half_carry_flag = false
    self.carry_flag = dest_value & 0x01 > 0
  end

end
