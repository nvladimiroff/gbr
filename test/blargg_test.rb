require_relative './test_helper'

class BlarggTest < Minitest::Test

  def test_pop_af
    load_program(at: 0x0200) do
      ld h, 0xFF
    end

    run_program do
      ld bc, 0x1200
      push bc
      pop af
      push af
      pop de
      ld a, c
      and_ a, 0xF0
      cp a, e
      call 0x0200
      inc b
      inc c
      jp nz, 0x0100
    end

    refute_equal(0xFF, @gb.cpu.h)
  end

end
