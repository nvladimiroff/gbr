class Joypad

  def initialize
    @pressed = Set.new
    @buttons_enabled = true
    @dpad_enabled = false
  end


  def read
    reg = 0x00

    if @buttons_enabled
      reg |= 0b0010_0000
      reg |= 0b0000_0001 if @pressed.include?(:a)
      reg |= 0b0000_0010 if @pressed.include?(:b)
      reg |= 0b0000_0100 if @pressed.include?(:select)
      reg |= 0b0000_1000 if @pressed.include?(:start)
    end

    if @dpad_enabled
      reg |= 0b0001_0000
      reg |= 0b0000_0001 if @pressed.include?(:right)
      reg |= 0b0000_0010 if @pressed.include?(:left)
      reg |= 0b0000_0100 if @pressed.include?(:up)
      reg |= 0b0000_1000 if @pressed.include?(:down)
    end

    # In a Gameboy, 0 is pressed and 1 is released.
    ~reg & 0xFF
  end


  def write(value)
    @buttons_enabled = (value & 0b0010_0000) == 0
    @dpad_enabled = (value & 0b0001_0000) == 0
  end


  def press(button)
    @pressed << button
  end


  def release(button)
    @pressed.delete(button)
  end

end
