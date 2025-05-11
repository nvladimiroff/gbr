class CPU::Decoder

  def initialize(cpu)
    opcodes_yml = YAML.load_file('config/opcodes.yaml')
    @unprefixed = opcodes_yml['unprefixed'].transform_keys { |key| key.to_i(16) }
    @cb_prefixed = opcodes_yml['cbprefixed'].transform_keys { |key| key.to_i(16) }
    @cpu = cpu
  end


  def decode_and_execute(opcode)
    instruction = @unprefixed[opcode]
    case instruction['mnemonic']
    when 'NOP' then nop(instruction)
    when 'LD' then ld(instruction)
    when 'ADD' then add(instruction)
    when 'SUB' then sub(instruction)
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
        @cpu.ram[load_data(read)]
      elsif op['name'] == 'n8' || op['name'] == 'a8' || op['name'] == 'e8'
        @cpu.next
        @cpu.current_op
      elsif op['name'] == 'n16' || op['name'] == 'a16'
        @cpu.next
        value = @cpu.current_op >> 4
        @cpu.next
        value + @cpu.current_op
      else
        @cpu.register(op['name'])
      end
    end


    def ld(instruction)
      write, read = instruction['operands']
      value = load_data(read)

      if write['immediate']
        @cpu.set_register(write['name'], value)
      else
        x = load_data(write)
        @cpu.ram[x] = value
      end
    end


    def nop(instruction)
      # no-op
    end


    def add(instruction)
      write, read = instruction['operands']
      value = load_data(read)
      old_value = load_data(write)

      @cpu.set_register(write['name'], old_value+value)
    end


    def sub(instruction)
      write, read = instruction['operands']
      value = load_data(read)
      old_value = load_data(write)

      @cpu.set_register(write['name'], old_value-value)
    end

end
