module CPU::Interrupts

  INTERRUPT_ADDRESS_MAPPING = {
    :vblank => 0x40,
    :lcd_stat => 0x48,
    :timer_overflow => 0x50,
    :serial => 0x58,
    :joypad => 0x60
  }

  INTERRUPT_TYPES = [:vblank, :lcd_stat, :timer_overflow, :serial, :joypad]

  INTERRUPT_BIT_POSITION = {
    :vblank => 1,
    :lcd_stat => 2,
    :timer_overflow => 3,
    :serial => 4,
    :joypad => 5
  }


  def interrupt(type)
    @mmu[0xFF0F] |= 1 << INTERRUPT_BIT_POSITION[type]
  end


  private

    def interrupt_enabled?(type)
      @mmu[0xFFFF][INTERRUPT_BIT_POSITION[type]] == 1
    end


    def handle_interrupts
      INTERRUPT_TYPES.each do |type|
        if @mmu[0xFF0F][INTERRUPT_BIT_POSITION[type]] == 1
          @halted = false

          return unless @ime && interrupt_enabled?(type)

          @mmu[0xFF0F] &= ~(1 << INTERRUPT_BIT_POSITION[type])
          @sp -= 2
          @mmu.write_word(@sp, @pc)
          @pc = INTERRUPT_ADDRESS_MAPPING[type]
          break
        end
      end
    end

end
