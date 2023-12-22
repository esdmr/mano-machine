`include "preamble.sv"

/**
 * Instruction format used by the ControlUnit.
 */
typedef struct packed {
  logic mode;
  logic [2:0] opcode;
  logic [11:0] operand;
} instruction_t;
