`include "preamble.sv"
`IMPORT(SequenceCounter)
`IMPORT(VirtualClock)

module SequenceCounterTest;
  `TAP_IO(1, 16)
  `TAP_CLOCK(VirtualClock)

  SequenceCounter #(
      .BITS(4)
  ) dut (
      .timer_out(tap_out),
      .clear_in(tap_in),
      .clock(tap_clock)
  );

  `TAP_BEGIN
  `TAP_CASE_AT_NEGEDGE('0, 'x, "initial state");
  `TAP_CASE_AT_NEGEDGE('1, 1 << 'h0, "cycle 0");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h1, "cycle 1");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h2, "cycle 2");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h3, "cycle 3");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h4, "cycle 4");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h5, "cycle 5");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h6, "cycle 6");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h7, "cycle 7");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h8, "cycle 8");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h9, "cycle 9");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hA, "cycle A");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hB, "cycle B");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hC, "cycle C");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hD, "cycle D");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hE, "cycle E");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'hF, "cycle F");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h0, "overflow 0");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h1, "overflow 1");
  `TAP_CASE_AT_NEGEDGE('1, 1 << 'h0, "reset 0");
  `TAP_CASE_AT_NEGEDGE('0, 1 << 'h1, "reset 1");
  `TAP_CASE_AT_NEGEDGE('1, 1 << 'h0, "reset part 1");
  `TAP_CASE_AT_NEGEDGE('1, 1 << 'h0, "reset part 2");
  `TAP_END
endmodule
