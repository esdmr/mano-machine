`include "preamble.sv"

/**
 * One bit data storage.
 */
module JKFlipFlop (
    output var logic q_out = 'x,
    input var  logic j_in,
    input var  logic k_in,
    input var  logic clock
);
  always_ff @(posedge clock)
    if (j_in || k_in)
      q_out <= j_in && !(k_in && q_out);
endmodule
