`include "preamble.sv"

/**
 * Read characters from terminal (stdin). Not synthesizable.
 */
module VirtualKeyboard (
    output var logic [7:0] data_out = 'x,
    output var logic load_out = '0,
    input var logic fgi_in,
    input var logic clock
);
  var int char = -1;

  initial
    forever
      @(posedge clock) begin
        char = $read_char();

        if (char != -1 && !fgi_in) begin
          data_out = 8'(char & 'hff);

          load_out = '1;
          @(posedge fgi_in);
          load_out = '0;
        end
      end
endmodule
