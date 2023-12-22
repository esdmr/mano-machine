`include "preamble.sv"
`IMPORT(HalfAdder)

module HalfAdderTest;
  `TAP_IO(2, 2)

  HalfAdder dut (
      .c_out(tap_out[1]),
      .sum_out(tap_out[0]),
      .a_in(tap_in[0]),
      .b_in(tap_in[1])
  );

  `TAP_BEGIN
  `TAP_CASE(2'b00, 2'h0, "[~a, ~b]")
  `TAP_CASE(2'b01, 2'h1, "[ a, ~b]")
  `TAP_CASE(2'b10, 2'h1, "[~a,  b]")
  `TAP_CASE(2'b11, 2'h2, "[ a,  b]")
  `TAP_END
endmodule
