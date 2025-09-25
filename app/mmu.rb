class MMU

  def initialize
    @wram = Array.new(0x2000, 0)
    @zram = Array.new(0x80, 0)
  end


  def wire(cpu, cartridge, ppu, timers, joypad)
    @cpu = cpu
    @cartridge = cartridge
    @ppu = ppu
    @timers = timers
    @joypad = joypad
  end


  def [](addr)
    if addr >= 0x0 && addr <= 0x7FFF
      @cartridge[addr]
    elsif addr >= 0x8000 && addr <= 0x9FFF
      # VRAM
      @ppu[addr]
    elsif addr >= 0xA000 && addr <= 0xBFFF
      @cartridge[addr]
    elsif addr >= 0xC000 && addr <= 0xDFFF
      @wram[addr - 0xC000]
    elsif addr >= 0xE000 && addr <= 0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000]
    elsif addr >= 0xFE00 && addr <= 0xFE9F
      # Sprites
      @ppu[addr]
    elsif addr >= 0xFEA0 && addr <= 0xFEFF
      # Unusable
      0xFF
    elsif addr == 0xFF00
      @joypad.read
    elsif addr >= 0xFF01 && addr <= 0xFF02
      # TODO: Serial communication
      0xFF
    elsif addr >= 0xFF04 && addr <= 0xFF07
      @timers[addr]
    elsif addr == 0xFF0F
      @cpu.if
    elsif addr >= 0xFF10 && addr <= 0xFF3F
      # TODO: Sound
      0xFF
    elsif addr >= 0xFF40 && addr <= 0xFF4B
      @ppu[addr]
    elsif addr >= 0xFF00 && addr <= 0xFF7F
      # TODO: Other IO I haven't implemented yet.
      #$logger.warn('Unimplemented memory read', addr: addr.to_hex)
      0xFF
    elsif addr >= 0xFF80 && addr <= 0xFFFE
      @zram[addr - 0xFF80]
    elsif addr == 0xFFFF
      @cpu.ie
    end
  end


  def []=(addr, value)
    if addr >= 0x0 && addr <= 0x7FFF
      @cartridge[addr] = value
    elsif addr >= 0x8000 && addr <= 0x9FFF
      # VRAM
      @ppu[addr] = value
    elsif addr >= 0xA000 && addr <= 0xBFFF
      @cartridge[addr] = value
    elsif addr >= 0xC000 && addr <= 0xDFFF
      @wram[addr - 0xC000] = value
    elsif addr >= 0xE000 && addr <= 0xFDFF
      # WRAM (Shadow)
      @wram[addr - 0xE000] = value
    elsif addr >= 0xFE00 && addr <= 0xFE9F
      # Sprites
      @ppu[addr] = value
    elsif addr >= 0xFEA0 && addr <= 0xFEFF
      # Unusable
    elsif addr == 0xFF00
      @joypad.write(value)
    elsif addr >= 0xFF01 && addr <= 0xFF02
      STDOUT.write(value.chr)
    elsif addr >= 0xFF04 && addr <= 0xFF07
      @timers[addr] = value
    elsif addr == 0xFF0F
      @cpu.if = value
    elsif addr >= 0xFF10 && addr <= 0xFF3F
      # TODO: Sound
    elsif addr == 0xFF46
      # DMA
      # TODO (low): this actually progresses at one byte per 4 cycles.
      location = value << 8
      0xA0.times do |i|
        @ppu[0xFE00 + i] = self[location + i]
      end
    elsif addr >= 0xFF40 && addr <= 0xFF4B
      @ppu[addr] = value
    elsif addr >= 0xFF00 && addr <= 0xFF7F
      # TODO: Other IO I haven't implemented yet.
      #$logger.warn('Unimplemented memory write', addr: addr.to_hex)
    elsif addr >= 0xFF80 && addr <= 0xFFFE
      @zram[addr - 0xFF80] = value
    elsif addr == 0xFFFF
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
