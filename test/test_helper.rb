require_relative '../config/boot'
require 'minitest/autorun'

class Minitest::Test

  def run_program(&block)
    program = Asm.new
    if block_given?
      program.instance_eval(&block)
    end
    @rom = [0x00] * 0x100 + program.compile
    @gb = Gameboy.new(@rom)
    @gb.run_for(limit: program.length)
  end

end


class Asm

  REGISTERS = [:a, :b, :c, :d, :e, :f, :l, :bc]


  def initialize
    @instructions = []
    @@opcodes ||= Opcodes::OPCODE_MAPPING.invert
  end


  def method_missing(sym, *args)
    return sym if REGISTERS.include?(sym)

    key = [sym] + map_ints(args)
    opcode = @@opcodes[key]

    if opcode == nil
      return super
    end

    instructions = [opcode]
    instructions << args.last if key.include?(:n8)
    if key.include?(:n16)
      instructions += [args.last & 0x00FF, args.last & 0xFF00 >> 8]
    end

    @instructions << instructions
  rescue
    super
  end


  def compile
    @instructions.flatten
  end


  def length
    @instructions.length
  end


  private

    def map_ints(args)
      args.map do |a|
        if a.is_a?(Integer)
          a > 0xFF ? :n16 : :n8
        else
          a
        end
      end
    end

end
