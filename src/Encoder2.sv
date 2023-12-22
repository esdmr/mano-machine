`include "preamble.sv"

/**
 * 4×2 one-hot encoder.
 */
module Encoder2 (
    output var logic [2-1 : 0] data_out,
    /* verilator lint_off UNUSEDSIGNAL */
    input var logic [2**2-1 : 0] data_in
    /* verilator lint_on UNUSEDSIGNAL */
);
  assign data_out[0] = data_in[1] || data_in[3];
  assign data_out[1] = |data_in[2+:2];
endmodule
