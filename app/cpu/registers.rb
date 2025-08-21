module CPU::Registers

  extend ActiveSupport::Concern


  def zero_flag
    f[7] == 1
  end


  def zero_flag=(value)
    self.f = set_bit(f, 7, value)
  end


  def subtract_flag
    f[6] == 1
  end


  def subtract_flag=(value)
    self.f = set_bit(f, 6, value)
  end


  def half_carry_flag
    f[5] == 1
  end


  def half_carry_flag=(value)
    self.f = set_bit(f, 5, value)
  end


  def carry_flag
    f[4] == 1
  end


  def carry_flag=(value)
    self.f = set_bit(f, 4, value)
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
