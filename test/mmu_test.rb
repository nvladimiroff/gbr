require_relative './test_helper'

class MMUTest < ActiveSupport::TestCase

  def test_shadow_wram
    run_program do
      ld bc, 0xC000
      ld a, 0xFF
      ld [bc], a
    end

    assert_equal(0xFF, @gb.mmu[0xC000])
    assert_equal(0xFF, @gb.mmu[0xE000])
  end

end
