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

end
