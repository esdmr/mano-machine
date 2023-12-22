`include "preamble.sv"
`IMPORT(Encoder4)

module Encoder4Test;
  `TAP_IO(16, 4)

  Encoder4 dut (
      .data_out(tap_out),
      .data_in (tap_in)
  );

  `TAP_BEGIN
  `TAP_CASE(16'b0000000000000000, 0, "No input")
  `TAP_CASE(16'b0000000000000001, 0, "[in[0]]")
  `TAP_CASE(16'b0000000000000010, 1, "[in[1]]")
  `TAP_CASE(16'b0000000000000100, 2, "[in[2]]")
  `TAP_CASE(16'b0000000000001000, 3, "[in[3]]")
  `TAP_CASE(16'b0000000000010000, 4, "[in[4]]")
  `TAP_CASE(16'b0000000000100000, 5, "[in[5]]")
  `TAP_CASE(16'b0000000001000000, 6, "[in[6]]")
  `TAP_CASE(16'b0000000010000000, 7, "[in[7]]")
  `TAP_CASE(16'b0000000100000000, 8, "[in[8]]")
  `TAP_CASE(16'b0000001000000000, 9, "[in[9]]")
  `TAP_CASE(16'b0000010000000000, 10, "[in[10]]")
  `TAP_CASE(16'b0000100000000000, 11, "[in[11]]")
  `TAP_CASE(16'b0001000000000000, 12, "[in[12]]")
  `TAP_CASE(16'b0010000000000000, 13, "[in[13]]")
  `TAP_CASE(16'b0100000000000000, 14, "[in[14]]")
  `TAP_CASE(16'b1000000000000000, 15, "[in[15]]")
  `TAP_END
endmodule
