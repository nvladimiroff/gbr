class MMU

  def initialize(cartridge, ppu, interrupts)
    @cartridge = cartridge
    @ppu = ppu
    @eram = Array.new(0x2000, 0)
    @wram = Array.new(0x2000, 0)
    @interrupts = interrupts
    @zram = Array.new(0x80, 0)

    # TEMP
    @joypad = 0x00
  end


  def [](addr)
    case addr
    when 0x0..0x7FFF
      @cartridge[addr]
    when 0x8000..0x9FFF
      # VRAM
      @ppu[addr]
    when 0xA000..0xBFFF
      @eram[addr - 0xA000]
    when 0xC000..0xDFFF
      @wram[addr - 0xC000]
    when 0xE000..0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000]
    when 0xFE00..0xFE9F
      # Sprites
      @ppu[addr]
    when 0xFEA0..0xFEFF
      # Unusable
      0xFF
    when 0xFF00
      @joypad
    when 0xFF01..0xFF02
      # TODO: Serial communication
      0xFF
    when 0xFF05..0xFF07
      # TODO: Timers
      0xFF
    when 0xFF0F
      # Interrupts
      @interrupts[0xFF0F]
    when 0xFF10..0xFF3F
      # TODO: Sound
      0xFF
    when 0xFF40..0xFF4B
      @ppu[addr]
    when 0xFF00..0xFF7F
      # TODO: Other IO I haven't implemented yet.
      $logger.warn('Unimplemented memory read', addr: addr.to_hex)
      0xFF
    when 0xFF80..0xFFFE
      @zram[addr - 0xFF80]
    when 0xFFFF
      @interrupts[0xFFFF]
    end
  end


  def []=(addr, value)
    case addr
    when 0x2000..0x3FFF
      @cartridge.swap_bank(value)
    when 0x0..0x7FFF
      # Ignore it. You can't write to the ROM.
    when 0x8000..0x9FFF
      @ppu[addr] = value
    when 0xA000..0xBFFF
      @eram[addr - 0xA000] = value
    when 0xC000..0xDFFF
      @wram[addr - 0xC000] = value
    when 0xE000..0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000] = value
    when 0xFE00..0xFE9F
      # Sprites
      @ppu[addr] = value
    when 0xFEA0..0xFEFF
      # Unusable
    when 0xFF00
      @joypad = value
    when 0xFF01..0xFF02
      # TODO: Serial communication
    when 0xFF05..0xFF07
      # TODO: Timers
    when 0xFF0F
      @interrupts[0xFF0F] = value
    when 0xFF10..0xFF3F
      # TODO: Sound
    when 0xFF40..0xFF4B
      @ppu[addr] = value
    when 0xFF00..0xFF7F
      # TODO: Other IO I haven't implemented yet.
      $logger.warn('Unimplemented memory write', addr: addr.to_hex, value: value.to_hex)
    when 0xFF80..0xFFFE
      @zram[addr - 0xFF80] = value
    when 0xFFFF
      @interrupts[0xFF0F] = value
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
