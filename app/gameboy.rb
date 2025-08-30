class Gameboy

  include CPU::Registers, CPU::Opcodes, CPU::Instructions, CPU::PrefixedInstructions

  attr_reader(:mmu)
  reg_8_bit(:a, :b, :c, :d, :e, :f, :h, :l)
  reg_16_bit(:af, :bc, :de, :hl)


  def initialize(rom)
    @mmu = MMU.new(rom)
    @pc = 0x0100
    @sp = 0xfffe
    @ticks = 0

    # DMG initial values
    @a = 0x1
    @b = 0
    @c = 0x13
    @d = 0xD8
    @e = 0
    @f = 0
    @h = 0x1
    @l = 0x4D

    @halted = false
    @ime = true
  end


  def send_interrupt(type)
    return unless interrupt_enabled(type)

    case type
    when :vblank
      @mmu[0xFF0F] |= 0x01
    when :lcd_stat
      @mmu[0xFF0F] |= 0x02
    when :timer_overflow
      @mmu[0xFF0F] |= 0x04
    when :serial
      @mmu[0xFF0F] |= 0x08
    when :joypad
      @mmu[0xFF0F] |= 0x10
    end
  end


  def dump_state(memory_range = 0x100..0x14F)
    Console.new.display_until_quit do |out|
      out.section("REGISTERS") do
        out.row(*%w(PC SP A B C D E F H L))
        out.row(*[@pc, @sp, @a, @b, @c, @d, @e, @f, @h, @l].map(&:to_hex))
      end

      out.section("INSTRUCTIONS") do
        out.line("Last instruction executed: #{MAPPING[@op]}")
        out.line("Next instruction: #{MAPPING[@mmu[@pc+1]]}")
      end

      out.section("INTERRUPTS") do
        out.line("Pending interrupts: #{pending_interrupts}")
      end

      out.section("MEMORY") do
        memory_range.each_slice(16) do |group|
          out.row(*group.map { |addr| @mmu[addr].to_hex })
        end
      end
    end
  end


  def step
    pending_interrupts.each do |interrupt|
      next unless @ime
      handle_interrupt(interrupt)
    end

    unless @halted
      @op = @mmu[@pc]
      @pc += 1
      decode_and_execute(@op)
    else
      @ticks += 4
    end
  rescue => e
    $logger.error("Error during instruction: #{@op.to_hex}", :exception => e)
    raise
  end


  private

    def decode_and_execute(opcode)
      instructions = MAPPING[opcode]

      raise "Unimplemented opcode" unless instructions

      send(*instructions)
    end


    def pending_interrupts
      interrupts = []

      if @mmu[0xFF0F] & 0x01 == 1
        interrupts << :vblank
      end

      if @mmu[0xFF0F] & 0x02 == 1
        interrupts << :lcd_stat
      end

      if @mmu[0xFF0F] & 0x04 == 1
        interrupts << :timer_overflow
      end

      if @mmu[0xFF0F] & 0x08 == 1
        interrupts << :serial
      end

      if @mmu[0xFF0F] & 0x10 == 1
        interrupts << :joypad
      end

      interrupts
    end


    def interrupt_enabled(type)
      true
    end


    def handle_interrupt(type)
      case type
      when :vblank
        addr = 0x40
        @mmu[0xFF0F] &= 0b1111_1110
      when :lcd_stat
        addr = 0x48
        @mmu[0xFF0F] &= 0b1111_1101
      when :timer_overflow
        addr = 0x50
        @mmu[0xFF0F] &= 0b1111_1011
      when :serial
        addr = 0x58
        @mmu[0xFF0F] &= 0b1111_0111
      when :joypad
        addr = 0x60
        @mmu[0xFF0F] &= 0b1110_1111
      end

      @sp -= 2
      @mmu.write_word(@sp, @pc)
      @pc = addr
      @ime = false
      @halted = false
    end

end
