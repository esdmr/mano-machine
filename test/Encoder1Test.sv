`include "preamble.sv"
`IMPORT(Encoder1)

module Encoder1Test;
  `TAP_IO(2, 1)

  Encoder1 dut (
      .data_out(tap_out),
      .data_in (tap_in)
  );

  `TAP_BEGIN
  `TAP_CASE(2'b00, 0, "No input")
  `TAP_CASE(2'b01, 0, "[in[0]]")
  `TAP_CASE(2'b10, 1, "[in[1]]")
  `TAP_END
endmodule
