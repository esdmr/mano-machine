`include "preamble.sv"
`IMPORT(instruction)

/**
 * Define a `wor` alias for an output.
 *
 * @param __CU_NAME__ - name of alias. Should be a valid identifier.
 */
`define CU_DEF_ALIAS(__CU_NAME__) \
  wor __CU_NAME__;                \
  assign __CU_NAME__``_out = __CU_NAME__;

/**
 * Define a JK flipflop which is active at boot.
 *
 * @param __CU_NAME__ - name of flipflop. Should be a valid identifier.
 */
`define CU_DEF_FF_J(__CU_NAME__)                           \
  wor __CU_NAME__``_j;                                     \
  wor __CU_NAME__``_k;                                     \
  assign __CU_NAME__``_j_out = boot_in || __CU_NAME__``_j; \
  assign __CU_NAME__``_k_out = !boot_in && __CU_NAME__``_k;

/**
 * Define a JK flipflop which is inactive at boot.
 *
 * @param __CU_NAME__ - name of flipflop. Should be a valid identifier.
 */
`define CU_DEF_FF_K(__CU_NAME__)                            \
  wor __CU_NAME__``_j;                                      \
  wor __CU_NAME__``_k;                                      \
  assign __CU_NAME__``_j_out = !boot_in && __CU_NAME__``_j; \
  assign __CU_NAME__``_k_out = boot_in || __CU_NAME__``_k;

/**
 * Activate flipflop at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of flipflop. Should be a valid identifier.
 */
`define CU_FF_J(__CU_IF__, __CU_DST__) \
  assign __CU_DST__``_j = __CU_IF__;

/**
 * Deactivate flipflop at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of flipflop. Should be a valid identifier.
 */
`define CU_FF_K(__CU_IF__, __CU_DST__) \
  assign __CU_DST__``_k = __CU_IF__;

/**
 * Complement flipflop at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of flipflop. Should be a valid identifier.
 */
`define CU_FF_NOT(__CU_IF__, __CU_DST__) \
  if (1 == 1) begin                      \
    var logic condition;                 \
    assign condition = __CU_IF__;        \
    `CU_FF_J(condition, __CU_DST__)      \
    `CU_FF_K(condition, __CU_DST__)      \
  end

/**
 * Set flipflop at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of flipflop. Should be a valid identifier.
 */
`define CU_FF_EQ(__CU_IF__, __CU_DST__, __CU_SRC__) \
  if (1 == 1) begin                                 \
    var logic condition;                            \
    assign condition = __CU_IF__;                   \
    var logic value;                                \
    assign value = __CU_SRC__;                      \
    `CU_FF_J(condition && value, __CU_DST__)        \
    `CU_FF_K(condition && !value, __CU_DST__)       \
  end

/**
 * Enable load pin at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of register. Should be a valid identifier.
 */
`define CU_LD(__CU_IF__, __CU_DST__) \
  assign __CU_DST__``_load = __CU_IF__;

/**
 * Enable clear pin at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of register. Should be a valid identifier.
 */
`define CU_CLR(__CU_IF__, __CU_DST__) \
  assign __CU_DST__``_clear = __CU_IF__;

/**
 * Enable increment pin at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of register. Should be a valid identifier.
 */
`define CU_INC(__CU_IF__, __CU_DST__) \
  assign __CU_DST__``_increment = __CU_IF__;

/**
 * Select a bus component at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_SRC__ - name of component. Should be a valid identifier.
 */
`define CU_SL(__CU_IF__, __CU_SRC__) \
  assign bus_selector[__CU_SRC__``_index] = __CU_IF__;

/**
 * Move data between two registers at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of destination. Should be a valid identifier.
 * @param __CU_SRC__ - name of source. Should be a valid identifier.
 */
`define CU_MOV(__CU_IF__, __CU_DST__, __CU_SRC__) \
  if (1 == 1) begin                               \
    var logic condition;                          \
    assign condition = __CU_IF__;                 \
    `CU_LD(condition, __CU_DST__)                 \
    `CU_SL(condition, __CU_SRC__)                 \
  end

/**
 * Move data from memory at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_DST__ - name of destination. Should be a valid identifier.
 */
`define CU_LOAD(__CU_IF__, __CU_DST__)  \
  if (1 == 1) begin                     \
    var logic condition;                \
    assign condition = __CU_IF__;       \
    `CU_LD(condition, __CU_DST__)       \
    assign mem_read_enable = condition; \
  end

/**
 * Move data to memory at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_SRC__ - name of source. Should be a valid identifier.
 */
`define CU_STORE(__CU_IF__, __CU_SRC__)  \
  if (1 == 1) begin                      \
    var logic condition;                 \
    assign condition = __CU_IF__;        \
    assign mem_write_enable = condition; \
    `CU_SL(condition, __CU_SRC__)        \
  end

/**
 * Do an ALU operation at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_OP__ - name of operation. Should be a valid identifier.
 */
`define CU_ALU(__CU_IF__, __CU_OP__)   \
  if (1 == 1) begin                    \
    var logic condition;               \
    assign condition = __CU_IF__;      \
    assign op_``__CU_OP__ = condition; \
    `CU_LD(condition, ac)              \
  end

/**
 * Do an ALU operation with carry at condition.
 *
 * @param __CU_IF__ - condition. Should be a 1 bit integer expression.
 * @param __CU_OP__ - name of operation. Should be a valid identifier.
 */
`define CU_ALU_CARRY(__CU_IF__, __CU_OP__)  \
  if (1 == 1) begin                         \
    var logic condition_outer;              \
    assign condition_outer = __CU_IF__;     \
    `CU_ALU(condition_outer, __CU_OP__)     \
    `CU_FF_EQ(condition_outer, e, carry_in) \
  end

/**
 * Manages the flow of data between registers and memory.
 */
module ControlUnit (
    output var logic [7 : 0] bus_selector_out,
    output var logic e_j_out,
    output var logic e_k_out,
    output var logic fgi_j_out,
    output var logic fgi_k_out,
    output var logic fgo_j_out,
    output var logic fgo_k_out,
    output var logic ien_j_out,
    output var logic ien_k_out,
    output var logic r_j_out,
    output var logic r_k_out,
    output var logic s_j_out,
    output var logic s_k_out,
    output var logic ac_clear_out,
    output var logic ac_increment_out,
    output var logic ac_load_out,
    output var logic ar_clear_out,
    output var logic ar_increment_out,
    output var logic ar_load_out,
    output var logic dr_clear_out,
    output var logic dr_increment_out,
    output var logic dr_load_out,
    output var logic inpr_clear_out,
    output var logic inpr_increment_out,
    output var logic inpr_load_out,
    output var logic ir_clear_out,
    output var logic ir_increment_out,
    output var logic ir_load_out,
    output var logic mem_read_enable_out,
    output var logic mem_write_enable_out,
    output var logic op_add_out,
    output var logic op_and_out,
    output var logic op_complement_out,
    output var logic op_dr_out,
    output var logic op_inpr_out,
    output var logic op_cil_out,
    output var logic op_cir_out,
    output var logic outr_clear_out,
    output var logic outr_increment_out,
    output var logic outr_load_out,
    output var logic pc_clear_out,
    output var logic pc_increment_out,
    output var logic pc_load_out,
    output var logic sc_clear_out,
    output var logic tr_clear_out,
    output var logic tr_increment_out,
    output var logic tr_load_out,
    input var instruction_t instruction_in,
    input var logic [15:0] ac_in,
    input var logic [15:0] dr_in,
    input var logic boot_in,
    input var logic carry_in,
    input var logic e_in,
    input var logic fgi_in,
    input var logic fgo_in,
    input var logic ien_in,
    input var logic r_in,
    input var logic s_in,
    input var logic load_in,
    input var logic clear_in,
    /* verilator lint_off UNUSEDSIGNAL */
    input var logic [15:0] timer_in
    /* verilator lint_on UNUSEDSIGNAL */
);
  `CU_DEF_ALIAS(ac_clear)
  `CU_DEF_ALIAS(ac_increment)
  `CU_DEF_ALIAS(ac_load)
  `CU_DEF_ALIAS(ar_clear)
  `CU_DEF_ALIAS(ar_increment)
  `CU_DEF_ALIAS(ar_load)
  `CU_DEF_ALIAS(dr_clear)
  `CU_DEF_ALIAS(dr_increment)
  `CU_DEF_ALIAS(dr_load)
  `CU_DEF_ALIAS(inpr_clear)
  `CU_DEF_ALIAS(inpr_increment)
  `CU_DEF_ALIAS(inpr_load)
  `CU_DEF_ALIAS(ir_clear)
  `CU_DEF_ALIAS(ir_increment)
  `CU_DEF_ALIAS(ir_load)
  `CU_DEF_ALIAS(mem_read_enable)
  `CU_DEF_ALIAS(mem_write_enable)
  `CU_DEF_ALIAS(op_add)
  `CU_DEF_ALIAS(op_and)
  `CU_DEF_ALIAS(op_complement)
  `CU_DEF_ALIAS(op_dr)
  `CU_DEF_ALIAS(op_inpr)
  `CU_DEF_ALIAS(op_cil)
  `CU_DEF_ALIAS(op_cir)
  `CU_DEF_ALIAS(outr_clear)
  `CU_DEF_ALIAS(outr_increment)
  `CU_DEF_ALIAS(outr_load)
  `CU_DEF_ALIAS(pc_clear)
  `CU_DEF_ALIAS(pc_increment)
  `CU_DEF_ALIAS(pc_load)
  `CU_DEF_ALIAS(sc_clear)
  `CU_DEF_ALIAS(tr_clear)
  `CU_DEF_ALIAS(tr_increment)
  `CU_DEF_ALIAS(tr_load)

  `CU_DEF_FF_K(e)
  `CU_DEF_FF_K(fgi)
  `CU_DEF_FF_J(fgo)
  `CU_DEF_FF_J(s)
  `CU_DEF_FF_K(ien)
  `CU_DEF_FF_K(r)

  `CU_CLR(!s_in, sc)
  `CU_CLR(boot_in, sc)
  `CU_CLR(boot_in, ar)
  `CU_CLR(boot_in, pc)
  `CU_CLR(boot_in, dr)
  `CU_CLR(boot_in, ac)
  `CU_CLR(boot_in, inpr)
  `CU_CLR(boot_in, ir)
  `CU_CLR(boot_in, tr)
  `CU_CLR(boot_in, outr)

  `CU_FF_J(load_in, fgi)
  `CU_LD(load_in, inpr)

  `CU_FF_J(clear_in, fgo)
  `CU_CLR(clear_in, outr)

  `CU_FF_J(0, s)
  `CU_INC(0, tr)
  `CU_INC(0, inpr)
  `CU_INC(0, outr)
  `CU_INC(0, ir)

  localparam int null_index = 0;  // verilog_lint: waive parameter-name-style
  localparam int ar_index = 1;  // verilog_lint: waive parameter-name-style
  localparam int pc_index = 2;  // verilog_lint: waive parameter-name-style
  localparam int dr_index = 3;  // verilog_lint: waive parameter-name-style
  localparam int ac_index = 4;  // verilog_lint: waive parameter-name-style
  localparam int ir_index = 5;  // verilog_lint: waive parameter-name-style
  localparam int tr_index = 6;  // verilog_lint: waive parameter-name-style
  localparam int mem_index = 7;  // verilog_lint: waive parameter-name-style

  wor [7:0] bus_selector;
  assign bus_selector_out = bus_selector;

  assign bus_selector[null_index] = '0;
  assign bus_selector[mem_index] = mem_read_enable_out;

  /* verilator lint_off GENUNNAMED */

  // Fetch
  `CU_MOV(!r_in && timer_in[0], ar, pc)
  `CU_LOAD(!r_in && timer_in[1], ir)
  `CU_INC(!r_in && timer_in[1], pc)

  // Decode
  `CU_MOV(!r_in && timer_in[2], ar, ir)

  var logic mode;
  assign mode = instruction_in.mode;

  var logic [7:0] data;
  assign data = 1 << instruction_in.opcode;

  var logic [11:0] operand;
  assign operand = instruction_in.operand;

  // Indirect
  `CU_LOAD(!data[7] && mode && timer_in[3], ar)

  // Interrupt
  var logic interrupt;
  assign interrupt = !timer_in[0] && !timer_in[1] && !timer_in[2] && ien_in && (fgi_in || fgo_in);

  `CU_FF_J(interrupt, r)
  `CU_CLR(r_in && timer_in[0], ar)
  `CU_MOV(r_in && timer_in[0], tr, pc)
  `CU_STORE(r_in && timer_in[1], tr)
  `CU_CLR(r_in && timer_in[1], pc)
  `CU_INC(r_in && timer_in[2], pc)
  `CU_FF_K(r_in && timer_in[2], ien)
  `CU_FF_K(r_in && timer_in[2], r)
  `CU_CLR(r_in && timer_in[2], sc)

  // Memory-reference
  //   AND
  `CU_LOAD(data[0] && timer_in[4], dr)
  `CU_ALU(data[0] && timer_in[5], and)
  `CU_CLR(data[0] && timer_in[5], sc)

  //   ADD
  `CU_LOAD(data[1] && timer_in[4], dr)
  `CU_ALU_CARRY(data[1] && timer_in[5], add)
  `CU_CLR(data[1] && timer_in[5], sc)

  //   LDA
  `CU_LOAD(data[2] && timer_in[4], dr)
  `CU_ALU(data[2] && timer_in[5], dr)
  `CU_CLR(data[2] && timer_in[5], sc)

  //   STA
  `CU_STORE(data[3] && timer_in[4], ac)
  `CU_CLR(data[3] && timer_in[4], sc)

  //   BUN
  `CU_MOV(data[4] && timer_in[4], pc, ar)
  `CU_CLR(data[4] && timer_in[4], sc)

  //   BSA
  `CU_STORE(data[5] && timer_in[4], pc)
  `CU_INC(data[5] && timer_in[4], ar)
  `CU_MOV(data[5] && timer_in[5], pc, ar)
  `CU_CLR(data[5] && timer_in[5], sc)

  //   ISZ
  `CU_LOAD(data[6] && timer_in[4], dr)
  `CU_INC(data[6] && timer_in[5], dr)
  `CU_STORE(data[6] && timer_in[6], dr)
  `CU_INC(data[6] && timer_in[6] && (dr_in == 0), pc)
  `CU_CLR(data[6] && timer_in[6], sc)

  // Register-reference
  var logic r;
  assign r = data[7] && !mode && timer_in[3];

  `CU_CLR(r, sc)
  `CU_CLR(r && operand[11], ac)  // CLA
  `CU_FF_K(r && operand[10], e)  // CLE
  `CU_ALU(r && operand[9], complement)  // CMA
  `CU_FF_NOT(r && operand[8], e)  // CME
  `CU_ALU_CARRY(r && operand[7], cir)  // CIR
  `CU_ALU_CARRY(r && operand[6], cil)  // CIL
  `CU_INC(r && operand[5], ac)  // INC
  `CU_INC(r && operand[4] && (ac_in[15] == 0), pc)  // SPA
  `CU_INC(r && operand[3] && (ac_in[15] == 1), pc)  // SNA
  `CU_INC(r && operand[2] && (ac_in == 0), pc)  // SZA
  `CU_INC(r && operand[1] && !e_in, pc)  // SZE
  `CU_FF_K(r && operand[0], s)  // HLT

  // Input-output
  var logic p;
  assign p = data[7] && mode && timer_in[3];

  `CU_CLR(p, sc)

  //   INP
  `CU_ALU(p && operand[11], inpr)
  `CU_FF_K(p && operand[11], fgi)

  //   OUT
  `CU_MOV(p && operand[10], outr, ac)
  `CU_FF_K(p && operand[10], fgo)

  `CU_INC(p && operand[9] && fgi_in, pc)  // SKI
  `CU_INC(p && operand[8] && fgo_in, pc)  // SKO
  `CU_FF_J(p && operand[7], ien)  // ION
  `CU_FF_K(p && operand[6], ien)  // IOF

  /* verilator lint_on GENUNNAMED */
endmodule
