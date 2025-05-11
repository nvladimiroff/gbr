module CPU::Decoder

  def load_opcodes
    opcodes_yml = YAML.load_file('config/opcodes.yaml')
    @unprefixed = opcodes_yml['unprefixed'].transform_keys { |key| key.to_i(16) }
    @cb_prefixed = opcodes_yml['cbprefixed'].transform_keys { |key| key.to_i(16) }
  end


  def decode_and_execute(opcode)
    instruction = @unprefixed[opcode]
    case instruction['mnemonic']
    when 'NOP' then nop(instruction)
    when 'LD' then ld(instruction)
    when 'ADD' then add(instruction)
    when 'SUB' then sub(instruction)
    when 'HALT' then halt(instruction)
    when 'INC' then inc(instruction)
    when 'DEC' then dec(instruction)
    else
      $logger.warn("[Decoder] Unimplemented mnemonic #{instruction['mnemonic']}")
    end

    instruction['cycles'].sum
  end


  private

    def load_data(op)
      if !op['immediate']
        read = op.clone.tap { |o|
          o['immediate'] = true
        }
        mmu[load_data(read)]
      elsif op['name'] == 'n8' || op['name'] == 'a8' || op['name'] == 'e8'
        next_instruction
        current_op
      elsif op['name'] == 'n16' || op['name'] == 'a16'
        next_instruction
        value = current_op >> 4
        next_instruction
        value + current_op
      else
        register(op['name'])
      end
    end


    def ld(instruction)
      write, read = instruction['operands']
      value = load_data(read)

      if write['immediate']
        set_register(write['name'], value)
      else
        x = load_data(write)
        mmu[x] = value
      end
    end


    def nop(instruction)
      # no-op
    end


    def add(instruction)
      write, read = instruction['operands']
      value = load_data(read)
      old_value = load_data(write)

      set_register(write['name'], old_value+value)
    end


    def sub(instruction)
      write, read = instruction['operands']
      value = load_data(read)
      old_value = load_data(write)

      set_register(write['name'], old_value-value)
    end


    def halt(instruction)
      halt!
    end


    def inc(instruction)
      op = instruction['operands'][0]
      value = load_data(op)

      set_register(op['name'], value+1)
    end


    def dec(instruction)
      op = instruction['operands'][0]
      value = load_data(op)

      set_register(op['name'], value-1)
    end

end
