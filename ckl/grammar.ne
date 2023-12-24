@{%
	import {lexer} from './lexer.js';
	import {id} from '@esdmr/nearley';
	import * as ast from './ast.js';
%}
@lexer lexer

program -> _ top_level_list _ {% ([, d]) => d %}

top_level_list -> null {% () => ast.Node.concat() %}
top_level_list -> top_level (
	_ top_level {% ([, d]) => d %}
):* {% ([a, b]) => ast.Node.concat(a, b) %}

top_level -> %identifier _ %left_paren _ param_list _ %right_paren _ %semicolon {% ([id,, _lparen,, params,, _rparen], ref) => new ast.Node(ref, ast.declarationFunction, id.value, params) %}
top_level -> %identifier _ %left_paren _ param_list _ %right_paren _ stmt_block {% ([id,, _lparen,, params,, _rparen,, body], ref) => new ast.Node(ref, ast.declarationFunction, id.value, params, body) %}
top_level -> id _ %semicolon {% ([id], ref) => new ast.Node(ref, ast.declarationVariable, id) %}
top_level -> id _ %assign _ exp_assignment _ %semicolon {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.declarationVariable, a, b) %}

top_level -> raw_assembly %semicolon {% id %}

top_level -> special_function_declaration_id _ %left_paren _ %right_paren _ %semicolon {% ([id,, _lparen,, _rparen], ref) => new ast.Node(ref, ast.declarationFunction, id.value, ast.Node.concat()) %}

top_level -> special_function_declaration_id _ %left_paren _ %right_paren _ stmt_block {% ([id,, _lparen,, _rparen,, body], ref) => new ast.Node(ref, ast.declarationFunction, id.value, ast.Node.concat(), body) %}

special_function_declaration_id -> %keyword_start {% id %}
special_function_declaration_id -> %keyword_isr {% id %}

id -> %identifier {% ([id], ref) => new ast.Node(ref, ast.identifier, id.value) %}
id -> %identifier _ %left_bracket _ exp_literal_int _ %right_bracket {% ([id,, _lbracket,, size,, _rbracket], ref) => new ast.Node(ref, ast.identifier, id.value, ...size.args) %}

param_list -> null {% ([]) => ast.Node.concat() %}
param_list -> id (
	_ %comma _ id {% ([, _comma,, d]) => d %}
):* {% ([a, b]) => ast.Node.concat(a, b) %}

stmt -> %keyword_if _ %left_paren _ exp _ %right_paren _ stmt (
	_ %keyword_else _ stmt {% ([, _else,, s]) => s %}
):? {% ([_if,, _lparen,, cond,, _rparen,, then, _else], ref) => new ast.Node(ref, ast.statementIf, cond, then, _else) %}

stmt -> %keyword_while _ %left_paren _ exp _ %right_paren _ stmt {% ([_while,, _lparen,, cond,, _rparen,, body], ref) => new ast.Node(ref, ast.statementWhile, cond, body) %}

stmt -> %keyword_return _ %semicolon {% ([_return], ref) => new ast.Node(ref, ast.statementReturn) %}

stmt -> %keyword_return _ exp _ %semicolon {% ([_return,, e], ref) => new ast.Node(ref, ast.statementReturn, e) %}

stmt -> %keyword_break _ %semicolon {% ([_break], ref) => new ast.Node(ref, ast.statementBreak) %}

stmt -> %keyword_continue _ %semicolon {% ([_continue], ref) => new ast.Node(ref, ast.statementContinue) %}

stmt -> %keyword_for _ %left_paren _ exp:? _ %semicolon _ exp:? _ %semicolon _ exp:? _ %right_paren _ stmt {% ([_for,, _lparen,, init,, _semicolon1,, cond,, _semicolon2,, step,, _rparen,, body], ref) => new ast.Node(ref, ast.statementFor, init, cond, step, body) %}

stmt -> %keyword_switch _ %left_paren _ exp _ %right_paren _ %left_brace _ stmt_list _ %right_brace {% ([_switch,, _lparen,, e,, _rparen,, _lbrace,, stmts,, _rbrace], ref) => new ast.Node(ref, ast.statementSwitch, e, stmts) %}

stmt -> %keyword_do _ stmt _ %keyword_while _ %left_paren _ exp _ %right_paren _ %semicolon {% ([_do,, body,, _while,, _lparen,, cond,, _rparen,, _semicolon], ref) => new ast.Node(ref, ast.statementDo, body, cond) %}

stmt_block -> %left_brace _ stmt_list _ %right_brace {% ([_lbrace,, stmts,, _rbrace]) => stmts %}
stmt -> stmt_block {% id %}

stmt -> exp _ %semicolon {% ([e], ref) => new ast.Node(ref, ast.statementExpression, e) %}

stmt -> %semicolon {% ([], ref) => new ast.Node(ref, ast.statementVoid) %}

stmt_list -> null {% () => ast.Node.concat() %}
stmt_list -> stmt (
	_ stmt {% ([, d]) => d %}
):* {% ([a, b]) => ast.Node.concat(a, b) %}

#
# Okay, okay. I know what you are thinking. Why the bloody hell am I using eval?
# That is an *excellent* question… left as an exercise for the reader.
#
exp_literal_int -> %hexadecimal {% ([i], ref) => new ast.Node(ref, ast.literal, (0, eval)(i.value)) %}
exp_literal_int -> %binary {% ([i], ref) => new ast.Node(ref, ast.literal, (0, eval)(i.value)) %}
exp_literal_int -> %octal {% ([i], ref) => new ast.Node(ref, ast.literal, (0, eval)(i.value)) %}
exp_literal_int -> %decimal {% ([i], ref) => new ast.Node(ref, ast.literal, (0, eval)(i.value)) %}

exp_literal_bool -> %keyword_false {% ([], ref) => new ast.Node(ref, ast.literal, 0) %}
exp_literal_bool -> %keyword_true {% ([], ref) => new ast.Node(ref, ast.literal, -1) %}

exp_literal_str -> %double_quote char:* %double_quote {% ([, ch], ref) => new ast.Node(ref, ast.literal, ch.join('')) %}
exp_literal_char -> %single_quote char %single_quote {% ([, ch], ref) => new ast.Node(ref, ast.literal, ch) %}

char -> %escaped_double_quote {% () => '"' %}
char -> %escaped_single_quote {% () => '\'' %}
char -> %escaped_backtick {% () => '`' %}
char -> %escaped_backslash {% () => '\\' %}
char -> %escaped_horizontal_tab {% () => '\t' %}
char -> %escaped_carriage_return {% () => '\r' %}
char -> %character {% ([ch]) => ch.value %}
char -> %escaped_unicode {% ([ch]) => String.fromCodePoint(Number.parseInt(ch.value.slice(3, -1).replaceAll('_', ''), 16)) %}
char -> %escaped_line_feed {% () => '\n' %}

exp_literal -> exp_literal_int {% id %}
exp_literal -> exp_literal_bool {% id %}
exp_literal -> exp_literal_str {% id %}
exp_literal -> exp_literal_char {% id %}

exp_primary -> %left_paren _ exp _ %right_paren {% ([,, e]) => e %}
exp_primary -> special_variable_identifier_id {% ([i], ref) => new ast.Node(ref, ast.specialIdentifier, i.value) %}
exp_primary -> %identifier {% ([i], ref) => new ast.Node(ref, ast.identifier, i.value) %}
exp_primary -> exp_literal {% id %}

special_variable_identifier_id -> %keyword_output {% id %}
special_variable_identifier_id -> %keyword_input {% id %}
special_variable_identifier_id -> %keyword_fgi {% id %}
special_variable_identifier_id -> %keyword_fgo {% id %}
special_variable_identifier_id -> %keyword_post {% id %}

raw_assembly -> %keyword_asm _ %left_paren _ arg_list _ %right_paren {% ([_asm,, _paren,, args], ref) => new ast.Node(ref, ast.assembly, ...args) %}

exp_postfix -> exp_postfix _ %increment {% ([e], ref) => new ast.Node(ref, ast.postIncrement, e) %}
exp_postfix -> exp_postfix _ %decrement {% ([e], ref) => new ast.Node(ref, ast.postDecrement, e) %}
exp_postfix -> raw_assembly {% id %}
exp_postfix -> exp_postfix _ %left_paren _ arg_list _ %right_paren {% ([e,, _paren,, args], ref) => new ast.Node(ref, ast.functionCall, e, ...args) %}
exp_postfix -> exp_postfix _ %left_bracket _ exp _ %right_bracket {% ([e,, _brack,, index], ref) => new ast.Node(ref, ast.arrayAccess, e, index) %}
exp_postfix -> exp_postfix _ %dereference {% ([e], ref) => new ast.Node(ref, ast.dereference, e) %}
exp_postfix -> exp_postfix _ %ampersand {% ([e], ref) => new ast.Node(ref, ast.reference, e) %}
exp_postfix -> exp_primary {% id %}

arg_list -> null {% () => ast.Node.concat() %}
arg_list -> exp_assignment _ (
	_ %comma _ exp_assignment {% ([, _comma,, i]) => i %}
):* (_ %comma):? {% ([h,, a]) => ast.Node.concat(h, a) %}

exp_unary -> %increment _ exp_unary {% ([,, e], ref) => new ast.Node(ref, ast.preIncrement, e) %}
exp_unary -> %decrement _ exp_unary {% ([,, e], ref) => new ast.Node(ref, ast.preDecrement, e) %}
exp_unary -> %plus _ exp_unary {% ([,, e]) => e %}
exp_unary -> %minus _ exp_unary {% ([,, e], ref) => new ast.Node(ref, ast.negative, e) %}
exp_unary -> %bool_not _ exp_unary {% ([,, e], ref) => new ast.Node(ref, ast.logicalNot, e) %}
exp_unary -> %complement _ exp_unary {% ([,, e], ref) => new ast.Node(ref, ast.bitwiseNot, e) %}
exp_unary -> exp_postfix {% id %}

exp_additive -> exp_additive _ %plus _ exp_unary {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.add, a, b) %}
exp_additive -> exp_additive _ %minus _ exp_unary {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.subtract, a, b) %}
exp_additive -> exp_unary {% id %}

exp_shift -> exp_shift _ %shift_left _ exp_additive {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.shiftLeft, a, b) %}
exp_shift -> exp_shift _ %shift_right _ exp_additive {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.shiftRight, a, b) %}
exp_shift -> exp_shift _ %arithmetic_shift_right _ exp_additive {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.arithmeticShiftRight, a, b) %}
exp_shift -> exp_additive {% id %}

exp_bitwise_and -> exp_bitwise_and _ %ampersand _ exp_shift {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.bitwiseAnd, a, b) %}
exp_bitwise_and -> exp_shift {% id %}

exp_bitwise_xor -> exp_bitwise_xor _ %xor _ exp_bitwise_and {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.bitwiseXor, a, b) %}
exp_bitwise_xor -> exp_bitwise_and {% id %}

exp_bitwise_or -> exp_bitwise_or _ %or _ exp_bitwise_xor {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.bitwiseOr, a, b) %}
exp_bitwise_or -> exp_bitwise_xor {% id %}

exp_relational -> exp_bitwise_or _ %less_than _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.lessThan, a, b) %}
exp_relational -> exp_bitwise_or _ %greater_than _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.greaterThan, a, b) %}
exp_relational -> exp_bitwise_or _ %less_or_equals _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.lessOrEquals, a, b) %}
exp_relational -> exp_bitwise_or _ %greater_or_equals _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.greaterOrEquals, a, b) %}
exp_relational -> exp_bitwise_or _ %equals _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.equals, a, b) %}
exp_relational -> exp_bitwise_or _ %not_equals _ exp_bitwise_or {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.notEquals, a, b) %}
exp_relational -> exp_bitwise_or {% id %}

exp_logical_and -> exp_logical_and _ %bool_and _ exp_relational {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.logicalAnd, a, b) %}
exp_logical_and -> exp_relational {% id %}

exp_logical_xor -> exp_logical_xor _ %bool_xor _ exp_logical_and {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.logicalXor, a, b) %}
exp_logical_xor -> exp_logical_and {% id %}

exp_logical_or -> exp_logical_or _ %bool_or _ exp_logical_xor {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.logicalOr, a, b) %}
exp_logical_or -> exp_logical_xor {% id %}

exp_conditional -> exp_logical_or _ %question _ exp _ %colon _ exp_conditional {% ([a,, _op,, b,, _colon,, c], ref) => new ast.Node(ref, ast.conditional, a, b, c) %}
exp_conditional -> exp_logical_or {% id %}

exp_assignment -> special_variable_assignment_id _ %assign _ exp_assignment {% ([v,, _op,, e], ref) => new ast.Node(ref, ast.set, new ast.Node(ref, ast.specialIdentifier, v.value), e) %}
exp_assignment -> exp_unary _ %assign _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.set, a, b) %}
exp_assignment -> exp_unary _ %assign_plus _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setPlus, a, b) %}
exp_assignment -> exp_unary _ %assign_minus _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setMinus, a, b) %}
exp_assignment -> exp_unary _ %assign_shift_left _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setShiftLeft, a, b) %}
exp_assignment -> exp_unary _ %assign_shift_right _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setShiftRight, a, b) %}
exp_assignment -> exp_unary _ %assign_arithmetic_shift_right _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setArithmeticShiftRight, a, b) %}
exp_assignment -> exp_unary _ %assign_and _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setBitwiseAnd, a, b) %}
exp_assignment -> exp_unary _ %assign_xor _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setBitwiseXor, a, b) %}
exp_assignment -> exp_unary _ %assign_or _ exp_assignment {% ([a,, _op,, b], ref) => new ast.Node(ref, ast.setBitwiseOr, a, b) %}
exp_assignment -> exp_conditional {% id %}

special_variable_assignment_id -> %keyword_ien {% id %}
special_variable_assignment_id -> %keyword_output {% id %}

exp -> exp _ %comma _ exp_assignment {% ([a,, _op,, b]) => ast.Node.concat(a, b) %}
exp -> exp_assignment {% id %}

_ -> whitespace:* {% () => undefined %}
__ -> whitespace:+ {% () => undefined %}
whitespace -> %whitespace | %line_comment | %block_comment {% () => undefined %}
