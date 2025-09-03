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
    opcode = @@opcodes[key]
    instructions = []

    if opcode == nil
      opcode = @@cb_opcodes[key]
      instructions << 0xCB if opcode
    end

    if opcode == nil
      raise "Missing opcode: #{key}"
    end

    instructions << opcode
    instructions << args.last if key.include?(:n8)
    if key.include?(:n16)
      instructions += [args.last & 0x00FF, (args.last & 0xFF00) >> 8]
    end

    @instructions << instructions
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

end
