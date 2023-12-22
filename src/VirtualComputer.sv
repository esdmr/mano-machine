`include "preamble.sv"
`timescale 1s / 1ms
`IMPORT(assembler)
`IMPORT(SOC)
`IMPORT(VirtualClock)
`IMPORT(VirtualKeyboard)
`IMPORT(VirtualPrinter)

`undef _ASM_SET_MEMORY_
/**
 * Implement set memory from the assembler.
 */
`define _ASM_SET_MEMORY_(__ASM_DATA__, __ASM_ADDR__, __ASM_INST__) \
  set_memory(__ASM_DATA__, __ASM_ADDR__, __ASM_INST__);

`undef _ASM_PROBE_MEMORY_
/**
 * Implement probe memory from the assembler.
 */
`define _ASM_PROBE_MEMORY_(__ASM_TARGET__, __ASM_ADDR__) \
  assign __ASM_TARGET__ = soc.mem.content[__ASM_ADDR__];

/**
 * The computer along with I/O and a preloaded assembly program. Not
 * synthesizable.
 */
module VirtualComputer;
  var logic [7:0] data_out;
  var logic [7:0] data_in;
  var logic fgi;
  var logic fgo;
  var logic clear;
  var logic load;
  var logic clock;
  var logic boot = 0;
  var logic s;

  SOC soc (
      .data_out,
      .fgi_out(fgi),
      .fgo_out(fgo),
      .s_out(s),
      .data_in,
      .boot_in(boot),
      .load_in(load),
      .clear_in(clear),
      .clock
  );

  initial begin
    @(posedge clock);
    boot = 1;
    @(posedge clock);
    boot = 0;
  end

  initial begin
    @(negedge s);
    @(posedge clock);
    $display("");
    $finish(0);
  end

  task static set_memory(input logic [15 : 0] data,
                         input logic [11 : 0] address,
                         input logic is_instruction);
    soc.mem.content[address] = data;

    if (is_instruction)
      $display("M[%h] = %h ; %s", address, data, disassemble(data));
    else if (data >= 32 && data <= 126)
      $display("M[%h] = %h ; '%c'", address, data, 8'(data & 16'hff));
    else $display("M[%h] = %h", address, data);
  endtask

  `ASM_DEFINE_PROGRAM_INCLUDE("program.asm.sv")

  VirtualClock vc (.clock_out(clock));

  VirtualKeyboard vk (
      .data_out(data_in),
      .load_out(load),
      .fgi_in  (fgi),
      .clock
  );

  VirtualPrinter vp (
      .clear_out(clear),
      .data_in(data_out),
      .fgo_in(fgo),
      .clock
  );
endmodule
