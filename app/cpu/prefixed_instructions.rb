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

end
