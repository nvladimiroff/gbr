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
      ld a, 0xFF
      ld [bc], a
      ld b, [bc]
    end

    assert_equal(0xFF, @gb.b)
    assert_equal(0xFF, @gb.mmu[0])
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


end
