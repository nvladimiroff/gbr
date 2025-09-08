class Timers

  def initialize
    @div = 0
  end


  def step(**opts)
    @div += opts[:by]
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
