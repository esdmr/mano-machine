`include "preamble.sv"
`IMPORT(Encoder3)

module Encoder3Test;
  `TAP_IO(8, 3)

  Encoder3 dut (
      .data_out(tap_out),
      .data_in (tap_in)
  );

  `TAP_BEGIN
  `TAP_CASE(8'b00000000, 0, "No input")
  `TAP_CASE(8'b00000001, 0, "[in[0]]")
  `TAP_CASE(8'b00000010, 1, "[in[1]]")
  `TAP_CASE(8'b00000100, 2, "[in[2]]")
  `TAP_CASE(8'b00001000, 3, "[in[3]]")
  `TAP_CASE(8'b00010000, 4, "[in[4]]")
  `TAP_CASE(8'b00100000, 5, "[in[5]]")
  `TAP_CASE(8'b01000000, 6, "[in[6]]")
  `TAP_CASE(8'b10000000, 7, "[in[7]]")
  `TAP_END
endmodule
