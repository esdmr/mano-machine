/**
 * Abstract interface to set the memory.
 *
 * @param __ASM_DATA__ - data to be set to memory. Will be a 16 bit integer
 * expression.
 * @param __ASM_ADDR__ - address of memory. Will be a 12 bit integer expression.
 * @param __ASM_INST__ - whether if the current address is an instruction. Will
 * be a 1 bit integer expression.
 */
`define _ASM_SET_MEMORY_(__ASM_DATA__, __ASM_ADDR__, __ASM_INST__) \
  $fatal("_ASM_SET_MEMORY_ is not implemented");

/**
 * Abstract interface to probe into the memory.
 *
 * @param __ASM_TARGET__ - name of the probe. Will be a valid identifier.
 * @param __ASM_ADDR__ - address of memory. Will be a 12 bit integer expression.
 */
`define _ASM_PROBE_MEMORY_(__ASM_TARGET__, __ASM_ADDR__) \
  initial $fatal("_ASM_SET_MEMORY_ is not implemented");

/**
 * Generate a variable name from label name.
 *
 * @param __ASM_NAME__ - name of label. It should be a valid identifier.
 */
`define ASM_REF_LABEL(__ASM_NAME__) __asm__``__ASM_NAME__``__

/**
 * Generate a variable name from label and sublabel name.
 *
 * @param __ASM_NAME__ - name of sublabel. It should be a valid identifier.
 */
`define ASM_REF_SUBLABEL(__ASM_NAME__) \
  __asm__`_ASM_LAST_LABEL_``__``__ASM_NAME__``__

/**
 * Read the content of a label for use in $monitor and such. The probe will be
 * available at `asm__<name>`.
 *
 * @param __ASM_NAME__ - name of label. It should be a valid identifier.
 */
`define ASM_PROBE_LABEL(__ASM_NAME__)     \
  var logic [15 : 0] asm__``__ASM_NAME__; \
  `_ASM_PROBE_MEMORY_(asm__``__ASM_NAME__, `ASM_REF_LABEL(__ASM_NAME__))

/**
 * Read the content of a sublabel for use in $monitor and such. The probe will
 * be available at `asm__<name of label>__<name of sublabel>`.
 *
 * @param __ASM_SUP__ - name of label. It should be a valid identifier.
 * @param __ASM_NAME__ - name of sublabel. It should be a valid identifier.
 */
`define ASM_PROBE_SUBLABEL(__ASM_SUP__, __ASM_NAME__) \
  `ASM_PROBE_LABEL(__ASM_SUP__``__``__ASM_NAME__)

/**
 * Generate initialization code to setup given assembly program.
 *
 * @param __ASM_MACRO__ - assembly program to run. It should be a macro token.
 * It will be expanded multiple times in different contexts. Inside it, a few
 * macros are defined which can be tested inside `ifdef-`elsif-`endif:
 *
 * - `_ASM_PROGRAM_`: Defined inside `ASM_DEFINE_PROGRAM`.
 * - `_ASM_DECL_`: Defined outside `initial` block.
 * - `_ASM_INIT_`: Defined inside `initial` block.
 * - `_ASM_LABEL_`: Defined in step 2 only.
 * - `_ASM_DATA_`: Defined in step 3 only.
 */
`define ASM_DEFINE_PROGRAM(__ASM_MACRO__)            \
  /* Setup */                                        \
  var logic [11 : 0] __asm_addr__ = '0;              \
                                                     \
  /* Step 1. Define all labels as variables */       \
  `define _ASM_PROGRAM_                              \
  `define _ASM_DECL_                                 \
  __ASM_MACRO__                                      \
  `undef _ASM_DECL_                                  \
                                                     \
  initial begin                                      \
    /* Step 2. Initialize label variables */         \
    `define _ASM_INIT_                               \
    `define _ASM_LABEL_                              \
    __ASM_MACRO__                                    \
    `undef _ASM_LABEL_                               \
                                                     \
    /* Step 3. Initialize memory (may use labels) */ \
    __asm_addr__ = '0;                               \
    `define _ASM_DATA_                               \
    __ASM_MACRO__                                    \
    `undef _ASM_DATA_                                \
    `undef _ASM_INIT_                                \
    `undef _ASM_PROGRAM_                             \
  end

/**
 * Generate initialization code to setup given assembly program included from a
 * file.
 *
 * @param __ASM_MACRO__ - file containing assembly program to run. See above.
 */
`define ASM_DEFINE_PROGRAM_INCLUDE(__ASM_FILE__) \
  `ASM_DEFINE_PROGRAM(`include __ASM_FILE__)

/**
 * Jump to the given address.
 *
 * @param __ASM_ADDR__ - address. It should be an 11 bit integer expression.
 */
`define ASM_ADDR(__ASM_ADDR__)     \
  `ifdef _ASM_INIT_                \
    __asm_addr__ = (__ASM_ADDR__); \
  `endif

/**
 * Jump to the given offset relative to the current address.
 *
 * @param __ASM_OFF__ - offset. It should be an 11 bit integer expression.
 */
`define ASM_ADDR_REL(__ASM_OFF__)  \
  `ifdef _ASM_INIT_                \
    __asm_addr__ += (__ASM_OFF__); \
  `endif

/**
 * Set the memory at the current address with the given value and step forward.
 *
 * @param __ASM_VALUE__ - value. It should be a 16 bit integer expression.
 * @param [__ASM_INST__] - is the value an instruction. It should be a 1 bit
 * integer expression.
 */
`define ASM_DATA(__ASM_VALUE__, __ASM_INST__ = 0)                  \
  `ifdef _ASM_DATA_                                                \
    `_ASM_SET_MEMORY_(__ASM_VALUE__, __asm_addr__++, __ASM_INST__) \
  `elsif _ASM_INIT_                                                \
    __asm_addr__++;                                                \
  `endif

/**
 * Set the memory at the current address with the address of the given label and
 * step forward.
 *
 * @param __ASM_NAME__ - name of label. It should be a valid identifier.
 */
`define ASM_DATA_LABEL(__ASM_NAME__) \
  `ASM_DATA(16'(`ASM_REF_LABEL(__ASM_NAME__)))

/**
 * Set the memory at the current address with the address of the given sublabel
 * and step forward.
 *
 * @param __ASM_NAME__ - name of sublabel. It should be a valid identifier.
 */
`define ASM_DATA_SUBLABEL(__ASM_NAME__) \
  `ASM_DATA(16'(`ASM_REF_SUBLABEL(__ASM_NAME__)))

/**
 * Fills the memory from the current address onwards with a certain value.
 *
 * @param __ASM_VALUE__ - value. It should be a 16 bit integer expression.
 * @param __ASM_LEN__ - length. It should be an integer expression.
 */
`define ASM_DATA_FILL(__ASM_VALUE__, __ASM_LEN__)                   \
  `ifdef _ASM_DATA_                                                 \
    for (int i = 0; i < __ASM_LEN__; i++)                           \
    `_ASM_SET_MEMORY_({8'b0, __asm_string__[i]}, __asm_addr__++, 0) \
  `elsif _ASM_INIT_                                                 \
    __asm_addr__ += 12'(__ASM_LEN__ & 'hfff);                       \
  `endif

/**
 * Set the memory at the current address with the given string and step forward.
 *
 * @param __ASM_STR__ - value. It should be a string expression.
 */
`define ASM_DATA_STR(__ASM_STR__)                                   \
  `ifdef _ASM_DATA_                                                 \
    __asm_string__ = (__ASM_STR__);                                 \
    for (int i = 0; i < __asm_string__.len(); i++)                  \
    `_ASM_SET_MEMORY_({8'b0, __asm_string__[i]}, __asm_addr__++, 0) \
  `elsif _ASM_INIT_                                                 \
    `undef _ASM_STR_DECL_                                           \
    __asm_string__ = (__ASM_STR__);                                 \
    __asm_addr__ += 12'(__asm_string__.len() & 'hfff);              \
  `elsif _ASM_DECL_                                                 \
    `ifndef _ASM_STR_DECL_                                          \
      `define _ASM_STR_DECL_                                        \
      var string __asm_string__;                                    \
    `endif                                                          \
  `endif

/**
 * Define a new label with the given name.
 *
 * @param __ASM_NAME__ - name of label. It should be a valid identifier.
 */
`define ASM_LABEL(__ASM_NAME__)                      \
  `undef _ASM_LAST_LABEL_                            \
  `define _ASM_LAST_LABEL_ __ASM_NAME__              \
  `ifdef _ASM_DECL_                                  \
    var logic [11 : 0] `ASM_REF_LABEL(__ASM_NAME__); \
  `elsif _ASM_LABEL_                                 \
    `ASM_REF_LABEL(__ASM_NAME__) = __asm_addr__;     \
  `endif

/**
 * Define a new sublabel with the given name.
 *
 * @param __ASM_NAME__ - name of sublabel. It should be a valid identifier.
 */
`define ASM_SUBLABEL(__ASM_NAME__)                      \
  `ifdef _ASM_DECL_                                     \
    var logic [11 : 0] `ASM_REF_SUBLABEL(__ASM_NAME__); \
  `elsif _ASM_LABEL_                                    \
    `ASM_REF_SUBLABEL(__ASM_NAME__) = __asm_addr__;     \
  `endif

/**
 * Define a register instruction with given name and index. The resulting
 * expression would have an opcode of 7, an addressing mode of 0, and an operand
 * of (1 << index). The macro `ASM_<name>` would insert this instruction at the
 * current address.
 *
 * @param __ASM_NAME__ - name of instruction. It should be a valid identifier.
 * @param __ASM_IDX__ - index. It should be an integer expression between 0 and
 * 11.
 */
`define ASM_REG_INSTR(__ASM_NAME__, __ASM_IDX__) \
  `define ASM_``__ASM_NAME__                   \ \
    `ASM_DATA({4'o07, 12'(1 << (__ASM_IDX__))}, 1)

/**
 * Define a I/O instruction with given name and index. The resulting expression
 * would have an opcode of 7, an addressing mode of 1, and an operand of (1 <<
 * index). The macro `ASM_<name>` would insert this instruction at the current
 * address.
 *
 * @param __ASM_NAME__ - name of instruction. It should be a valid identifier.
 * @param __ASM_IDX__ - index. It should be an integer expression between 0 and
 * 11.
 */
`define ASM_IO_INSTR(__ASM_NAME__, __ASM_IDX__) \
  `define ASM_``__ASM_NAME__                  \ \
    `ASM_DATA({4'o17, 12'(1 << (__ASM_IDX__))}, 1)

/**
 * Define a memory instruction with given name and opcode. The macros
 * `ASM_<name>_<D/I><A/L/S>(operand)` (Direct or Indirect, address or Label or
 * sublabel) would insert this instruction at the current address.
 *
 * @param __ASM_NAME__ - name of instruction. It should be a valid identifier.
 * @param __ASM_OPC__ - opcode. It should be an integer expression between 0 and
 * 7.
 */
`define ASM_MEM_INSTR(__ASM_NAME__, __ASM_OPC__)                           \
  `define ASM_``__ASM_NAME__``_DA(__ASM_OPR__)                           \ \
    `ASM_DATA({1'b0, 3'(__ASM_OPC__), 12'(__ASM_OPR__)}, 1)                \
  `define ASM_``__ASM_NAME__``_IA(__ASM_OPR__)                           \ \
    `ASM_DATA({1'b1, 3'(__ASM_OPC__), 12'(__ASM_OPR__)}, 1)                \
  `define ASM_``__ASM_NAME__``_DL(__ASM_NAME__ = `_ASM_LAST_LABEL_)      \ \
    `ASM_DATA({1'b0, 3'(__ASM_OPC__), `ASM_REF_LABEL(__ASM_NAME__)}, 1)    \
  `define ASM_``__ASM_NAME__``_IL(__ASM_NAME__ = `_ASM_LAST_LABEL_)      \ \
    `ASM_DATA({1'b1, 3'(__ASM_OPC__), `ASM_REF_LABEL(__ASM_NAME__)}, 1)    \
  `define ASM_``__ASM_NAME__``_DS(__ASM_NAME__)                          \ \
    `ASM_DATA({1'b0, 3'(__ASM_OPC__), `ASM_REF_SUBLABEL(__ASM_NAME__)}, 1) \
  `define ASM_``__ASM_NAME__``_IS(__ASM_NAME__)                          \ \
    `ASM_DATA({1'b1, 3'(__ASM_OPC__), `ASM_REF_SUBLABEL(__ASM_NAME__)}, 1)

// Memory-reference
`ASM_MEM_INSTR(AND, 0)
`ASM_MEM_INSTR(ADD, 1)
`ASM_MEM_INSTR(LDA, 2)
`ASM_MEM_INSTR(STA, 3)
`ASM_MEM_INSTR(BUN, 4)
`ASM_MEM_INSTR(BSA, 5)
`ASM_MEM_INSTR(ISZ, 6)

// Register-reference
`ASM_REG_INSTR(CLA, 11)
`ASM_REG_INSTR(CLE, 10)
`ASM_REG_INSTR(CMA, 9)
`ASM_REG_INSTR(CME, 8)
`ASM_REG_INSTR(CIR, 7)
`ASM_REG_INSTR(CIL, 6)
`ASM_REG_INSTR(INC, 5)
`ASM_REG_INSTR(SPA, 4)
`ASM_REG_INSTR(SNA, 3)
`ASM_REG_INSTR(SZA, 2)
`ASM_REG_INSTR(SZE, 1)
`ASM_REG_INSTR(HLT, 0)

// Input-output
`ASM_IO_INSTR(INP, 11)
`ASM_IO_INSTR(OUT, 10)
`ASM_IO_INSTR(SKI, 9)
`ASM_IO_INSTR(SKO, 8)
`ASM_IO_INSTR(ION, 7)
`ASM_IO_INSTR(IOF, 6)

/**
 * Shorthand for defining a subroutine.
 *
 * @param __ASM_NAME__ - name of subroutine. It should be a valid identifier.
 */
`define ASM_SUBROUTINE(__ASM_NAME__) \
  `ASM_LABEL(__ASM_NAME__)           \
  `ASM_DATA(0)

/**
 * Shorthand for calling a subroutine.
 *
 * @param __ASM_NAME__ - name of subroutine. It should be a valid identifier.
 */
`define ASM_CALL(__ASM_NAME__) `ASM_BSA_DL(__ASM_NAME__)

/**
 * Shorthand for skipping over an argument.
 *
 * @param [__ASM_NAME__] - name of subroutine. It should be a valid identifier.
 * By default will return from the last defined label (subroutine).
 */
`define ASM_ARG_SKIP(__ASM_NAME__ = `_ASM_LAST_LABEL_) `ASM_ISZ_DL(__ASM_NAME__)

/**
 * Shorthand for copying and skipping over an argument.
 *
 * @param __ASM_DST__ - name of sublabel. It should be a valid identifier.
 * @param [__ASM_NAME__] - name of subroutine. It should be a valid identifier.
 * By default will return from the last defined label (subroutine).
 */
`define ASM_ARG_NEXT(__ASM_DST__, __ASM_NAME__ = `_ASM_LAST_LABEL_) \
  `ASM_LDA_IL(__ASM_NAME__)                                         \
  `ASM_STA_DS(__ASM_DST__)                                          \
  `ASM_ARG_SKIP(__ASM_NAME__)

/**
 * Shorthand for returning from a subroutine.
 *
 * @param [__ASM_NAME__] - name of subroutine. It should be a valid identifier.
 * By default will return from the last defined label (subroutine).
 */
`define ASM_RETURN(__ASM_NAME__ = `_ASM_LAST_LABEL_) `ASM_BUN_IL(__ASM_NAME__)

/**
 * Shorthand for logical right shift.
 */
`define ASM_SHR `ASM_CLE `ASM_CIR

/**
 * Shorthand for logical left shift.
 */
`define ASM_SHL `ASM_CLE `ASM_CIL

/**
 * Shorthand for arithmetic right shift.
 */
`define ASM_ASR `ASM_CLE `ASM_SPA `ASM_CME `ASM_CIR

/**
 * Decode an instruction into readable assembly.
 */
function static string disassemble(input logic [15:0] data);
  var string i;
  var logic mode;
  var logic [11:0] operand;

  mode = data[15];
  operand = data[11:0];

  casez (32'(data))
    'b?000????????????: $sformat(i, "AND %h %s", operand, mode ? "I" : "");
    'b?001????????????: $sformat(i, "ADD %h %s", operand, mode ? "I" : "");
    'b?010????????????: $sformat(i, "LDA %h %s", operand, mode ? "I" : "");
    'b?011????????????: $sformat(i, "STA %h %s", operand, mode ? "I" : "");
    'b?100????????????: $sformat(i, "BUN %h %s", operand, mode ? "I" : "");
    'b?101????????????: $sformat(i, "BSA %h %s", operand, mode ? "I" : "");
    'b?110????????????: $sformat(i, "ISZ %h %s", operand, mode ? "I" : "");
    'b0111100000000000: $sformat(i, "CLA      ");
    'b0111010000000000: $sformat(i, "CLE      ");
    'b0111001000000000: $sformat(i, "CMA      ");
    'b0111000100000000: $sformat(i, "CME      ");
    'b0111000010000000: $sformat(i, "CIR      ");
    'b0111000001000000: $sformat(i, "CIL      ");
    'b0111000000100000: $sformat(i, "INC      ");
    'b0111000000010000: $sformat(i, "SPA      ");
    'b0111000000001000: $sformat(i, "SNA      ");
    'b0111000000000100: $sformat(i, "SZA      ");
    'b0111000000000010: $sformat(i, "SZE      ");
    'b0111000000000001: $sformat(i, "HLT      ");
    'b1111100000000000: $sformat(i, "INP      ");
    'b1111010000000000: $sformat(i, "OUT      ");
    'b1111001000000000: $sformat(i, "SKI      ");
    'b1111000100000000: $sformat(i, "SKO      ");
    'b1111000010000000: $sformat(i, "ION      ");
    'b1111000001000000: $sformat(i, "IOF      ");
    default: $sformat(i, "UNK %b", data);
  endcase

  return i;
endfunction
