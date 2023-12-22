`include "preamble.sv"

/**
 * 8×3 one-hot encoder.
 */
module Encoder3 (
    output var logic [3-1 : 0] data_out,
    /* verilator lint_off UNUSEDSIGNAL */
    input var logic [2**3-1 : 0] data_in
    /* verilator lint_on UNUSEDSIGNAL */
);
  assign data_out[0] = data_in[1] || data_in[3] || data_in[5] || data_in[7];
  assign data_out[1] = |data_in[2+:2] || |data_in[6+:2];
  assign data_out[2] = |data_in[4+:4];
endmodule
