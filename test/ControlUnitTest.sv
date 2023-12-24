`include "preamble.sv"
`IMPORT(ControlUnit)

module ControlUnitTest;
  var logic [7 : 0] bus_selector_out;
  var logic e_j_out;
  var logic e_k_out;
  var logic fgi_j_out;
  var logic fgi_k_out;
  var logic fgo_j_out;
  var logic fgo_k_out;
  var logic ien_j_out;
  var logic ien_k_out;
  var logic r_j_out;
  var logic r_k_out;
  var logic s_j_out;
  var logic s_k_out;
  var logic ac_clear_out;
  var logic ac_increment_out;
  var logic ac_load_out;
  var logic ar_clear_out;
  var logic ar_increment_out;
  var logic ar_load_out;
  var logic dr_clear_out;
  var logic dr_increment_out;
  var logic dr_load_out;
  var logic inpr_clear_out;
  var logic inpr_increment_out;
  var logic inpr_load_out;
  var logic ir_clear_out;
  var logic ir_increment_out;
  var logic ir_load_out;
  var logic mem_read_enable_out;
  var logic mem_write_enable_out;
  var logic op_add_out;
  var logic op_and_out;
  var logic op_complement_out;
  var logic op_dr_out;
  var logic op_inpr_out;
  var logic op_cil_out;
  var logic op_cir_out;
  var logic outr_clear_out;
  var logic outr_increment_out;
  var logic outr_load_out;
  var logic pc_clear_out;
  var logic pc_increment_out;
  var logic pc_load_out;
  var logic sc_clear_out;
  var logic tr_clear_out;
  var logic tr_increment_out;
  var logic tr_load_out;
  var instruction_t instruction_in;
  var logic [15:0] ac_in;
  var logic [15:0] dr_in;
  var logic boot_in;
  var logic carry_in;
  var logic e_in;
  var logic fgi_in;
  var logic fgo_in;
  var logic ien_in;
  var logic r_in;
  var logic s_in;
  var logic load_in;
  var logic clear_in;
  var logic [15:0] timer_in;

  var logic [53:0] outputs;

  assign outputs = {
    bus_selector_out,
    e_j_out,
    e_k_out,
    fgi_j_out,
    fgi_k_out,
    fgo_j_out,
    fgo_k_out,
    ien_j_out,
    ien_k_out,
    r_j_out,
    r_k_out,
    s_j_out,
    s_k_out,
    ac_clear_out,
    ac_increment_out,
    ac_load_out,
    ar_clear_out,
    ar_increment_out,
    ar_load_out,
    dr_clear_out,
    dr_increment_out,
    dr_load_out,
    inpr_clear_out,
    inpr_increment_out,
    inpr_load_out,
    ir_clear_out,
    ir_increment_out,
    ir_load_out,
    mem_read_enable_out,
    mem_write_enable_out,
    op_add_out,
    op_and_out,
    op_complement_out,
    op_dr_out,
    op_inpr_out,
    op_cil_out,
    op_cir_out,
    outr_clear_out,
    outr_increment_out,
    outr_load_out,
    pc_clear_out,
    pc_increment_out,
    pc_load_out,
    sc_clear_out,
    tr_clear_out,
    tr_increment_out,
    tr_load_out
  };

  var logic [73:0] inputs;

  assign inputs = {
    instruction_in,
    ac_in,
    dr_in,
    boot_in,
    carry_in,
    e_in,
    fgi_in,
    fgo_in,
    ien_in,
    r_in,
    s_in,
    load_in,
    clear_in,
    timer_in
  };

  task static clear_inputs();
    instruction_in = 'x;
    ac_in = 'x;
    dr_in = 'x;
    boot_in = '0;
    carry_in = 'x;
    e_in = 'x;
    fgi_in = 'x;
    fgo_in = 'x;
    ien_in = 'x;
    r_in = 'x;
    s_in = '1;
    load_in = 'x;
    clear_in = 'x;
    timer_in = 'x;
  endtask

  ControlUnit dut (
      .bus_selector_out,
      .e_j_out,
      .e_k_out,
      .fgi_j_out,
      .fgi_k_out,
      .fgo_j_out,
      .fgo_k_out,
      .ien_j_out,
      .ien_k_out,
      .r_j_out,
      .r_k_out,
      .s_j_out,
      .s_k_out,
      .ac_clear_out,
      .ac_increment_out,
      .ac_load_out,
      .ar_clear_out,
      .ar_increment_out,
      .ar_load_out,
      .dr_clear_out,
      .dr_increment_out,
      .dr_load_out,
      .inpr_clear_out,
      .inpr_increment_out,
      .inpr_load_out,
      .ir_clear_out,
      .ir_increment_out,
      .ir_load_out,
      .mem_read_enable_out,
      .mem_write_enable_out,
      .op_add_out,
      .op_and_out,
      .op_complement_out,
      .op_dr_out,
      .op_inpr_out,
      .op_cil_out,
      .op_cir_out,
      .outr_clear_out,
      .outr_increment_out,
      .outr_load_out,
      .pc_clear_out,
      .pc_increment_out,
      .pc_load_out,
      .sc_clear_out,
      .tr_clear_out,
      .tr_increment_out,
      .tr_load_out,
      .instruction_in,
      .ac_in,
      .dr_in,
      .timer_in,
      .boot_in,
      .carry_in,
      .e_in,
      .fgi_in,
      .fgo_in,
      .ien_in,
      .r_in,
      .s_in,
      .load_in,
      .clear_in
  );

  localparam int NULL = 0;
  localparam int AR = 1;
  localparam int PC = 2;
  localparam int DR = 3;
  localparam int AC = 4;
  localparam int IR = 5;
  localparam int TR = 6;
  localparam int MEM = 7;

  `TAP_BEGIN
  // Fetch
  `TAP_INIT(clear_inputs(); r_in = 0; timer_in = 1 << 0; #1;)
  `TAP_TEST(bus_selector_out[PC] && ar_load_out, "!r_in && timer_in[0]")
  `TAP_INIT(clear_inputs(); r_in = 0; timer_in = 1 << 1; #1;)
  `TAP_TEST(bus_selector_out[MEM] && ir_load_out && pc_increment_out,
            "!r_in && timer_in[1]")

  // Decode
  `TAP_INIT(clear_inputs(); r_in = 0; timer_in = 1 << 2; #1;)
  `TAP_TEST(bus_selector_out[IR] && ar_load_out, "!r_in && timer_in[2]")

  // Indirect
  `TAP_INIT(
      clear_inputs(); instruction_in = 0; instruction_in.mode = 1; timer_in = 1 << 3; #1;)
  `TAP_TEST(bus_selector_out[MEM] && ar_load_out,
            "!data[7] && mode && timer_in[3]")

  // Interrupt
  `TAP_INIT(clear_inputs(); timer_in = 1 << 3; ien_in = 1; fgi_in = 1; #1;)
  `TAP_TEST(r_j_out,
            "!timer_in[0] && !timer_in[1] && !timer_in[2] && ien_in && fgi_in")
  `TAP_INIT(clear_inputs(); timer_in = 1 << 3; ien_in = 1; fgo_in = 1; #1;)
  `TAP_TEST(r_j_out,
            "!timer_in[0] && !timer_in[1] && !timer_in[2] && ien_in && fgo_in")

  // TODO: Add more tests
  `TAP_END
endmodule
