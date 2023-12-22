`ifndef _MODULE_PREAMBLE_
`define _MODULE_PREAMBLE_

`default_nettype none

/**
 * Import a module once.
 *
 * @param __MODULE_NAME__ - symbolic name of the module. Should be a valid
 * identifier.
 * @param __MODULE_PATH__ - path to the module. Should be a string literal.
 */
`define IMPORTX(__MODULE_NAME__, __MODULE_PATH__) \
  `ifndef _MODULE_``__MODULE_NAME__``_            \
  `define _MODULE_``__MODULE_NAME__``_            \
  `include __MODULE_PATH__                        \
  `endif

/**
 * Shorthand for importing a module with the same name as the filename.
 *
 * @param __MODULE_NAME__ - name of the module. Should be a valid identifier.
 * Should be the same as the filename, excluding the extension.
 */
`define IMPORT(__MODULE_NAME__) \
  `IMPORTX(__MODULE_NAME__,`"__MODULE_NAME__``.sv`")

`endif
