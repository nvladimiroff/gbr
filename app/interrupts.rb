class Interrupts

  attr_reader(:pending)
  attr_accessor(:ime)


  ADDRESS_MAPPING = {
    :vblank => 0x40,
    :lcd_stat => 0x48,
    :timer_overflow => 0x50,
    :serial => 0x58,
    :joypad => 0x60
  }


  def initialize
    @pending = {
      :vblank => false,
      :lcd_stat => false,
      :timer_overflow => false,
      :serial => false,
      :joypad => false
    }

    @enabled = {
      :vblank => true,
      :lcd_stat => true,
      :timer_overflow => true,
      :serial => true,
      :joypad => true
    }

    @ime = true
  end


  def fire(type)
    @pending[type] = true
  end


  def handle
    return unless @ime

    @pending.each do |type, fired|
      next unless enabled?(type) && fired

      @ime = false
      @pending[type] = false
      yield(type, ADDRESS_MAPPING[type])
    end

  end


  def enabled?(type)
    @enabled[type]
  end


  def [](addr)
    if addr == 0xFF0F
      byte = 0x00

      byte |= 0x01 if @pending[:vblank]
      byte |= 0x02 if @pending[:lcd_stat]
      byte |= 0x04 if @pending[:timer_overflow]
      byte |= 0x08 if @pending[:serial]
      byte |= 0x10 if @pending[:joypad]

      byte
    elsif addr == 0xFFFF
      byte = 0x00

      byte |= 0x01 if @enabled[:vblank]
      byte |= 0x02 if @enabled[:lcd_stat]
      byte |= 0x04 if @enabled[:timer_overflow]
      byte |= 0x08 if @enabled[:serial]
      byte |= 0x10 if @enabled[:joypad]

      byte
    else
      $logger.error('Invalid memory access', addr:)
    end
  end


  def []=(addr, value)
    if addr == 0xFF0F
      @pending[:vblank] = value & 0x01 > 0
      @pending[:lcd_state] = value & 0x02 > 0
      @pending[:timer_overflow] = value & 0x04 > 0
      @pending[:serial] = value & 0x08 > 0
      @pending[:joypad] = value & 0x10 > 0
    elsif addr == 0xFFFF
      @enabled[:vblank] = value & 0x01 > 0
      @enabled[:lcd_state] = value & 0x02 > 0
      @enabled[:timer_overflow] = value & 0x04 > 0
      @enabled[:serial] = value & 0x08 > 0
      @enabled[:joypad] = value & 0x10 > 0
    else
      $logger.error('Invalid memory write', addr:, value:)
    end
  end




  def pending_byte
    byte = 0x00

    byte |= 0x01 if @pending.include?(:vblank)
    byte |= 0x02 if @pending.include?(:lcd_stat)
    byte |= 0x04 if @pending.include?(:timer_overflow)
    byte |= 0x08 if @pending.include?(:serial)
    byte |= 0x10 if @pending.include?(:joypad)

    byte
  end


  def byte=(value)
    # TODO
  end

end
