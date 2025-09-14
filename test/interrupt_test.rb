require_relative './test_helper'

class InterruptTest < ActiveSupport::TestCase

  def test_vblank
    load_program at: 0x40 do
      ld a, 0xFF
      reti
    end

    load_program do
      ld b, 0xFF
    end

    fire_interrupt(:vblank)
    5.times { step }

    assert_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end


  def test_interrupts_disabled
    load_program at: 0x40 do
      ld a, 0xFF
      reti
    end

    load_program do
      di
      ld b, 0xFF
    end

    step
    fire_interrupt(:vblank)
    step

    refute_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end


  def test_di_ei_toggle
    load_program at: 0x40 do
      ld a, 0xFF
      reti
    end

    load_program do
      di
      ei
      ld b, 0xFF
    end

    2.times { step }
    fire_interrupt(:vblank)
    3.times { step }

    assert_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end


  def test_interrupt_doesnt_fire_without_interrupt
    load_program at: 0x40  do
      ld a, 0xFF
      reti
    end

    run_program do
      ld b, 0xFF
    end

    refute_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end


  def test_interrupt_clears_halt
    load_program at: 0x40  do
      ld a, 0xFF
      reti
    end

    load_program do
      halt
      ld b, 0xFF
    end

    2.times { step }
    fire_interrupt(:vblank)
    3.times { step }

    assert_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end

end
