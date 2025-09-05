class Assembler

  VALUES = [:a, :b, :c, :d, :e, :f, :l, :bc, :de, :hl, :nz, :z]


  def self.compile(&block)
    asm = new
    asm.instance_eval(&block)
    asm
  end


  def initialize
    @instructions = []
    @@opcodes ||= CPU::Opcodes::MAPPING.invert
    @@cb_opcodes ||= CPU::Opcodes::CB_MAPPING.invert
  end


  def method_missing(sym, *args)
    return sym if VALUES.include?(sym)

    key = [sym] + (encode_next_byte?(sym) ? map_ints(args) : args)
    @instructions << build_instruction(key, args)
  end


  def binary
    @instructions.flatten
  end


  def length
    @instructions.length
  end


  def map_to(rom, **opts)
    start = opts[:at] || 0

    binary.each_with_index { |byte, i|
      rom[start+i] = byte
    }
  end


  private

    def encode_next_byte?(instruction)
      !%i(bit set res).include?(instruction)
    end


    def map_ints(args)
      args.map do |a|
        if a.is_a?(Array) && a[0].is_a?(Integer)
          a[0] > 0xFF ? [:n16] : [:n8]
        elsif a.is_a?(Integer)
          a > 0xFF ? :n16 : :n8
        else
          a
        end
      end
    end


    def build_instruction(key, args)
      opcode = @@opcodes[key]
      i = []

      if opcode == nil
        opcode = @@cb_opcodes[key]
        i << 0xCB if opcode
      end

      if opcode == nil
        raise "Missing opcode: #{key}"
      end
      i << opcode

      key.drop(1).zip(args).each do |k, arg|
        if k.is_a?(Array)
          k = k[0]
          arg = arg[0]
        end

        if k == :n8
          i << arg
        elsif k == :n16
          i += [arg & 0x00FF, (arg & 0xFF00) >> 8]
        end
      end

      $logger.debug('Assembling', :i => i, :key => key, :args => args)

      i
    end

end
