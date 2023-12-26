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
  task static queue(input int char);
    if (char != -1 && !fgi_in) begin
      data_out = 8'(char & 'hff);

      load_out = '1;
      @(posedge fgi_in);
      load_out = '0;
    end
  endtask

  var int fd = 0;

  initial begin
`ifdef INPUT
    fd = $fopen(`INPUT, "r");
    forever @(posedge clock) if (!fgi_in) queue($fgetc(fd));
`else
    forever @(posedge clock) queue($read_char());
`endif
  end
endmodule
