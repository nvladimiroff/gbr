require_relative '../config/boot'
require 'minitest/autorun'

class Minitest::Test


  def run_program(*data)
    @rom = [0x00] * 0x100 + data
    @gb = Gameboy.new(@rom)
    @gb.run_for(limit: data.length - 1)
  end


  def run_program2(&block)
    program = Asm.new
    program.instance_eval(&block)
    @rom = [0x00] * 0x100 + program.compile
    @gb = Gameboy.new(@rom)
    @gb.run_for(limit: program.length)
  end

end


class Asm

  REGISTERS = [:a, :b, :c, :d, :e, :f, :l, :bc]

  OPCODE_MAPPING = {
    [:nop]           => [0x00],
    [:ld, :bc, :n16] => [0x01, :n16],
    [:ld, [:bc], :a] => [0x02],
    [:ld, :b, :n8]   => [0x06, :n8],
    [:ld, :b, [:bc]] => [0x0A],
    [:ld, :a, :n8]   => [0x3e, :n8],
    [:ld, :b, :a]    => [0x47],
    [:add, :a, :b]   => [0x80],
    [:adc, :a, :b]   => [0x88],
    [:sub, :a, :b]   => [0x90],
  }


  def initialize
    @instructions = []
  end


  def method_missing(sym, *args)
    return sym if REGISTERS.include?(sym)

    key = [sym] + map_ints(args)
    @instructions << unmap_ints(OPCODE_MAPPING[key], to: args.last)
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


    def unmap_ints(instructions, **opts)
      instructions.collect_concat do |i|
        if i == :n8
          [opts[:to]]
        elsif i == :n16
          [opts[:to] & 0x00FF, opts[:to] & 0xFF00 >> 8]
        else
          [i]
        end
      end
    end

end
