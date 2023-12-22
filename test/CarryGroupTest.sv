`include "preamble.sv"
`IMPORT(CarryGroup)

module CarryGroupTest;
  `TAP_IO(3, 1)

  CarryGroup dut (
      .c_out(tap_out),
      .p_in (tap_in[0]),
      .g_in (tap_in[2]),
      .c_in (tap_in[1])
  );

  `TAP_BEGIN
  `TAP_CASE(3'b000, 0, "[~p, ~g, ~cin]")
  `TAP_CASE(3'b001, 0, "[ p, ~g, ~cin]")
  `TAP_CASE(3'b010, 0, "[~p, ~g,  cin]")
  `TAP_CASE(3'b011, 1, "[ p, ~g,  cin]")
  `TAP_CASE(3'b100, 1, "[~p,  g, ~cin]")
  `TAP_CASE(3'b101, 1, "[ p,  g, ~cin]")
  `TAP_CASE(3'b110, 1, "[~p,  g,  cin]")
  `TAP_CASE(3'b111, 1, "[ p,  g,  cin]")
  `TAP_END
endmodule
