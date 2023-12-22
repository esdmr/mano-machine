`include "preamble.sv"
`IMPORT(Register)

/**
 * Register which is always incrementing. Its output is decoded for use in the
 * control unit.
 */
module SequenceCounter #(
    parameter int BITS = 4
) (
    output var logic [2**BITS-1:0] timer_out,
    input var logic clear_in,
    input var logic clock
);
  var logic [BITS-1:0] data;

  Register #(
      .BITS(BITS)
  ) sc (
      .data_out(data),
      .data_in('0),
      .load_in('0),
      .increment_in('1),
      .clear_in,
      .clock
  );

  assign timer_out = 1 << data;
endmodule
