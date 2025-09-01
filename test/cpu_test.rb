require_relative './test_helper'

class CPUTest < Minitest::Test

  def test_nothing
    run_program do
      nop
    end

    assert(true)
  end


  def test_ld_const_a
    run_program do
      ld a, 0xFF
    end

    assert_equal(0xFF, @gb.a)
  end


  def test_ld_const_bc
    run_program do
      ld bc, 0xFFFF
    end

    assert_equal(0xFFFF, @gb.bc)
  end


  def test_ld_a_b
    run_program do
      ld a, 0xFF
      ld b, a
    end

    assert_equal(0xFF, @gb.b)
  end


  def test_ld_write_mem
    run_program do
      ld b, 0xC0
      ld c, 0x00
      ld a, 0xFF
      ld [bc], a
    end

    assert_equal(0xFF, @gb.mmu[0xC000])
  end


  def test_add
    run_program do
      ld a, 0xAA
      ld b, 0x55
      add a, b
    end

    assert_equal(0xFF, @gb.a)
  end


  def test_adc
    run_program do
      ld a, 0xFF
      ld b, 0x01
      add a, b
      adc a, b
    end

    assert_equal(0x02, @gb.a)
  end


  def test_sub
    run_program do
      ld a, 0xFF
      ld b, 0x55
      sub a, b
    end

    assert_equal(0xAA, @gb.a)
  end


  def test_inc
    run_program do
      ld b, 0x00
      inc b
    end

    assert_equal(0x01, @gb.b)
  end


  def test_dec
    run_program do
      ld b, 0xFF
      dec b
    end

    assert_equal(0xFE, @gb.b)
  end


  def test_bool
    run_program do
      ld a, 0xFF
      ld b, 0xF0
      and_ a, b
      or_ a, 0x0F
    end

    assert_equal(0xFF, @gb.a)
    assert_equal(0xF0, @gb.b)
  end


  def test_jump
    run_program do
      jr 0x2
      ld b, 0xFF
      ld a, 0xFF
    end

    assert_equal(0xFF, @gb.a)
    refute_equal(0xFF, @gb.b)
  end


  def test_cond_jr
    run_program do
      ld a, 0x00
      ld c, 0x01
      add a, c
      jr nz, 0x2
      ld b, 0xFF
      ld a, 0xFF
    end

    assert_equal(0xFF, @gb.a)
    refute_equal(0xFF, @gb.b)
  end


  def test_cond_jp
    run_program do
      ld a, 0x00
      ld c, 0x01
      add a, c
      jp nz, 0x10A
      ld b, 0xFF
      ld a, 0xFF
    end

    assert_equal(0xFF, @gb.a)
    refute_equal(0xFF, @gb.b)
  end


  def test_halt
    load_program do
      ld a, 0xFF
      halt
      ld b, 0xFF
    end

    3.times { step }

    assert_equal(0xFF, @gb.a)
    refute_equal(0xFF, @gb.b)
  end


  def test_call
    load_program at: 0x200  do
      ld c, 0xFF
      ret
    end

    run_program do
      ld a, 0
      add a, 1
      call nz, 0x200
      ld b, 0xFF
    end

    assert_equal(0xFF, @gb.b)
    assert_equal(0xFF, @gb.c)
  end


  def test_double_call
    load_program at: 0x200  do
      call 0x300
      ld a, 0xFF
      ret
    end

    load_program at: 0x300  do
      ld b, 0xFF
      ret
    end

    run_program do
      call 0x200
      ld c, 0xFF
    end

    assert_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
    assert_equal(0xFF, @gb.c)
  end


  def test_doesnt_call_if_condition_not_met
    load_program at: 0x200 do
      ld a, 0xFF
      ret
    end

    run_program do
      ld a, 0
      add a, 1
      call z, 0x200
      ld b, 0xFF
    end

    refute_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
  end


  def test_pop_push
    run_program do
      ld bc, 0xFFFF
      push bc
      pop de
    end

    assert_equal(0xFFFF, @gb.de)
  end


  def test_set_bit
    run_program do
      ld a, 0
      set 4, a
    end

    assert_equal(0b0001_0000, @gb.a)
  end

  def test_reset_bit
    run_program do
      ld a, 0xFF
      res 4, a
    end

    assert_equal(0b1110_1111, @gb.a)
  end


  def test_test_bit
    run_program do
      ld a, 0b1110_1111
      bit 4, a
    end

    assert_equal(true, @gb.zero_flag)
  end


  def test_compare
    run_program do
      ld a, 0xFF
      ld b, 0xFF
      cp a, b
      jr z, 0x2
      ld c, 0xFF
    end

    assert_equal(0xFF, @gb.a)
    assert_equal(0xFF, @gb.b)
    refute_equal(0xFF, @gb.c)
  end

end
