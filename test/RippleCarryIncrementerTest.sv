`include "preamble.sv"
`IMPORT(RippleCarryIncrementer)

module RippleCarryIncrementerTest;
  `TAP_IO(16, 17)

  RippleCarryIncrementer #(
      .BITS(16)
  ) dut (
      .c_out(tap_out[16]),
      .data_out(tap_out[15:0]),
      .data_in(tap_in)
  );

  `TAP_BEGIN
  `TAP_CASE(16'h0000, {1'b0, 16'h0001}, "zero")
  `TAP_CASE(16'hffff, {1'b1, 16'h0000}, "max")
  `TAP_CASE(16'h1265, {1'b0, 16'h1266}, "random no")
  `TAP_END
endmodule
