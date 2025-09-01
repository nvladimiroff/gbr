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
    @pending = []
    @ime = true
  end


  def fire(type)
    @pending << type
  end


  def handle
    return unless @ime

    @pending.each do |type|
      next unless enabled?(type)

      @ime = false
      yield(type, ADDRESS_MAPPING[type])
    end

  end


  def enabled?(type)
    true # TODO
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
