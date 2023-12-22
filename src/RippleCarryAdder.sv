`include "preamble.sv"
`IMPORT(FullAdder)

/**
 * Ripple-carry adder.
 */
module RippleCarryAdder #(
    parameter int BITS = 16
) (
    output var logic c_out,
    output var logic [BITS - 1 : 0] sum_out,
    input var logic [BITS - 1 : 0] a_in,
    input var logic [BITS - 1 : 0] b_in,
    input var logic c_in
);
  var logic [BITS:0] carry;
  assign carry[0] = c_in;
  assign c_out = carry[BITS];

  for (genvar i = 0; i < BITS; i++) begin : gen_bit
    FullAdder f (
        .c_out(carry[i+1]),
        .sum_out(sum_out[i]),
        .a_in(a_in[i]),
        .b_in(b_in[i]),
        .c_in(carry[i])
    );
  end
endmodule
