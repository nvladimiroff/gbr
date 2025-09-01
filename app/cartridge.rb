class Cartridge

  attr_accessor(:bank)


  def initialize(rom)
    @rom = rom
    @bank = 1
  end


  def [](addr)
    if addr <= 0x4000
      @rom[addr]
    else
      @rom[addr + (@bank - 1) * 0x4000]
    end
  end

end
