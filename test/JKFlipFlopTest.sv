`include "preamble.sv"
`IMPORT(JKFlipFlop)
`IMPORT(VirtualClock)

module JKFlipFlopTest;
  `TAP_IO(2, 1)
  `TAP_CLOCK(VirtualClock)

  JKFlipFlop dut (
      .q_out(tap_out),
      .j_in (tap_in[0]),
      .k_in (tap_in[1]),
      .clock(tap_clock)
  );

  `TAP_BEGIN
  `TAP_CASE_AT_NEGEDGE(2'b00, 'x, "initial state")
  `TAP_CASE_AT_NEGEDGE(2'b01, '1, "j down")
  `TAP_CASE_AT_NEGEDGE(2'b01, '1, "j hold")
  `TAP_CASE_AT_NEGEDGE(2'b00, '1, "j up")
  `TAP_CASE_AT_NEGEDGE(2'b10, '0, "k down")
  `TAP_CASE_AT_NEGEDGE(2'b10, '0, "k hold")
  `TAP_CASE_AT_NEGEDGE(2'b00, '0, "k up")
  `TAP_CASE_AT_NEGEDGE(2'b11, '1, "jk down 1")
  `TAP_CASE_AT_NEGEDGE(2'b11, '0, "jk hold 1")
  `TAP_CASE_AT_NEGEDGE(2'b11, '1, "jk hold 2")
  `TAP_CASE_AT_NEGEDGE(2'b00, '1, "jk up")
  `TAP_CASE_AT_NEGEDGE(2'b11, '0, "jk down 2")
  `TAP_CASE_AT_NEGEDGE(2'b00, '0, "jk up")
  `TAP_END
endmodule
