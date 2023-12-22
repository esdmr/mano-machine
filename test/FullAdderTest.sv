`include "preamble.sv"
`IMPORT(FullAdder)

module FullAdderTest;
  `TAP_IO(3, 2)

  FullAdder dut (
      .c_out(tap_out[1]),
      .sum_out(tap_out[0]),
      .a_in(tap_in[0]),
      .b_in(tap_in[1]),
      .c_in(tap_in[2])
  );

  `TAP_BEGIN
  `TAP_CASE(3'b000, 2'h0, "[~a, ~b, ~c]")
  `TAP_CASE(3'b001, 2'h1, "[ a, ~b, ~c]")
  `TAP_CASE(3'b010, 2'h1, "[~a,  b, ~c]")
  `TAP_CASE(3'b011, 2'h2, "[ a,  b, ~c]")
  `TAP_CASE(3'b100, 2'h1, "[~a, ~b,  c]")
  `TAP_CASE(3'b101, 2'h2, "[ a, ~b,  c]")
  `TAP_CASE(3'b110, 2'h2, "[~a,  b,  c]")
  `TAP_CASE(3'b111, 2'h3, "[ a,  b,  c]")
  `TAP_END
endmodule
