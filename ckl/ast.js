export const declarationVariable = 'var';
export const declarationFunction = 'fun';
export const statementIf = 'xif';
export const statementDo = 'xdo';
export const statementWhile = 'xwh';
export const statementFor = 'xfr';
export const statementContinue = 'xco';
export const statementBreak = 'xbr';
export const statementSwitch = 'xsw';
export const statementCase = 'xca';
export const statementDefault = 'xdf';
export const statementConst = 'xcn';
export const statementReturn = 'xrt';
export const statementExpression = 'xpr';
export const statementVoid = 'xvo';
export const postIncrement = 'poi';
export const postDecrement = 'pod';
export const functionCall = 'fnc';
export const arrayAccess = 'ara';
export const preIncrement = 'pri';
export const preDecrement = 'prd';
export const negative = 'neg';
export const logicalNot = 'lgn';
export const bitwiseNot = 'btn';
export const dereference = 'der';
export const reference = 'ref';
export const add = 'add';
export const subtract = 'sub';
export const shiftLeft = 'shl';
export const shiftRight = 'shr';
export const arithmeticShiftRight = 'asr';
export const bitwiseAnd = 'bta';
export const bitwiseXor = 'btx';
export const bitwiseOr = 'bto';
export const lessThan = 'rlt';
export const lessOrEquals = 'rle';
export const greaterThan = 'rgt';
export const greaterOrEquals = 'rge';
export const equals = 'req';
export const notEquals = 'rne';
export const logicalAnd = 'lga';
export const logicalXor = 'lgx';
export const logicalOr = 'lgo';
export const conditional = 'tri';
export const set = 'set';
export const setPlus = 'spl';
export const setMinus = 'smi';
export const setShiftLeft = 'ssl';
export const setShiftRight = 'ssr';
export const setArithmeticShiftRight = 'sar';
export const setBitwiseAnd = 'sba';
export const setBitwiseXor = 'sbx';
export const setBitwiseOr = 'sbo';
export const literal = 'lit';
export const identifier = 'idn';
export const specialIdentifier = 'ids';
export const list = 'lst';
export const assembly = 'asm';
export const sizeof = 'len';

export class Node {
	/**
	 * @param {unknown} object
	 * @param {string} [type]
	 * @returns {object is Node}
	 */
	static is(object, type) {
		return object instanceof Node && (!type || object.type === type);
	}

	type;
	args;

	/**
	 * @param {unknown[]} args
	 */
	static concat(...args) {
		return new Node(
			undefined,
			list,
			...args.flatMap((i) =>
				i instanceof Node && i.type === list ? i.args : i,
			),
		);
	}

	/**
	 * @param {unknown} pos
	 * @param {string} type
	 * @param  {...unknown} args
	 */
	constructor(pos, type, ...args) {
		this.pos = pos;
		this.type = type;
		this.args = args;
	}

	*[Symbol.iterator]() {
		yield* this.args;
	}
}
