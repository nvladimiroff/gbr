require_relative './test_helper'

class PPUTest < Minitest::Test

  def test_render_black_screen
    run_program do
      ld hl, 0x8000
      ld a, 0xFF
      ld b, 0x40

      ldi [hl], a
      dec b
      jr nz, 0xFB

      halt # wait for vblank
    end

    assert(@gb.ppu.pixels.all? do |p| p == 0x005121FF end)
  end


  def test_render_white_screen
    run_program do
      ld hl, 0x8000
      ld a, 0x00
      ld b, 0x40

      ldi [hl], a
      dec b
      jr nz, 0xFB

      halt # wait for vblank
    end

    assert(@gb.ppu.pixels.all? do |p| p == 0x578200FF end)
  end


end
