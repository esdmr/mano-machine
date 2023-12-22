`include "preamble.sv"
`IMPORT(LookAheadCarry)

module LookAheadCarryTest;
  `TAP_IO(5, 4)

  LookAheadCarry #(
      .BITS(2)
  ) dut (
      .pg_out(tap_out[2]),
      .gg_out(tap_out[3]),
      .c_out (tap_out[1:0]),
      .p_in  (tap_in[1:0]),
      .g_in  (tap_in[3:2]),
      .c_in  (tap_in[4])
  );

  `TAP_BEGIN
  `TAP_CASE({1'b0, 2'b00, 2'b00}, {2'b00, 2'b00}, "[p=00 g=00 !c_in]")
  `TAP_CASE({1'b1, 2'b00, 2'b00}, {2'b00, 2'b01}, "[p=00 g=00  c_in]")
  `TAP_CASE({1'b0, 2'b00, 2'b01}, {2'b00, 2'b00}, "[p=01 g=00 !c_in]")
  `TAP_CASE({1'b1, 2'b00, 2'b01}, {2'b00, 2'b11}, "[p=01 g=00  c_in]")
  `TAP_CASE({1'b0, 2'b00, 2'b10}, {2'b00, 2'b00}, "[p=10 g=00 !c_in]")
  `TAP_CASE({1'b1, 2'b00, 2'b10}, {2'b00, 2'b01}, "[p=10 g=00  c_in]")
  `TAP_CASE({1'b0, 2'b00, 2'b11}, {2'b01, 2'b00}, "[p=11 g=00 !c_in]")
  `TAP_CASE({1'b1, 2'b00, 2'b11}, {2'b01, 2'b11}, "[p=11 g=00  c_in]")
  `TAP_CASE({1'b0, 2'b01, 2'b01}, {2'b00, 2'b10}, "[p=01 g=01 !c_in]")
  `TAP_CASE({1'b1, 2'b01, 2'b01}, {2'b00, 2'b11}, "[p=01 g=01  c_in]")
  `TAP_CASE({1'b0, 2'b10, 2'b10}, {2'b10, 2'b00}, "[p=10 g=10 !c_in]")
  `TAP_CASE({1'b1, 2'b10, 2'b10}, {2'b10, 2'b01}, "[p=10 g=10  c_in]")
  `TAP_CASE({1'b0, 2'b01, 2'b11}, {2'b11, 2'b10}, "[p=11 g=01 !c_in]")
  `TAP_CASE({1'b1, 2'b01, 2'b11}, {2'b11, 2'b11}, "[p=11 g=01  c_in]")
  `TAP_CASE({1'b0, 2'b10, 2'b11}, {2'b11, 2'b00}, "[p=11 g=10 !c_in]")
  `TAP_CASE({1'b1, 2'b10, 2'b11}, {2'b11, 2'b11}, "[p=11 g=10  c_in]")
  `TAP_CASE({1'b0, 2'b11, 2'b11}, {2'b11, 2'b10}, "[p=11 g=11 !c_in]")
  `TAP_CASE({1'b1, 2'b11, 2'b11}, {2'b11, 2'b11}, "[p=11 g=11  c_in]")
  `TAP_END
endmodule
