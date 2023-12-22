`include "preamble.sv"
`IMPORT(Register)
`IMPORT(VirtualClock)

module RegisterTest;
  `TAP_IO(11, 8)
  `TAP_CLOCK(VirtualClock)

  Register #(
      .BITS(8)
  ) dut (
      .data_out(tap_out),
      .data_in(tap_in[7 : 0]),
      .load_in(tap_in[8]),
      .increment_in(tap_in[9]),
      .clear_in(tap_in[10]),
      .clock(tap_clock)
  );

  `TAP_BEGIN
  `TAP_CASE_AT_NEGEDGE({3'b000, 8'h00}, 8'hxx, "initial state")
  `TAP_CASE_AT_NEGEDGE({3'b000, 8'hf5}, 8'hxx, "hold initial state")
  `TAP_CASE_AT_NEGEDGE({3'b001, 8'h00}, 8'h00, "initial state")
  `TAP_CASE_AT_NEGEDGE({3'b001, 8'hf5}, 8'hf5, "load state")
  `TAP_CASE_AT_NEGEDGE({3'b000, 8'h5f}, 8'hf5, "hold state")
  `TAP_CASE_AT_NEGEDGE({3'b010, 8'h5f}, 8'hf6, "increment state")
  `TAP_CASE_AT_NEGEDGE({3'b010, 8'h5f}, 8'hf7, "second increment state")
  `TAP_CASE_AT_NEGEDGE({3'b000, 8'h5f}, 8'hf7, "hold increment state")
  `TAP_CASE_AT_NEGEDGE({3'b100, 8'h5f}, 8'h00, "clear state")
  `TAP_CASE_AT_NEGEDGE({3'b000, 8'h5f}, 8'h00, "hold clear state")
  `TAP_END
endmodule
