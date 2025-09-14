require_relative '../config/boot'
require 'minitest/autorun'

class ActiveSupport::TestCase

  parallelize(workers: :number_of_processors)


  def setup
    @rom = Array.new(0x8000, 0)
    @prev_inst = nil
    @gb = nil
  end


  def load_program(**opts, &block)
    program = Assembler.compile(&block)
    map_code(program.binary, at: opts[:at] || 0x0100)
  end


  def run_program(&block)
    load_program(&block)

    @gb = Gameboy.new(@rom)
    loop do
      @gb.step

      # Run until NOP twice
      if @gb.cpu.op == 0 && @prev_inst == 0
        break
      end
      @prev_inst = @gb.cpu.op
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

