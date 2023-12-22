`include "preamble.sv"

/**
 * 16×4 one-hot encoder.
 */
module Encoder4 (
    output var logic [4-1 : 0] data_out,
    /* verilator lint_off UNUSEDSIGNAL */
    input var logic [2**4-1 : 0] data_in
    /* verilator lint_on UNUSEDSIGNAL */
);
  assign data_out[0] = (
    data_in[1] ||
    data_in[3] ||
    data_in[5] ||
    data_in[7] ||
    data_in[9] ||
    data_in[11] ||
    data_in[13] ||
    data_in[15]
  );
  assign data_out[1] = |data_in[2+:2] || |data_in[6+:2] || |data_in[10+:2] || |data_in[14+:2];
  assign data_out[2] = |data_in[4+:4] || |data_in[12+:4];
  assign data_out[3] = |data_in[8+:8];
endmodule
