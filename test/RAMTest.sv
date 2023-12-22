`include "preamble.sv"
`IMPORT(RAM)
`IMPORT(VirtualClock)

module RAMTest;
  `TAP_IO(30, 16)
  `TAP_CLOCK(VirtualClock)

  RAM #(
      .D_WIDTH(16),
      .A_WIDTH(12)
  ) dut (
      .data_out(tap_out),
      .data_in(tap_in[27 : 12]),
      .address_in(tap_in[11 : 0]),
      .read_enable_in(tap_in[29]),
      .write_enable_in(tap_in[28]),
      .clock(tap_clock)
  );

  `TAP_BEGIN
  `TAP_INIT(dut.content[12'h200] = 16'h1234;)
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h0000, 12'h000}, 16'hxxxx, "initial state")
  `TAP_CASE_AT_NEGEDGE({2'b01, 16'h0000, 12'h000}, 16'hxxxx, "reset state")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h0000, 12'h000}, 16'h0000, "hold reset state")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h0000, 12'h001}, 16'hxxxx, "next memory tile")
  `TAP_CASE_AT_NEGEDGE({2'b01, 16'h5f5f, 12'h001}, 16'hxxxx, "set state")
  `TAP_CASE_AT_NEGEDGE({2'b00, 16'h5f5f, 12'h001}, 16'hxxxx,
                         "no read hold set state")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h5f5f, 12'h001}, 16'h5f5f,
                         "read hold set state")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'hf5f5, 12'h001}, 16'h5f5f, "hold 2 set state")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h5f5f, 12'h000}, 16'h0000, "previous tile")
  `TAP_CASE_AT_NEGEDGE({2'b00, 16'hf5f5, 12'h001}, 16'h0000,
                         "output when not reading")
  `TAP_CASE_AT_NEGEDGE({2'b10, 16'h4242, 12'h200}, 16'h1234,
                         "can read data set memory")
  `TAP_END
endmodule
