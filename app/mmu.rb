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


  private

    def map_rom(rom)
      rom.each_with_index { |byte, i|
        @memory[i] = byte
      }
    end

end
