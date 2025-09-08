class Cartridge

  attr_accessor(:bank)


  def initialize(rom)
    @rom = rom
    @rom_bank = 1

    @ram = Array.new(0x8000, 0xFF)
    @ram_bank = 0
    @ram_enabled = true
  end


  def title
    title = ''
    (0x0134..0x0143).each do |addr|
      title << @rom[addr]
    end

    title
  end


  def type
    # See https://gbdev.io/pandocs/The_Cartridge_Header.html for decoding this value
    @rom[0x0147]
  end


  def [](addr)
    case addr
    when 0x0000..0x3FFF
      @rom[addr]
    when 0x4000..0x7FFF
      @rom[addr + 0x4000 * (@rom_bank - 1)]
    when 0xA000..0xBFFF
      if @ram_enabled
        @ram[addr - 0xA000 + 0x2000 * @ram_bank]
      else
        0xFF
      end
      # TODO: Also mysterious clock stuff
    end
  end


  def []=(addr, value)
    case addr
    when 0x0000..0x1FFF
      @ram_enabled = value & 0x0F == 0x0A
    when 0x2000..0x3FFF
      puts "Switching ROM bank"
      @rom_bank = value
      @rom_bank = 1 if @rom_bank == 0
    when 0x4000..0x5FFF
      puts "Switching RAM bank"
      @ram_bank = value
    when 0x6000..0x7FFF
      # TODO: Mysterious clock stuff.
    when 0xA000..0xBFFF
      @ram[addr - 0xA000 + 0x2000 * @ram_bank]
      # TODO: Also more mysterious clock stuff.
    end
  end

end
