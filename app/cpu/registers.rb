module CPU::Registers

  extend ActiveSupport::Concern


  # Special handling for f and af because the lower 4 bits are always zero.
  def f
    @f & 0xF0
  end


  def f=(value)
    @f = value & 0xF0
  end


  def af
    (@a << 8) | @f
  end


  def af=(value)
    @a = (value >> 8) & 0xFF
    @f = value & 0xF0
  end


  def zero_flag
    @f[7] == 1
  end


  def zero_flag=(value)
    @f = set_bit(@f, 7, value)
  end


  def subtract_flag
    @f[6] == 1
  end


  def subtract_flag=(value)
    @f = set_bit(@f, 6, value)
  end


  def half_carry_flag
    @f[5] == 1
  end


  def half_carry_flag=(value)
    @f = set_bit(@f, 5, value)
  end


  def carry_flag
    @f[4] == 1
  end


  def carry_flag=(value)
    @f = set_bit(@f, 4, value)
  end


  def a
    (@a || 0) & 0xFF
  end


  def b
    (@b || 0) & 0xFF
  end


  def c
    (@c || 0) & 0xFF
  end

  def d
    (@d || 0) & 0xFF
  end

  def e
    (@e || 0) & 0xFF
  end


  def h
    (@h || 0) & 0xFF
  end


  def l
    (@l || 0) & 0xFF
  end


  def a=(value)
    @a = value & 0xFF
  end


  def b=(value)
    @b = value & 0xFF
  end


  def c=(value)
    @c = value & 0xFF
  end


  def d=(value)
    @d = value & 0xFF
  end


  def e=(value)
    @e = value & 0xFF
  end


  def h=(value)
    @h = value & 0xFF
  end


  def l=(value)
    @l = value & 0xFF
  end


  def bc
    @b << 8 | @c
  end


  def bc=(value)
    @b = (value & 0xFF00) >> 8
    @c = value & 0xFF
  end



  def de
    @d << 8 | @e
  end


  def de=(value)
    @d = (value & 0xFF00) >> 8
    @e = value & 0xFF
  end


  def hl
    @h << 8 | @l
  end


  def hl=(value)
    @h = (value & 0xFF00) >> 8
    @l = value & 0xFF
  end


  private

    def set_bit(x, pos, value)
      unless value
        x & ~(2 ** pos)
      else
        x | (2 ** pos)
      end
    end


  class_methods do

    def reg_8_bit(*names)
      names.each { |name|
        define_method(name) {
          (instance_variable_get("@#{name}") || 0) & 0xFF
        }
        define_method("#{name}=") { |value|
          instance_variable_set("@#{name}", value & 0xFF)
        }
      }
    end


    def reg_16_bit(*names)
      names.each { |name|
        reg1 = name[0]
        reg2 = name[1]

        define_method(name) {
          instance_variable_get("@#{reg1}") << 8 | instance_variable_get("@#{reg2}")
        }
        define_method("#{name}=") { |value|
          instance_variable_set("@#{reg1}", (value & 0xFF00) >> 8)
          instance_variable_set("@#{reg2}", value & 0xFF)
        }
      }
    end

  end

end
