`include "preamble.sv"
`IMPORT(ALU)

module ALUTest;
  `TAP_IO(48, 17)

  ALU dut (
      .c_out(tap_out[16]),
      .ac_out(tap_out[15:0]),
      .ac_in(tap_in[15:0]),
      .dr_in(tap_in[31:16]),
      .inpr_in(tap_in[39:32]),
      .c_in(tap_in[40]),
      .op_and_in(tap_in[41]),
      .op_add_in(tap_in[42]),
      .op_dr_in(tap_in[43]),
      .op_inpr_in(tap_in[44]),
      .op_complement_in(tap_in[45]),
      .op_cir_in(tap_in[46]),
      .op_cil_in(tap_in[47])
  );

  `TAP_BEGIN
  `TAP_CASE({8'b00000000, 8'hxx, 16'hxxxx, 16'hxxxx}, {1'b0, 16'h0000},
              "Zero output if no operator")

  // and
  `TAP_CASE({8'b0000001x, 8'hxx, 16'h5678, 16'h1234}, {1'b0, 16'h1230},
              "AND operator")

  // add
  `TAP_CASE({8'b0000010x, 8'hxx, 16'h5678, 16'h1234}, {1'b0, 16'h68ac},
              "ADD operator")
  `TAP_CASE({8'b0000010x, 8'hxx, 16'h5678, 16'hf234}, {1'b1, 16'h48ac},
              "ADD operator with carry out")

  // dr
  `TAP_CASE({8'b0000100x, 8'hxx, 16'h5678, 16'hxxxx}, {1'b0, 16'h5678},
              "DR operator")

  // inpr
  `TAP_CASE({8'b0001000x, 8'h9a, 16'hxxxx, 16'hxxxx}, {1'b0, 16'h009a},
              "INPR operator")

  // complement
  `TAP_CASE({8'b0010000x, 8'hxx, 16'hxxxx, 16'h1234}, {1'b0, 16'hedcb},
              "COMPLEMENT operator")

  // cir
  `TAP_CASE({8'b01000000, 8'hxx, 16'hxxxx, 16'h1234}, {1'b0, 16'h091a},
              "CIR operator")
  `TAP_CASE({8'b01000001, 8'hxx, 16'hxxxx, 16'h1234}, {1'b0, 16'h891a},
              "CIR operator with carry in")
  `TAP_CASE({8'b01000000, 8'hxx, 16'hxxxx, 16'h1235}, {1'b1, 16'h091a},
              "CIR operator with carry out")
  `TAP_CASE({8'b01000001, 8'hxx, 16'hxxxx, 16'h1235}, {1'b1, 16'h891a},
              "CIR operator with carry")

  // cil
  `TAP_CASE({8'b10000000, 8'hxx, 16'hxxxx, 16'h1234}, {1'b0, 16'h2468},
              "CIL operator")
  `TAP_CASE({8'b10000001, 8'hxx, 16'hxxxx, 16'h1234}, {1'b0, 16'h2469},
              "CIL operator with carry in")
  `TAP_CASE({8'b10000000, 8'hxx, 16'hxxxx, 16'h9234}, {1'b1, 16'h2468},
              "CIL operator with carry out")
  `TAP_CASE({8'b10000001, 8'hxx, 16'hxxxx, 16'h9234}, {1'b1, 16'h2469},
              "CIL operator with carry")

  `TAP_END
endmodule
