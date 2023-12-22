`ifndef _MODULE_PREAMBLE_

`include "../src/preamble.sv"

`undef IMPORT
/**
 * Redirect all `IMPORT` calls to `src`.
 */
`define IMPORT(__MODULE_NAME__) \
  `IMPORTX(__MODULE_NAME__,`"../src/``__MODULE_NAME__``.sv`")

`timescale 1s / 1ms

/**
 * Start the list of test cases. The code following this will be inside a
 * `initial` block.
 */
`define TAP_BEGIN             \
  var int __tap_test_count__; \
  initial begin               \
  $display("TAP version 13"); \
  __tap_test_count__ = 0;

/**
 * End the list of test cases. The code following this will be outside the
 * `initial` block.
 */
`define TAP_END                           \
  $display("1..%0d", __tap_test_count__); \
  $finish(0);                             \
  end

/**
 * Run the given statement(s). This macro is included to assist the linter in
 * parsing the file, as it may not recognize that we are in an initial block.
 * Any program that respects macros will remain unaffected.
 *
 * @param __TAP_STMT__ - statement(s). Should be valid under an `initial` block.
 */
`define TAP_INIT(__TAP_STMT__) __TAP_STMT__

/**
 * Something has gone really wrong. This will exit the testbench early.
 *
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_BAIL_OUT(__TAP_DESC__)                                       \
  $display("Bail out! %s (%s:%0d)", __TAP_DESC__, `__FILE__, `__LINE__); \
  $finish;

/**
 * A passing test. This would normally be wrapped in an `if` or `case`
 * statement.
 *
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_OK(
    __TAP_DESC__)       \
  __tap_test_count__++; \
  $display("ok %0d - %s (%s:%0d)", __tap_test_count__, (__TAP_DESC__), `__FILE__, `__LINE__);

/**
 * A failing test. This would normally be wrapped in an `if` or `case`
 * statement.
 *
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_NOT_OK(
    __TAP_DESC__)       \
  __tap_test_count__++; \
  $display("not ok %0d - %s (%s:%0d)", __tap_test_count__, (__TAP_DESC__), `__FILE__, `__LINE__);

/**
 * A test which asserts the given condition.
 *
 * @param __TAP_IF__ - condition. Should be a 1 bit integer expression.
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_TEST(__TAP_IF__, __TAP_DESC__) \
  if (__TAP_IF__) begin                    \
    `TAP_OK(__TAP_DESC__)                  \
  end else begin                           \
    `TAP_NOT_OK(__TAP_DESC__)              \
  end

/**
 * Setup the input and output variables, available at `tap_in` and `tap_out`.
 *
 * @param __TAP_INPUTS__ - number of input bits. Should be an integer expression.
 * @param __TAP_OUTPUTS__ - number of output bits. Should be an integer expression.
 */
`define TAP_IO(__TAP_INPUTS__, __TAP_OUTPUTS__) \
  var logic [(__TAP_OUTPUTS__)-1:0] tap_out;    \
  var logic [(__TAP_INPUTS__)-1:0] tap_in;

/**
 * Setup the clock, available at `tap_clock`, with the given module.
 *
 * @param __TAP_MOD__ - name of the module. Should be a valid identifier.
 */
`define TAP_CLOCK(__TAP_MOD__) \
  var logic tap_clock;         \
  __TAP_MOD__ __tap_clock__(.clock_out(tap_clock));

/**
 * Format the description of `TAP_CASE` test cases.
 *
 * @param __TAP_OUTPUTS__ - expected output. Should be an integer expression.
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define _TAP_FORMAT_DESC_(__TAP_OUTPUTS__,
                          __TAP_DESC__) \
  $sformatf("%s [expected: %h, actual: %h]", (__TAP_DESC__), (__TAP_OUTPUTS__), tap_out)

/**
 * A test which asserts the given condition with the given inputs.
 *
 * @param __TAP_INPUTS__ - given inputs. Should be an integer expression.
 * @param __TAP_OUTPUTS__ - expected output. Should be an integer expression.
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_CASE(__TAP_INPUTS__, __TAP_OUTPUTS__,
                 __TAP_DESC__) \
  tap_in = (__TAP_INPUTS__);   \
  #1 `TAP_TEST(tap_out === (__TAP_OUTPUTS__), `_TAP_FORMAT_DESC_(__TAP_OUTPUTS__, __TAP_DESC__))

/**
 * A test which asserts the given condition with the given inputs at the given
 * clock edge.
 *
 * @param __TAP_INPUTS__ - given inputs. Should be an integer expression.
 * @param __TAP_AT__ - clock edge. Should be a valid clock edge.
 * @param __TAP_OUTPUTS__ - expected output. Should be an integer expression.
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_CASE_AT(__TAP_INPUTS__, __TAP_AT__, __TAP_OUTPUTS__,
                    __TAP_DESC__) \
  tap_in = __TAP_INPUTS__;        \
  @(__TAP_AT__);                  \
  `TAP_TEST(tap_out === __TAP_OUTPUTS__, `_TAP_FORMAT_DESC_(__TAP_OUTPUTS__, __TAP_DESC__))

/**
 * A test which asserts the given condition with the given inputs at the next
 * negative clock edge.
 *
 * @param __TAP_INPUTS__ - given inputs. Should be an integer expression.
 * @param __TAP_OUTPUTS__ - expected output. Should be an integer expression.
 * @param __TAP_DESC__ - description. Should be a string expression.
 */
`define TAP_CASE_AT_NEGEDGE(__TAP_INPUTS__, __TAP_OUTPUTS__, __TAP_DESC__) \
  `TAP_CASE_AT(__TAP_INPUTS__, negedge tap_clock, __TAP_OUTPUTS__, __TAP_DESC__)

`endif
