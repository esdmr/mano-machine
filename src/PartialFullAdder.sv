`include "preamble.sv"

/**
 * Three bit adder, with carry-lookahead compatible outputs.
 */
module PartialFullAdder (
    output var logic p_out,
    output var logic g_out,
    output var logic sum_out,
    input var  logic a_in,
    input var  logic b_in,
    input var  logic c_in
);
  assign sum_out = a_in ^ b_in ^ c_in;
  assign p_out   = a_in || b_in;
  assign g_out   = a_in && b_in;
endmodule
