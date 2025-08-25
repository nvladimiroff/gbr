require_relative '../config/boot'
require 'minitest/autorun'

class Minitest::Test

  def setup
    @gb = Gameboy.new([])
  end


  def set_interrupt_handler(addr, &block)
    handler = Asm.compile(&block)
    map_code(handler.binary, start: addr)
  end


  def run_program(**opts, &block)
    program = Asm.compile(&block)

    map_code(program.binary, start: 0x100)

    limit = opts[:limit] || program.length
    limit.times do
      @gb.step
    end
  end


  private

    def map_code(program, **opts)
      start = opts[:start] || 0

      program.each_with_index { |byte, i|
        @gb.mmu[start+i] = byte
      }
    end

end


class Asm

  VALUES = [:a, :b, :c, :d, :e, :f, :l, :bc, :nz]


  def self.compile(&block)
    asm = new
    asm.instance_eval(&block)
    asm
  end


  def initialize
    @instructions = []
    @@opcodes ||= Opcodes::MAPPING.invert
  end


  def method_missing(sym, *args)
    return sym if VALUES.include?(sym)

    key = [sym] + map_ints(args)
    opcode = @@opcodes[key]

    if opcode == nil
      raise "Missing opcode: #{key}"
    end

    instructions = [opcode]
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
