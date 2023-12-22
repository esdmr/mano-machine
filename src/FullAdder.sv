`include "preamble.sv"

/**
 * Three bit adder, with ripple-carry compatible outputs.
 */
module FullAdder (
    output var logic c_out,
    output var logic sum_out,
    input var  logic a_in,
    input var  logic b_in,
    input var  logic c_in
);
  assign c_out   = (a_in && b_in) || (c_in && (a_in ^ b_in));
  assign sum_out = a_in ^ b_in ^ c_in;
endmodule
