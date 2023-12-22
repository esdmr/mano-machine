`include "preamble.sv"
`IMPORT(RippleCarryAdder)

module RippleCarryAdderTest;
  `TAP_IO(33, 17)

  RippleCarryAdder #(
      .BITS(16)
  ) dut (
      .c_out(tap_out[16]),
      .sum_out(tap_out[15 : 0]),
      .a_in(tap_in[15 : 0]),
      .b_in(tap_in[31 : 16]),
      .c_in(tap_in[32])
  );

  `TAP_BEGIN
  `TAP_CASE({1'b0, 16'h0000, 16'h0000}, {1'b0, 16'h0000}, "zero")
  `TAP_CASE({1'b1, 16'h0000, 16'h0000}, {1'b0, 16'h0001}, "only cin")
  `TAP_CASE({1'b0, 16'h0000, 16'hae43}, {1'b0, 16'hae43}, "only a")
  `TAP_CASE({1'b1, 16'h0000, 16'hae43}, {1'b0, 16'hae44}, "a and cin")
  `TAP_CASE({1'b0, 16'hae43, 16'h0000}, {1'b0, 16'hae43}, "only b")
  `TAP_CASE({1'b1, 16'hae43, 16'h0000}, {1'b0, 16'hae44}, "b and cin")
  `TAP_CASE({1'b0, 16'hae43, 16'hae43}, {1'b1, 16'h5c86}, "a and b")
  `TAP_CASE({1'b1, 16'hae43, 16'hae43}, {1'b1, 16'h5c87}, "a and b and cin")
  `TAP_END
endmodule
