class CPU::Registers

  attr_accessor(:af, :bc, :de, :hl, :pc, :sp)


  def initialize
    @af = 0
    @bc = 0
    @de = 0
    @hl = 0

    @pc = 0
    @sp = 0
  end


  def a
    @af >> 4
  end


  def a=(value)
    upper = @af & 0xFF00
    @af = upper + (value & 0x00FF)
  end


  def b
    @bc & 0xFF00
  end


  def b=(value)
    upper = @bc & 0x00FF
    @bc = upper + (value & 0xFF00)
  end


  def c
    @bc & 0x00FF
  end


  def c=(value)
    upper = @bc & 0xFF00
    @bc = upper + (value & 0x00FF)
  end


  def d
    @de & 0xFF00
  end


  def d=(value)
    upper = @de & 0x00FF
    @de = upper + (value & 0xFF00)
  end

end
