class Timers

  def initialize
    @div_accum = 0
    @div = 0
  end


  def step(by)
    @div_accum += by

    if @div_accum >= 255
      @div += 1
      @div &= 0xFFFF
      @div_accum = 0
    end
  end


  def [](addr)
    case addr
    when 0xFF04
      @div
    else
      # TODO: other timers
      0xFF
    end
  end


  def []=(addr, value)
    case addr
    when 0xFF04
      @div = 0
    else
      # TODO: Other timers
    end
  end

end
