`include "preamble.sv"
`IMPORT(PartialFullAdder)
`IMPORT(LookAheadCarry)

/**
 * One layer carry-lookahead adder.
 */
module FastAdder #(
    parameter int BITS = 16
) (
    output var logic pg_out,
    output var logic gg_out,
    output var logic [BITS-1 : 0] sum_out,
    input var logic [BITS-1 : 0] a_in,
    input var logic [BITS-1 : 0] b_in,
    input var logic c_in
);
  var logic [BITS-1 : 0] c;
  var logic [BITS-1 : 0] p;
  var logic [BITS-1 : 0] g;

  for (genvar i = 0; i < BITS; i++) begin : gen_bit
    PartialFullAdder pfa (
        .p_out(p[i]),
        .g_out(g[i]),
        .sum_out(sum_out[i]),
        .a_in(a_in[i]),
        .b_in(b_in[i]),
        .c_in(c[i])
    );
  end

  LookAheadCarry #(
      .BITS(BITS)
  ) cla (
      .pg_out,
      .gg_out,
      .c_out(c),
      .p_in (p),
      .g_in (g),
      .c_in
  );
endmodule
