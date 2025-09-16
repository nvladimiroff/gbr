class MMU

  def initialize
    @wram = Array.new(0x2000, 0)
    @zram = Array.new(0x80, 0)

    # TEMP
    @joypad = 0xFF
  end


  def wire(cpu, cartridge, ppu, timers)
    @cpu = cpu
    @cartridge = cartridge
    @ppu = ppu
    @timers = timers
  end


  def [](addr)
    case addr
    when 0x0..0x7FFF
      @cartridge[addr]
    when 0x8000..0x9FFF
      # VRAM
      @ppu[addr]
    when 0xA000..0xBFFF
      @cartridge[addr]
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
    when 0xFF04..0xFF07
      @timers[addr]
    when 0xFF0F
      @cpu.if
    when 0xFF10..0xFF3F
      # TODO: Sound
      0xFF
    when 0xFF40..0xFF4B
      @ppu[addr]
    when 0xFF00..0xFF7F
      # TODO: Other IO I haven't implemented yet.
      #$logger.warn('Unimplemented memory read', addr: addr.to_hex)
      0xFF
    when 0xFF80..0xFFFE
      @zram[addr - 0xFF80]
    when 0xFFFF
      @cpu.ie
    end
  end


  def []=(addr, value)
    case addr
    when 0x0..0x7FFF
      @cartridge[addr] = value
    when 0x8000..0x9FFF
      @ppu[addr] = value
    when 0xA000..0xBFFF
      @cartridge[addr] = value
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
    when 0xFF01
      STDOUT.write(value.chr)
    when 0xFF02
      # TODO: Serial communication
    when 0xFF04..0xFF07
      @timers[addr] = value
    when 0xFF0F
      @cpu.if = value
    when 0xFF10..0xFF3F
      # TODO: Sound
    when 0xFF46
      # DMA
      # TODO (low): this actually progresses at one byte per 4 cycles.
      location = value << 8
      0xA0.times do |i|
        @ppu[0xFE00 + i] = self[location + i]
      end
    when 0xFF40..0xFF4B
      @ppu[addr] = value
    when 0xFF00..0xFF7F
      # TODO: Other IO I haven't implemented yet.
      #$logger.warn('Unimplemented memory write', addr: addr.to_hex, value: value.to_hex)
    when 0xFF80..0xFFFE
      @zram[addr - 0xFF80] = value
    when 0xFFFF
      @cpu.ie = value
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
