module CPU::PrefixedInstructions

  def prefix
    instruction = CPU::Opcodes::CB_MAPPING[@mmu[@pc]]
    @pc += 1

    send(*instruction)
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
  end


  def rrc(dest)
  end


  def sra(dest)
  end


  def sla(dest)
  end


  def srl
  end

end
