# Mano Machine implementation in SystemVerilog

My project for the *Computer Architecture* class. Implements the [Mano machine](https://en.wikipedia.org/wiki/Mano_machine). Includes synthesizable modules
for the non-IO components, an assembler via macros, and an executable module for
simulation.

## Requirements

To run the simulator along with the preloaded assembly program, you will need
the following tools:

- [Python](https://www.python.org/) v3.12 or later
- [Icarus Verilog](https://steveicarus.github.io/iverilog/) v12.0 or later

To run everything else you will need the following tools too:

- [Node.JS](https://nodejs.org/) v18 or later
- [`tap-mocha-reporter`](https://www.npmjs.com/package/tap-mocha-reporter)
- C compiler such as [GCC](https://gcc.gnu.org/) to be used via `iverilog-vpi`
- Make, preferably [GNU Make](https://www.gnu.org/software/make/)
- [Verible](https://chipsalliance.github.io/verible/) `v0.0-3428-gcfcbb82b` or later
- [Verilator](https://verilator.org/) `v5.019` or later
- Either:
  - Option A (recommended):
    - Standalone DigitalJS server, preferably my fork (TODO)
    - [Yosys](https://yosyshq.net/yosys/) `v0.35` or later
    - [cURL](https://curl.se/)
    - [`xdg-open`](http://portland.freedesktop.org/doc/xdg-open.html)
  - Option B:
    - [VS Code](https://code.visualstudio.com/)
    - [DigitalJS extension](https://marketplace.visualstudio.com/items?itemName=yuyichao.digitaljs)

## Usage

- Prepare the VPI modules:
  `./sv.py make`.
- Simulate preloaded with the assembly program in
  `src/program.asm.sv`:
  `./sv.py run src/VirtualComputer.sv`.
- Synthesize to logic gates:
  `./sv.py synthesize --online http://localhost:15555 src/SOC.sv` or
  `./sv.py synthesize --vscode src/SOC.sv`.
- Translate to VHDL (not tested):
  `./sv.py compile src/SOC.sv --type vhdl --out SOC.vhdl`.
- Synthesize to FPGA (not tested):
  `./sv.py compile src/SOC.sv --type fpga --out SOC.fpga`.
- Run linter:
  `./sv.py lint`.
- Run tests:
  `./sv.py test`.
- Run formatter:
  `./sv.py format`.

## Project structure

- `src`
  - `Virtual*.sv`: non-synthesizable modules
  - `/[a-z].*\.sv/`: non-module source files
  - Anything else: synthesizable modules
- `test`
  - `/[a-z].*\.sv/`: utility files
  - Anything else: testbench modules
- `vpi`
  - `*.c`: VPI source files for `iverilog`
  - `Makefile`: configuration for Make
- `sv.py`: Script which wraps almost any command that you will run
- `extended_instructions.py`: Script which generates new (and dare I say mostly
  useless) instructions for the current CPU architecture.

## The preamble

The files `src/preamble.sv` and `test/preamble.sv` contain macros which will be
loaded at the top of every file.

An important macro from the preamble is `IMPORT`. Instead of wrapping each
module in `ifndef`-`define`, we will wrap the `include` which will import that
module. As long as no module is circularly importing itself, it is a more
elegant solution to importing a file only once and in order.

In `test/preamble.sv`, the `IMPORT` macro will be redirected to the `src`
directory, so `IMPORT(RAM)` imports `src/RAM.sv` and not `test/RAM.sv`.
Additionally, `test/preamble.sv` includes some macros to assist running
testbenches.

## The assembler

We use SystemVerilog macros to implement the assembler. In a module which will
accept the assembler, you should implement the `_ASM_SET_MEMORY_` macro which
will be called with the bytes from the assembled program.

Inside the module body you will use the `ASM_DEFINE_PROGRAM` macro and pass the
program as its argument. For multiline programs I recommend moving the content
of the argument into a macro. For very long programs I recommend using `include`
and the `.asm.sv` suffix. (The formatter correctly indents the instructions with
this suffix.)

Non-memory-reference instructions are available as `ASM_<name>`.
Memory-reference instructions are available as
`ASM_<name>_<mode><operand_type>`. See [`assembler.sv`](src/assembler.sv) for
more information.

Labels can be created via `ASM_LABEL`. Some labels can be marked private, e.g.,
subroutine branches and variables. These can be defined via `ASM_SUBLABEL` and
are only accessible between two `ASM_LABEL`s (or the end of the program).

You can set the assembler address via `ASM_ADDR` and `ASM_ADDR_REL`.

You can set raw data via `ASM_DATA`. If the data is the address of a label, you
can use `ASM_DATA_LABEL` and `ASM_DATA_SUBLABEL`. If the data is a string, you
can use `ASM_DATA_STR`. (It will not append a null character). Finally, you can
use `ASM_DATA_FILL` to initialize a span in the memory.

There are some shortcuts available, such as `ASM_SUBROUTINE`, `ASM_CALL`,
`ASM_RETURN`, `ASM_ARG_SKIP`, `ASM_ARG_NEXT`, `ASM_SHR`, `ASM_SHL`, and
`ASM_ASR`.  See [`assembler.sv`](src/assembler.sv) for more information.

Finally, there is the `disassemble` task which will decode an instruction.

## The test library

There is an implementation of a [Test Anything Protocol
(TAP)](https://testanything.org/) producer inside `test/preamble.sv`. For every
test case, it will output a `ok` or `not ok` line to the stdout which will be
picked up by a tap consumer.

There is a test runner implemented in python in `sv.py`. You can use the `test`
sub-command to run some or all testbenches. If you are running this command via
a TTY and have `tap-mocha-reporter` installed, the output will be passed into
it.

For asynchronous modules, you can use `TAP_TEST` and `TAP_CASE`. For synchronous
modules, you can also use `TAP_CASE_AT` and `TAP_CASE_AT_NEGEDGE`.

See [`test/preamble.sv`](test/preamble.sv) for more information.

## The VPI module for IO

While SystemVerilog has a `$fgetc`, the stdin is line-buffered and so it cannot
be used for the keyboard module. Additionally, `$fgetc` blocks the process
waiting for user input.

To replace `$fgetc`, We will implement the necessary logic in C and load the
`$read_char` function into the `iverilog` simulation. This is implemented inside
`vpi/io.c`. It supports both Windows (untested) and Linux. If you would like to
avoid using this module for some reason, you can pass the `--no-vpi` option to
the `./sv.py run` command.

## The CKL programming language

Pronounced like “sickle”, it is a C-like programming language specifically for
the Mano Machine. It is currently a work in progress. It also does not do many
optimizations, mostly those that the user cannot do without resorting to inline
assembly.

```c
// Top-level variable declaration
a;
// Top-level variable declaration with initializer
b = 123;

// Forward declaration
add(a, b);

// Function declaration
add(a, b) {
  // Last expression is returned automatically.
  a + b;
}

// Special function declarations
$start() { /* … */ }
$isr()   { /* … */ }

io() {
  // Asynchronous input
  a = $input;
  // Synchronous input
  a = $input();

  // Asynchronous input
  $output = a;
  // Synchronous input
  $output(a)

  // I/O flags
  do; while (!$fgo);
  do; while (!$fgi);

  // IEN flag
  $ien = 1;
  $ien = 0;

  // Address of the word immediately after the assembly program.
  string = $post;

  // Inline assembly
  asm("`ASM_ISZ_DL(%s)", a);
}

// Also inline assembly
asm("`ASM_ADDR_REL(2)");
```
