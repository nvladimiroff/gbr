module Opcodes

    OPCODE_MAPPING = {
      0x00 => [:nop],
      0x01 => [:ld, :bc, :n16],
      0x02 => [:ld, [:bc], :a],
      0x03 => [:inc, :bc],
      0x04 => [:inc, :b],
      0x05 => [:dec, :b],

      0x06 => [:ld, :b, :n8],

      0x0A => [:ld, :b, [:bc]],

      0x3e => [:ld, :a, :n8],

      0x47 => [:ld, :b, :a],

      0x80 => [:add, :a, :b],

      0x88 => [:adc, :a, :b],

      0x90 => [:sub, :a, :b],
    }


end
