class MMU

  def initialize(rom)
    @memory = Array.new(0x10000, 0)
    map_rom(rom)
  end


  def [](addr)
    @memory[addr]
  end


  def []=(addr, value)
    @memory[addr] = value
  end


  def read_word(addr)
    @memory[addr] + (@memory[addr+1] << 8)
  end


  def write_word(addr, value)
    @memory[addr] = value & 0xFF
    @memory[addr+1] = value >> 8
  end


  private

    def map_rom(rom)
      rom.each_with_index { |byte, i|
        @memory[i] = byte
      }
    end

end
