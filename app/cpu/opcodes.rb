module CPU::Opcodes

  def execute
    case current_op
    when 0x00 then noop
    when 0x01 then ld(:bc, :n16)
    when 0x02 then ld(:at_bc, :a)
    when 0x03 then inc(:bc)
    when 0x04 then inc(:b)
    when 0x05 then dec(:b)
    when 0x06 then ld(:b, :n8)
    when 0x07 then rlca
    when 0x08 then ld(:at_n16, :sp)
    when 0x09 then add(:hl, :bc)
    when 0x0A then ld(:b, :at_bc)
    when 0x0B then dec(:bc)
    when 0x0C then inc(:c)
    when 0x0D then dec(:c)
    when 0x0E then ld(:c, :n8)
    when 0x0F then rrca
    when 0x10 then stop
    when 0x11 then ld(:de, :n16)
    when 0x12 then ld(:at_de, :a)
    when 0x13 then inc(:de)
    when 0x14 then inc(:d)
    when 0x15 then dec(:d)
    else
      $logger.warn("[OP] Unimplemented opcode: #{current_op.to_s(16)}")
    end
  end

end
