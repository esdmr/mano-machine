`include "preamble.sv"
`IMPORT(FastAdder2)

module FastAdder2Test;
  `TAP_IO(9, 6)

  FastAdder2 #(
      .WIDTH (2),
      .HEIGHT(2)
  ) dut (
      .pg_out(tap_out[4]),
      .gg_out(tap_out[5]),
      .sum_out(tap_out[3 : 0]),
      .a_in(tap_in[3 : 0]),
      .b_in(tap_in[7 : 4]),
      .c_in(tap_in[8])
  );

  `TAP_BEGIN
  `TAP_CASE({1'b0, 4'b0000, 4'b0000}, {2'b00, 4'b0000}, "zero")
  `TAP_CASE({1'b1, 4'b0000, 4'b0000}, {2'b00, 4'b0001}, "only cin")
  `TAP_CASE({1'b0, 4'b0000, 4'b0001}, {2'b00, 4'b0001}, "only a")
  `TAP_CASE({1'b1, 4'b0000, 4'b0001}, {2'b00, 4'b0010}, "a and cin")
  `TAP_CASE({1'b0, 4'b0001, 4'b0000}, {2'b00, 4'b0001}, "only b")
  `TAP_CASE({1'b1, 4'b0001, 4'b0000}, {2'b00, 4'b0010}, "b and cin")
  `TAP_CASE({1'b0, 4'b0001, 4'b0001}, {2'b00, 4'b0010}, "a and b")
  `TAP_CASE({1'b1, 4'b0001, 4'b0001}, {2'b00, 4'b0011}, "a and b and cin")
  `TAP_CASE({1'b0, 4'b0000, 4'b1000}, {2'b00, 4'b1000}, "edge: only a")
  `TAP_CASE({1'b1, 4'b0000, 4'b1000}, {2'b00, 4'b1001}, "edge: a and cin")
  `TAP_CASE({1'b0, 4'b1000, 4'b0000}, {2'b00, 4'b1000}, "edge: only b")
  `TAP_CASE({1'b1, 4'b1000, 4'b0000}, {2'b00, 4'b1001}, "edge: b and cin")
  `TAP_CASE({1'b0, 4'b1000, 4'b1000}, {2'b10, 4'b0000}, "edge: a and b")
  `TAP_CASE({1'b1, 4'b1000, 4'b1000}, {2'b10, 4'b0001}, "edge: a and b and cin")
  `TAP_CASE({1'b0, 4'b0101, 4'b1010}, {2'b01, 4'b1111}, "edge: propagate")
  `TAP_CASE({1'b1, 4'b0011, 4'b1100}, {2'b01, 4'b0000},
              "edge: propagate and cin")
  `TAP_END
endmodule
