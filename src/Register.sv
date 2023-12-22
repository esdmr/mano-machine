`include "preamble.sv"
`IMPORT(RippleCarryIncrementer)

/**
 * Synchronized data storage with load, increment, and clear pins.
 */
module Register #(
    parameter int BITS = 16
) (
    output var logic [BITS-1 : 0] data_out = 'x,
    input var logic [BITS-1 : 0] data_in,
    input var logic load_in,
    input var logic increment_in,
    input var logic clear_in,
    input var logic clock
);
  var logic [BITS-1 : 0] incremented;

  RippleCarryIncrementer #(
      .BITS(BITS)
  ) rci (
      .c_out(),
      .data_out(incremented),
      .data_in(data_out)
  );

  always_ff @(posedge clock)
    if (clear_in) data_out <= '0;
    else if (load_in) data_out <= data_in;
    else if (increment_in) data_out <= incremented;
endmodule
