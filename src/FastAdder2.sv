`include "preamble.sv"
`IMPORT(FastAdder)
`IMPORT(LookAheadCarry)

/**
 * Two layer carry-lookahead adder.
 */
module FastAdder2 #(
    parameter int WIDTH  = 4,
    parameter int HEIGHT = 4
) (
    output var logic pg_out,
    output var logic gg_out,
    output var logic [WIDTH*HEIGHT-1 : 0] sum_out,
    input var logic [WIDTH*HEIGHT-1 : 0] a_in,
    input var logic [WIDTH*HEIGHT-1 : 0] b_in,
    input var logic c_in
);
  var logic [HEIGHT-1 : 0] c;
  var logic [HEIGHT-1 : 0] p;
  var logic [HEIGHT-1 : 0] g;

  for (genvar i = 0; i < HEIGHT; i++) begin : gen_group
    FastAdder #(
        .BITS(WIDTH)
    ) fa (
        .pg_out(p[i]),
        .gg_out(g[i]),
        .sum_out(sum_out[i*WIDTH+:WIDTH]),
        .a_in(a_in[i*WIDTH+:WIDTH]),
        .b_in(b_in[i*WIDTH+:WIDTH]),
        .c_in(c[i])
    );
  end

  LookAheadCarry #(
      .BITS(HEIGHT)
  ) cla (
      .pg_out,
      .gg_out,
      .c_out(c),
      .p_in (p),
      .g_in (g),
      .c_in
  );
endmodule
