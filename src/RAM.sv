`include "preamble.sv"

/**
 * Mass data storage.
 *
 * @param D_WIDTH data width, or word size, in bits.
 * @param A_WIDTH address width.
 */
module RAM #(
    parameter int D_WIDTH = 16,
    parameter int A_WIDTH = 12
) (
    output var logic [D_WIDTH-1 : 0] data_out = 'x,
    input var logic [D_WIDTH-1 : 0] data_in,
    input var logic [A_WIDTH-1 : 0] address_in,
    input var logic read_enable_in,
    input var logic write_enable_in,
    input var logic clock
);
  var logic [D_WIDTH-1 : 0] content[2**A_WIDTH];  // = 'x

  /* verilator lint_off NOLATCH */
  always_latch if (read_enable_in) data_out = content[address_in];
  /* verilator lint_on NOLATCH */
  always_ff @(posedge clock)
    if (write_enable_in)
      content[address_in] <= data_in;
endmodule
