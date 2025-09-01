class MMU

  def initialize(cartridge, ppu, interrupts)
    @cartridge = cartridge
    @ppu = ppu
    @eram = Array.new(0x2000, 0)
    @wram = Array.new(0x2000, 0)
    @interrupts = interrupts
    @zram = Array.new(0x80, 0)
  end


  def [](addr)
    case addr
    when 0x0..0x7FFF
      @cartridge[addr]
    when 0x8000..0x9FFF
      # PPU
    when 0xA000..0xBFFF
      @eram[addr - 0xA000]
    when 0xC000..0xDFFF
      @wram[addr - 0xC000]
    when 0xE000..0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000]
    when 0xFE00..0xFE9F
      # Sprites
    when 0xFF0F # Interrupts
      @interrupts.pending_byte
    when 0xFF00..0xFF7F
      # Other IO I haven't implemented yet.
    when 0xFF80..0xFFFF
      @zram[addr - 0xFF80]
    end
  end


  def []=(addr, value)
    case addr
    when 0x0..0x7FFF
      raise ReadOnlyMemoryError.new
    when 0x8000..0x9FFF
      # PPU
    when 0xA000..0xBFFF
      @eram[addr - 0xA000] = value
    when 0xC000..0xDFFF
      @wram[addr - 0xC000] = value
    when 0xE000..0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000] = value
    when 0xFE00..0xFE9F
      # Sprites
    when 0xFF0F # Interrupts

    when 0xFF00..0xFF7F
      # Other IO I haven't implemented yet.
    when 0xFF80..0xFFFF
      @zram[addr - 0xFF80] = value
    end
  end


  def read_word(addr)
    self[addr] + (self[addr+1] << 8)
  end


  def write_word(addr, value)
    self[addr] = value & 0xFF
    self[addr+1] = value >> 8
  end


  class ReadOnlyMemoryError < StandardError
    def initialize
      super('Read-only memory had an attempted write.')
    end
  end

end
