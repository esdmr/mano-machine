`include "preamble.sv"

/**
 * 2×1 one-hot encoder.
 */
module Encoder1 (
    output var logic [1-1 : 0] data_out,
    /* verilator lint_off UNUSEDSIGNAL */
    input var logic [2**1-1 : 0] data_in
    /* verilator lint_on UNUSEDSIGNAL */
);
  assign data_out[0] = data_in[1];
endmodule
