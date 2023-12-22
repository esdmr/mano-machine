`include "preamble.sv"

/**
 * Calculate the carry from a partial full adder.
 */
module CarryGroup (
    output var logic c_out,
    input var  logic p_in,
    input var  logic g_in,
    input var  logic c_in
);
  assign c_out = g_in || p_in && c_in;
endmodule
