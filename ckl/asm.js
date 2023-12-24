import assert from 'node:assert';
import {format} from 'node:util';

// Memory-reference
export const and = 'AND';
export const add = 'ADD';
export const lda = 'LDA';
export const sta = 'STA';
export const bun = 'BUN';
export const bsa = 'BSA';
export const isz = 'ISZ';

// Register-reference
export const cla = 'CLA';
export const cle = 'CLE';
export const cma = 'CMA';
export const cme = 'CME';
export const cir = 'CIR';
export const cil = 'CIL';
export const inc = 'INC';
export const spa = 'SPA';
export const sna = 'SNA';
export const sza = 'SZA';
export const sze = 'SZE';
export const hlt = 'HLT';

// Input-output
export const inp = 'INP';
export const out = 'OUT';
export const ski = 'SKI';
export const sko = 'SKO';
export const ion = 'ION';
export const iof = 'IOF';

export const raw = 'RAW';
export const label = 'LABEL';
export const data = 'DATA';
export const blank = 'EMPTY';

/**
 * @param {number} value
 */
export function mod(value, base = 0x1_00_00) {
	return ((value % base) + base) % base;
}

let id = 0;

export class Operand {
	id = ++id;
	name;
	defaultValue;
	extra;

	/**
	 * @param {string} [name]
	 * @param {number | Operand} [defaultValue]
	 * @param {unknown} [extra]
	 */
	constructor(name = '_', defaultValue = 0, extra) {
		this.name = name;
		this.defaultValue = defaultValue;
		this.extra = extra;
	}

	/**
	 * @param {Operand} other
	 */
	into(other) {
		this.id = other.id;
		this.name = other.name;
		this.defaultValue = other.defaultValue;
		this.extra = other.extra;
	}

	toString() {
		return `${this.name}_${this.id || ''}`;
	}
}

export class Instruction {
	opcode;
	operand;
	mode;

	/**
	 * @param {string} opcode
	 * @param {Operand} [operand]
	 * @param {boolean} [mode]
	 */
	constructor(opcode, operand, mode = false) {
		this.opcode = opcode;
		this.operand = operand;
		this.mode = mode;
	}

	toString() {
		switch (this.opcode) {
			case blank: {
				return '// Blank line';
			}

			case label: {
				return `\`ASM_LABEL(${this.operand})`;
			}

			case data: {
				if (this.operand?.defaultValue instanceof Operand) {
					return `\`ASM_LABEL(${this.operand})\n  \`ASM_DATA_LABEL(${this.operand.defaultValue})`;
				}

				return `\`ASM_LABEL(${this.operand})\n  \`ASM_DATA(${mod(
					this.operand?.defaultValue ?? 0,
				)})`;
			}

			case raw: {
				assert(this.operand);
				assert(Array.isArray(this.operand.extra));
				assert(typeof this.operand.extra[0] === 'string');
				return format(
					this.operand.extra[0].replaceAll(/%+(?!s)/g, '%%'),
					...this.operand.extra.slice(1),
				);
			}

			default: {
				if (this.operand) {
					return `  \`ASM_${this.opcode}_${this.mode ? 'I' : 'D'}L(${
						this.operand
					})`;
				}

				return `  \`ASM_${this.opcode}`;
			}
		}
	}
}
