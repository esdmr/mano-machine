`include "preamble.sv"
`IMPORT(CarryGroup)

/**
 * Calculate the effective input carry of a group of partial full address.
 */
module LookAheadCarry #(
    parameter int BITS = 4
) (
    output var logic pg_out,
    output var logic gg_out,
    output var logic [BITS-1 : 0] c_out,
    input var logic [BITS-1 : 0] p_in,
    input var logic [BITS-1 : 0] g_in,
    input var logic c_in
);
  var logic carry[BITS+1];

  for (genvar i = 0; i < BITS; i++) begin : gen_carry_out
    assign c_out[i] = carry[i];
  end

  for (genvar i = 0; i < BITS; i++) begin : gen_carry_group
    if (i == 0) begin : gen_first
      assign carry[i] = c_in;
    end else begin : gen_rest
      CarryGroup cg (
          .c_out(carry[i]),
          .p_in (p_in[i-1]),
          .g_in (g_in[i-1]),
          .c_in (carry[i-1])
      );
    end
  end

  assign pg_out = &p_in;

  var logic [BITS-1 : 0] gg_array;

  for (genvar i = 0; i < BITS; i++) begin : gen_gg
    if (i == BITS - 1) begin : gen_last
      assign gg_array[i] = g_in[i];
    end else begin : gen_rest
      assign gg_array[i] = g_in[i] && &p_in[BITS-1 : i+1];
    end
  end

  assign gg_out = |gg_array;
endmodule
