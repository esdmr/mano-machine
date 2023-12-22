`include "preamble.sv"
`IMPORT(RAM)
`IMPORT(Encoder3)
`IMPORT(Register)
`IMPORT(SequenceCounter)
`IMPORT(JKFlipFlop)
`IMPORT(ControlUnit)
`IMPORT(ALU)

/**
 * Define a register along with its pins.
 *
 * @param __SOC_NAME__ - name of register. Should be a valid identifier.
 * @param __SOC_BITS__ - width of register. Should be an integer literal.
 */
`define SOC_REGISTER(__SOC_NAME__, __SOC_BITS__)        \
  var logic [__SOC_BITS__-1:0] __SOC_NAME__``_data_out; \
  var logic [__SOC_BITS__-1:0] __SOC_NAME__``_data_in;  \
  var logic __SOC_NAME__``_load;                        \
  var logic __SOC_NAME__``_increment;                   \
  var logic __SOC_NAME__``_clear;                       \
  Register #(                                           \
      .BITS(__SOC_BITS__)                               \
  ) __SOC_NAME__ (                                      \
      .data_out(__SOC_NAME__``_data_out),               \
      .data_in(__SOC_NAME__``_data_in),                 \
      .load_in(__SOC_NAME__``_load),                    \
      .increment_in(__SOC_NAME__``_increment),          \
      .clear_in(__SOC_NAME__``_clear),                  \
      .clock                                            \
  );

/**
 * Define a JK flipflop along with its pins.
 *
 * @param __SOC_NAME__ - name of flipflop. Should be a valid identifier.
 */
`define SOC_FLAG(__SOC_NAME__)     \
  var logic __SOC_NAME__``_data;   \
  var logic __SOC_NAME__``_j;      \
  var logic __SOC_NAME__``_k;      \
  JKFlipFlop __SOC_NAME__ (        \
      .q_out(__SOC_NAME__``_data), \
      .j_in (__SOC_NAME__``_j),    \
      .k_in (__SOC_NAME__``_k),    \
      .clock                       \
  );

/**
 * Connect the output of a component to the bus.
 *
 * @param __SOC_NAME__ - name of component. Should be a valid identifier.
 * @param __SOC_IDX__ - bus selector. Should be an integer literal.
 */
`define SOC_BUS_INPUT(__SOC_NAME__, __SOC_IDX__) \
  assign bus_in[__SOC_IDX__] = 16'(__SOC_NAME__``_data_out);

/**
 * Connect the input of a component to the bus.
 *
 * @param __SOC_NAME__ - name of component. Should be a valid identifier.
 */
`define SOC_BUS_OUTPUT(__SOC_NAME__) \
  assign __SOC_NAME__``_data_in = bus_out[0+:$bits(__SOC_NAME__``_data_in)];

/**
 * Connect both sides of a component to the bus.
 *
 * @param __SOC_NAME__ - name of component. Should be a valid identifier.
 * @param __SOC_IDX__ - bus selector. Should be an integer literal.
 */
`define SOC_BUS_INOUT(__SOC_NAME__, __SOC_IDX__) \
  `SOC_BUS_INPUT(__SOC_NAME__, __SOC_IDX__)      \
  `SOC_BUS_OUTPUT(__SOC_NAME__)

/**
 * The computer minus the I/O. Synthesizable, unlike `VirtualComputer`.
 */
module SOC (
    output var logic [7:0] data_out,
    output var logic fgi_out,
    output var logic fgo_out,
    output var logic s_out,
    input var logic [7:0] data_in,
    input var logic load_in,
    input var logic clear_in,
    input var logic boot_in,
    input var logic clock
);
  var logic [15 : 0] bus_in[8];
  var logic [15 : 0] bus_out;
  var logic [2 : 0] bus_selector_out;
  assign bus_in[0] = '0;
  assign bus_out   = bus_in[bus_selector_out];

  var logic [7 : 0] bus_selector_in;
  Encoder3 busSelector (
      .data_out(bus_selector_out),
      .data_in (bus_selector_in)
  );

  var logic mem_read_enable;
  var logic mem_write_enable;
  RAM #(
      .D_WIDTH(16),
      .A_WIDTH(12)
  ) mem (
      .data_out(bus_in[7]),
      .data_in(bus_out),
      .address_in(ar_data_out),
      .read_enable_in(mem_read_enable),
      .write_enable_in(mem_write_enable),
      .clock
  );

  `SOC_REGISTER(ar, 12)
  `SOC_BUS_INOUT(ar, 1)

  `SOC_REGISTER(pc, 12)
  `SOC_BUS_INOUT(pc, 2)

  `SOC_REGISTER(dr, 16)
  `SOC_BUS_INOUT(dr, 3)

  `SOC_REGISTER(ac, 16)
  `SOC_BUS_INPUT(ac, 4)

  `SOC_REGISTER(inpr, 8)
  assign inpr_data_in = data_in;

  `SOC_REGISTER(ir, 16)
  `SOC_BUS_INOUT(ir, 5)

  `SOC_REGISTER(tr, 16)
  `SOC_BUS_INOUT(tr, 6)

  `SOC_REGISTER(outr, 8)
  `SOC_BUS_OUTPUT(outr)
  assign data_out = outr_data_out;

  `SOC_FLAG(fgi)
  assign fgi_out = fgi_data;

  `SOC_FLAG(fgo)
  assign fgo_out = fgo_data;

  `SOC_FLAG(s)
  assign s_out = s_data;

  `SOC_FLAG(e)
  `SOC_FLAG(r)
  `SOC_FLAG(ien)

  var logic carry;
  var logic op_and;
  var logic op_add;
  var logic op_dr;
  var logic op_inpr;
  var logic op_complement;
  var logic op_cir;
  var logic op_cil;
  ALU alu (
      .c_out(carry),
      .ac_out(ac_data_in),
      .ac_in(ac_data_out),
      .dr_in(dr_data_out),
      .inpr_in(inpr_data_out),
      .c_in(e_data),
      .op_and_in(op_and),
      .op_add_in(op_add),
      .op_dr_in(op_dr),
      .op_inpr_in(op_inpr),
      .op_complement_in(op_complement),
      .op_cir_in(op_cir),
      .op_cil_in(op_cil)
  );

  var logic [15:0] timer;
  var logic sc_clear;
  SequenceCounter #(
      .BITS(4)
  ) sc (
      .timer_out(timer),
      .clear_in (sc_clear),
      .clock
  );

  ControlUnit cu (
      .bus_selector_out(bus_selector_in),
      .ac_clear_out(ac_clear),
      .ac_increment_out(ac_increment),
      .ac_load_out(ac_load),
      .op_add_out(op_add),
      .op_and_out(op_and),
      .op_complement_out(op_complement),
      .op_dr_out(op_dr),
      .op_inpr_out(op_inpr),
      .op_cil_out(op_cil),
      .op_cir_out(op_cir),
      .ar_clear_out(ar_clear),
      .ar_increment_out(ar_increment),
      .ar_load_out(ar_load),
      .dr_clear_out(dr_clear),
      .dr_increment_out(dr_increment),
      .dr_load_out(dr_load),
      .e_j_out(e_j),
      .e_k_out(e_k),
      .inpr_load_out(inpr_load),
      .inpr_increment_out(inpr_increment),
      .inpr_clear_out(inpr_clear),
      .fgi_j_out(fgi_j),
      .fgi_k_out(fgi_k),
      .fgo_j_out(fgo_j),
      .fgo_k_out(fgo_k),
      .s_j_out(s_j),
      .s_k_out(s_k),
      .ien_j_out(ien_j),
      .ien_k_out(ien_k),
      .ir_load_out(ir_load),
      .ir_increment_out(ir_increment),
      .ir_clear_out(ir_clear),
      .mem_read_enable_out(mem_read_enable),
      .mem_write_enable_out(mem_write_enable),
      .outr_load_out(outr_load),
      .outr_increment_out(outr_increment),
      .outr_clear_out(outr_clear),
      .pc_clear_out(pc_clear),
      .pc_increment_out(pc_increment),
      .pc_load_out(pc_load),
      .r_j_out(r_j),
      .r_k_out(r_k),
      .sc_clear_out(sc_clear),
      .tr_clear_out(tr_clear),
      .tr_increment_out(tr_increment),
      .tr_load_out(tr_load),
      .instruction_in(ir_data_out),
      .ac_in(ac_data_out),
      .dr_in(dr_data_out),
      .carry_in(carry),
      .e_in(e_data),
      .fgi_in(fgi_out),
      .fgo_in(fgo_out),
      .ien_in(ien_data),
      .r_in(r_data),
      .s_in(s_out),
      .clear_in,
      .load_in,
      .boot_in,
      .timer_in(timer)
  );
endmodule
