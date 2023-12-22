`include "preamble.sv"
`IMPORT(Encoder2)

module Encoder2Test;
  `TAP_IO(4, 2)

  Encoder2 dut (
      .data_out(tap_out),
      .data_in (tap_in)
  );

  `TAP_BEGIN
  `TAP_CASE(4'b0000, 0, "No input")
  `TAP_CASE(4'b0001, 0, "[in[0]]")
  `TAP_CASE(4'b0010, 1, "[in[1]]")
  `TAP_CASE(4'b0100, 2, "[in[2]]")
  `TAP_CASE(4'b1000, 3, "[in[3]]")
  `TAP_END
endmodule
