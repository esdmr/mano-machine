`include "preamble.sv"

/**
 * Two bit adder.
 */
module HalfAdder (
    output var logic c_out,
    output var logic sum_out,
    input var  logic a_in,
    input var  logic b_in
);
  assign c_out   = a_in & b_in;
  assign sum_out = a_in ^ b_in;
endmodule
