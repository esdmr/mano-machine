`include "preamble.sv"
`IMPORT(FastAdder2)
`IMPORT(CarryGroup)

/**
 * Defines each ALU operator.
 *
 * @param __ALU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __ALU_AC__ - value of AC. Should be a 16 bit integer expression.
 * @param __ALU_C__ - value of carry. Should be a 1 bit integer expression.
 */
`define ALU_OPERATOR(__ALU_IF__, __ALU_AC__, __ALU_C__) \
  assign ac = {16{__ALU_IF__}} & 16'(__ALU_AC__);       \
  assign c  = __ALU_IF__ & __ALU_C__;

/**
 * Calculates an operation depending on the selected operator.
 */
module ALU (
    output var logic c_out,
    output var logic [15:0] ac_out,
    input var logic [15:0] ac_in,
    input var logic [15:0] dr_in,
    input var logic [7:0] inpr_in,
    input var logic c_in,
    input var logic op_and_in,
    input var logic op_add_in,
    input var logic op_dr_in,
    input var logic op_inpr_in,
    input var logic op_complement_in,
    input var logic op_cir_in,
    input var logic op_cil_in
);
  wor c;
  assign c_out = c;
  wor [15:0] ac;
  assign ac_out = ac;

  var logic add_c_in;
  assign add_c_in = '0;

  var logic [15:0] add;
  var logic add_p;
  var logic add_g;
  FastAdder2 #(
      .WIDTH (4),
      .HEIGHT(4)
  ) fa (
      .pg_out(add_p),
      .gg_out(add_g),
      .sum_out(add),
      .a_in(ac_in),
      .b_in(dr_in),
      .c_in(add_c_in)
  );

  var logic add_c_out;
  CarryGroup cg (
      .c_out(add_c_out),
      .p_in (add_p),
      .g_in (add_g),
      .c_in (add_c_in)
  );

  var logic [15:0] cil;
  var logic cil_carry;
  assign cil_carry = ac_in[15];
  assign cil = {ac_in[14:0], c_in};

  var logic [15:0] cir;
  var logic cir_carry;
  assign cir_carry = ac_in[0];
  assign cir = {c_in, ac_in[15:1]};

  `ALU_OPERATOR(op_and_in, ac_in & dr_in, '0)
  `ALU_OPERATOR(op_add_in, add, add_c_out)
  `ALU_OPERATOR(op_dr_in, dr_in, '0)
  `ALU_OPERATOR(op_inpr_in, inpr_in, '0)
  `ALU_OPERATOR(op_complement_in, ~ac_in, '0)
  `ALU_OPERATOR(op_cil_in, cil, cil_carry)
  `ALU_OPERATOR(op_cir_in, cir, cir_carry)
endmodule
