`include "preamble.sv"

/**
 * Pass characters to the terminal (stdout). Not synthesizable.
 */
module VirtualPrinter (
    output var logic clear_out = '0,
    input var logic [7:0] data_in,
    input var logic fgo_in,
    input var logic clock
);
  initial
    forever
      @(posedge clock)
        if (!fgo_in) begin
          $write("%c", data_in);
          $fflush();

          clear_out = '1;
          @(posedge fgo_in);
          clear_out = '0;
        end
endmodule
