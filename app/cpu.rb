class CPU

  include CPU::Opcodes

  attr_accessor(:clock, :r)


  def initialize(rom)
    @clock = {
      m: 0,
      t: 0
    }

    @r = Registers.new
    @rom = rom
    @ram = Array.new(0x2000, 0)
  end


  def run
    loop do
      execute

      @r.pc += 1
    end
  end


  def noop
  end


  def ld(write, read)
    value = load_data(read)

    if memory_access?(write)
      write_memory(write, value)
    else
      @r.send("#{write}=".to_sym, value)
    end
  end


  def inc(reg)
    @r.send("#{reg}=".to_sym, @r.send(reg) + 1)
  end


  def dec(reg)
    @r.send("#{reg}=".to_sym, @r.send(reg) - 1)
  end


  def rlca
  end


  def rrca
  end


  def add(write, read)
    @r.send("#{write}=".to_sym, @r.send(read) + @r.send(write))
  end


  def stop
  end


  private

    def memory_access?(sym)
      sym.to_s.start_with?('at')
    end


    def immediate16?(sym)
      sym == :n16
    end


    def immediate8?(sym)
      sym == :n8
    end


    def load_data(sym)
      if memory_access?(sym)
        location = sym[3..].to_sym
        @ram[load_data(location)]
      elsif immediate8?(sym)
        @r.pc += 1
        current_op
      elsif immediate16?(sym)
        @r.pc += 1
        value = current_op >> 4
        @r.pc += 1
        value + current_op
      else
        puts "SENT #{sym}"
        @r.send(sym)
      end
    end


    def write_memory(location, value)
      @ram[load_data(location[3..].to_sym)] = value
    end


    def current_op
      @rom[@r.pc]
    end

end
