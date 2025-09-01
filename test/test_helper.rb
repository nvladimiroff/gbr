require_relative '../config/boot'
require 'minitest/autorun'

class Minitest::Test

  def setup
    @rom = Array.new(0x8000, 0)
    @prev_inst = nil
    @gb = nil
  end


  def load_program(**opts, &block)
    program = Asm.compile(&block)
    map_code(program.binary, at: opts[:at] || 0x0100)
  end


  def run_program(&block)
    load_program(&block)

    @gb = Gameboy.new(@rom)
    loop do
      @gb.step

      # Run until NOP twice
      if @gb.instance_variable_get(:@op) == 0 && @prev_inst == 0
        break
      end
      @prev_inst = @gb.instance_variable_get(:@op)
    end
  end


  def step
    @gb ||= Gameboy.new(@rom)
    @gb.step
  end


  def fire_interrupt(...)
    @gb ||= Gameboy.new(@rom)
    @gb.fire_interrupt(...)
  end


  private

    def map_code(program, **opts)
      start = opts[:at]

      program.each_with_index { |byte, i|
        @rom[start+i] = byte
      }
    end

end


class Asm

  VALUES = [:a, :b, :c, :d, :e, :f, :l, :bc, :de, :nz, :z]


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


  private

    def encode_next_byte?(instruction)
      !%i(bit set res).include?(instruction)
    end

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
