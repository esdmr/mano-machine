`include "preamble.sv"
`IMPORT(FastAdder)

module FastAdderTest;
  `TAP_IO(5, 4)

  FastAdder #(
      .BITS(2)
  ) dut (
      .pg_out(tap_out[2]),
      .gg_out(tap_out[3]),
      .sum_out(tap_out[1 : 0]),
      .a_in(tap_in[1 : 0]),
      .b_in(tap_in[3 : 2]),
      .c_in(tap_in[4])
  );

  `TAP_BEGIN
  `TAP_CASE({1'b0, 2'b00, 2'b00}, {2'b00, 2'b00}, "zero")
  `TAP_CASE({1'b1, 2'b00, 2'b00}, {2'b00, 2'b01}, "only cin")
  `TAP_CASE({1'b0, 2'b00, 2'b01}, {2'b00, 2'b01}, "only a")
  `TAP_CASE({1'b1, 2'b00, 2'b01}, {2'b00, 2'b10}, "a and cin")
  `TAP_CASE({1'b0, 2'b01, 2'b00}, {2'b00, 2'b01}, "only b")
  `TAP_CASE({1'b1, 2'b01, 2'b00}, {2'b00, 2'b10}, "b and cin")
  `TAP_CASE({1'b0, 2'b01, 2'b01}, {2'b00, 2'b10}, "a and b")
  `TAP_CASE({1'b1, 2'b01, 2'b01}, {2'b00, 2'b11}, "a and b and cin")
  `TAP_CASE({1'b0, 2'b00, 2'b10}, {2'b00, 2'b10}, "edge: only a")
  `TAP_CASE({1'b1, 2'b00, 2'b10}, {2'b00, 2'b11}, "edge: a and cin")
  `TAP_CASE({1'b0, 2'b10, 2'b00}, {2'b00, 2'b10}, "edge: only b")
  `TAP_CASE({1'b1, 2'b10, 2'b00}, {2'b00, 2'b11}, "edge: b and cin")
  `TAP_CASE({1'b0, 2'b10, 2'b10}, {2'b10, 2'b00}, "edge: a and b")
  `TAP_CASE({1'b1, 2'b10, 2'b10}, {2'b10, 2'b01}, "edge: a and b and cin")
  `TAP_CASE({1'b0, 2'b01, 2'b10}, {2'b01, 2'b11}, "edge: propagate")
  `TAP_CASE({1'b1, 2'b01, 2'b10}, {2'b01, 2'b00}, "edge: propagate and cin")
  `TAP_END
endmodule
