/* eslint-disable camelcase */
import * as nearley from '@esdmr/nearley';

/**
 * @param {string} name
 * @param {string} char
 * @returns {nearley.lexer.Rules}
 */
const stringLike = (name, char) => ({
	surrogate: {match: /\p{Surrogate}+/u, error: true},
	[name]: {match: char, pop: 1},
	escaped_double_quote: '\\"',
	escaped_single_quote: "\\'",
	escaped_backtick: '\\`',
	escaped_backslash: '\\\\',
	escaped_horizontal_tab: '\\t',
	escaped_carriage_return: '\\r',
	escaped_line_feed: '\\n',
	escaped_unicode: /\\u\{[\da-fA-F](?:_?[\da-fA-F])*\}/u,
	character: {
		match: new RegExp(String.raw`[^\\\p{Surrogate}${char}]+`, 'u'),
		lineBreaks: true,
	},
});

export const lexer = nearley.lexer.states({
	main: {
		surrogate: {match: /\p{Surrogate}+/u, error: true},

		line_comment: {
			match: /(?:\/\/|#)[^\n\p{Surrogate}]*(?:\n|$)/u,
			lineBreaks: true,
		},
		block_comment: {
			match: /\/\*[^*\p{Surrogate}]*(?:\*+[^/*\p{Surrogate}]+)*\*+\//u,
			lineBreaks: true,
		},
		whitespace: {match: /[ \t\r\n]+/u, lineBreaks: true},

		double_quote: {match: '"', push: 'string'},
		single_quote: {match: "'", push: 'character'},

		identifier: {
			match: /[a-zA-Z_][a-zA-Z0-9_]*/u,
			type: nearley.lexer.keywords({
				keyword_asm: 'asm',
				keyword_break: 'break',
				keyword_case: 'case',
				keyword_const: 'const',
				keyword_continue: 'continue',
				keyword_default: 'default',
				keyword_do: 'do',
				keyword_else: 'else',
				keyword_false: 'false',
				keyword_for: 'for',
				keyword_goto: 'goto',
				keyword_if: 'if',
				keyword_inline: 'inline',
				keyword_return: 'return',
				keyword_sizeof: 'sizeof',
				keyword_static: 'static',
				keyword_struct: 'struct',
				keyword_switch: 'switch',
				keyword_true: 'true',
				keyword_while: 'while',
			}),
		},

		keyword_start: /\$start\b/u,
		keyword_isr: /\$isr\b/u,
		keyword_input: /\$input\b/u,
		keyword_output: /\$output\b/u,
		keyword_post: /\$post\b/u,
		keyword_fgi: /\$fgi\b/u,
		keyword_fgo: /\$fgo\b/u,
		keyword_ien: /\$ien\b/u,

		hexadecimal: /[-+]?0[xX][\da-fA-F](?:_?[\da-fA-F])*(?:[eE]\d(?:_?\d)*)?/u,
		binary: /[-+]?0[bB][01](?:_?[01])*(?:[eE]\d(?:_?\d)*)?/u,
		octal: /[-+]?0[oO][0-7](?:_?[0-7])*(?:[eE]\d(?:_?\d)*)?/u,
		decimal: /[-+]?\d(?:_?\d)*(?:[eE]\d(?:_?\d)*)?/u,

		decrement: /[-][-]/u,
		assign_minus: /[-]=/u,
		minus: /[-]/u,

		assign_arithmetic_shift_right: '>>>=',
		arithmetic_shift_right: '>>>',
		assign_shift_left: '<<=',
		assign_shift_right: '>>=',
		assign_and: '&=',
		assign_or: '|=',
		assign_plus: '+=',
		assign_xor: '^=',
		bool_and: '&&',
		bool_or: '||',
		bool_xor: '^^',
		equals: '==',
		greater_or_equals: '>=',
		increment: '++',
		less_or_equals: '<=',
		not_equals: '!=',
		shift_left: '<<',
		shift_right: '>>',
		ampersand: '&',
		assign: '=',
		bool_not: '!',
		colon: ':',
		comma: ',',
		complement: '~',
		dereference: '*',
		dot: '.',
		greater_than: '>',
		left_brace: '{',
		left_bracket: '[',
		left_paren: '(',
		less_than: '<',
		plus: '+',
		question: '?',
		right_brace: '}',
		right_bracket: ']',
		right_paren: ')',
		semicolon: ';',
	},
	string: stringLike('double_quote', '"'),
	character: stringLike('single_quote', "'"),
});
