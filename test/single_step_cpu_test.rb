require_relative './test_helper'

class SingleStepCPUTest < ActiveSupport::TestCase

  class TestMMU

    def initialize
      @ram = Array.new(0x10000, 0)
    end


    def [](addr)
      @ram[addr]
    end


    def []=(addr, value)
      @ram[addr] = value
    end


    def wire(...)
    end


    def read_word(addr)
      self[addr] + (self[addr+1] << 8)
    end


    def write_word(addr, value)
      self[addr] = value & 0xFF
      self[addr+1] = value >> 8
    end


    def reset
      @ram.map! do |_| 0 end
    end

  end


  REGISTERS = %i(pc sp a b c d e f h l)

  Dir['test/sm83/v1/*.json'].each do |file|
    test_collection = JSON.load_file(file)

    test_collection.each do |test_data|
      define_method("test_#{test_data['name'].gsub(' ', '_')}") do
        # Set up the initial state.
        REGISTERS.each do |r|
          @gb.cpu.send("#{r}=", test_data['initial'][r.to_s])
        end
        test_data['initial']['ram'].each do |value|
          @gb.mmu[value[0]] = value[1]
        end

        # Step once.
        @gb.step

        # Verify.
        REGISTERS.each do |r|
          expected = test_data['final'][r.to_s]
          actual = @gb.cpu.send(r)
          assert_equal(expected, actual, "Register #{r} failed to match")
        end
        test_data['final']['ram'].each do |value|
          expected = value[1]
          actual = @gb.mmu[value[0]]
          assert_equal(expected, actual, "Address #{value[0]} failed to match")
        end
      end
    end
  end


  def setup
    @rom ||= Array.new(0x8000, 0)
    @mmu ||= TestMMU.new
    @mmu.reset
    @gb ||= Gameboy.new(@rom, mmu: @mmu)
  end

end
