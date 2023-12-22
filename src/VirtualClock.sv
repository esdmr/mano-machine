`include "preamble.sv"

/**
 * Generates a clock pulse. Not synthesizable.
 */
module VirtualClock (
    output var logic clock_out = 0
);
  initial forever #1 clock_out = ~clock_out;
endmodule
