`include "preamble.sv"
`IMPORT(PartialFullAdder)

module PartialFullAdderTest;
  `TAP_IO(3, 3)

  PartialFullAdder dut (
      .p_out(tap_out[1]),
      .g_out(tap_out[2]),
      .sum_out(tap_out[0]),
      .a_in(tap_in[0]),
      .b_in(tap_in[1]),
      .c_in(tap_in[2])
  );

  `TAP_BEGIN
  `TAP_CASE(3'b000, 3'b000, "[~a, ~b, ~c]")
  `TAP_CASE(3'b001, 3'b011, "[ a, ~b, ~c]")
  `TAP_CASE(3'b010, 3'b011, "[~a,  b, ~c]")
  `TAP_CASE(3'b011, 3'b110, "[ a,  b, ~c]")
  `TAP_CASE(3'b100, 3'b001, "[~a, ~b,  c]")
  `TAP_CASE(3'b101, 3'b010, "[ a, ~b,  c]")
  `TAP_CASE(3'b110, 3'b010, "[~a,  b,  c]")
  `TAP_CASE(3'b111, 3'b111, "[ a,  b,  c]")
  `TAP_END
endmodule
