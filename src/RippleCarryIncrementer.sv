`include "preamble.sv"
`IMPORT(HalfAdder)

/**
 * Group of half adders with an always active input carry.
 */
module RippleCarryIncrementer #(
    parameter int BITS = 16
) (
    output var logic c_out,
    output var logic [BITS-1:0] data_out,
    input var logic [BITS-1:0] data_in
);
  var logic [BITS:0] carry;
  assign c_out = carry[BITS];
  assign carry[0] = '1;

  for (genvar i = 0; i < BITS; i++) begin : gen_bit
    HalfAdder h (
        .c_out(carry[i+1]),
        .sum_out(data_out[i]),
        .a_in(data_in[i]),
        .b_in(carry[i])
    );
  end
endmodule
