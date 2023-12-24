/* eslint-disable unicorn/prefer-code-point, no-bitwise, complexity */
import assert from 'node:assert';
import * as ast from './ast.js';
import * as asm from './asm.js';

class VariableDeclaration {
	operands;

	/**
	 * @param {asm.Operand[]} operands
	 */
	constructor(operands) {
		this.operands = operands;
	}
}

class FunctionDeclaration {
	reference;
	parameters;
	body;
	context;

	/**
	 * @param {asm.Operand} reference
	 * @param {asm.Operand[]} parameters
	 * @param {unknown} [body]
	 * @param {Context} [context]
	 */
	constructor(reference, parameters, body, context) {
		this.reference = reference;
		this.parameters = parameters;
		this.body = body;
		this.context = context;
	}
}

class SharedContext {
	/** @type {Set<FunctionDeclaration | VariableDeclaration>} */
	deferredDeclarations = new Set();
	/** @type {Map<number | asm.Operand, asm.Operand>} */
	scratchConstants = new Map();
	startOperand = new asm.Operand('start');
	isrOperand = new asm.Operand('isr');
	isrStubOperand = new asm.Operand('isr_stub');
	postOperand = new asm.Operand('post');
	/** @type {asm.Instruction[]} */
	instructions = [
		new asm.Instruction(asm.label, this.isrStubOperand),
		new asm.Instruction(asm.bsa, this.startOperand),
		new asm.Instruction(asm.bsa, this.isrOperand),
	];
}

export class Context {
	parent;
	/** @type {SharedContext} */
	shared;
	/** @type {Map<string, FunctionDeclaration | VariableDeclaration>} */
	declarations = new Map();
	/** @type {asm.Operand | undefined} */
	continueOperand;
	/** @type {asm.Operand | undefined} */
	breakOperand;
	/** @type {asm.Operand[]} */
	scratchVariables;
	/** @type {FunctionDeclaration | undefined} */
	currentFunction;
	/** @type {Context[]} */
	children = [];

	/**
	 * @param {Context | undefined} parent
	 */
	static forFunction(parent) {
		const context = new Context(parent);
		context.continueOperand = undefined;
		context.breakOperand = undefined;
		context.currentFunction = undefined;
		context.scratchVariables = [];
		return context;
	}

	/**
	 * @param {Context | undefined} [parent]
	 */
	constructor(parent) {
		this.parent = parent;
		this.shared = parent?.shared ?? new SharedContext();
		this.continueOperand = parent?.continueOperand ?? undefined;
		this.breakOperand = parent?.breakOperand ?? undefined;
		this.currentFunction = parent?.currentFunction ?? undefined;
		this.scratchVariables = parent?.scratchVariables ?? [];
		parent?.children.push(this);
	}

	/**
	 * @param {string} name
	 * @returns {FunctionDeclaration | VariableDeclaration | undefined}
	 */
	get(name) {
		return this.declarations.get(name) ?? this.parent?.get(name);
	}

	/**
	 * @param {asm.Instruction} instruction
	 */
	add(instruction) {
		this.shared.instructions.push(instruction);
	}

	/**
	 * @param {string} name
	 * @param {FunctionDeclaration | VariableDeclaration} declaration
	 */
	declare(name, declaration) {
		if (this.declarations.has(name)) {
			throw new Error(`Redeclaration of '${name}'`);
		}

		this.declarations.set(name, declaration);
		this.shared.deferredDeclarations.add(declaration);
	}

	/**
	 * @param {number | asm.Operand} value
	 */
	getScratchConstant(value) {
		if (typeof value === 'number') {
			value = asm.mod(value);
		}

		if (this.shared.scratchConstants.has(value)) {
			const operand = this.shared.scratchConstants.get(value);
			assert(operand);
			return operand;
		}

		const operand = new asm.Operand(
			`_${value instanceof asm.Operand ? value.name : value}`,
			value,
			'const',
		);

		const declaration = new VariableDeclaration([operand]);

		this.shared.scratchConstants.set(value, operand);
		this.shared.deferredDeclarations.add(declaration);
		return operand;
	}

	/**
	 * @param {number | asm.Operand} value
	 */
	loadConstant(value) {
		if (typeof value === 'number') {
			value = asm.mod(value);
		}

		if (value) {
			this.add(new asm.Instruction(asm.lda, this.getScratchConstant(value)));
		} else {
			this.add(new asm.Instruction(asm.cla));
		}
	}

	/**
	 * @param {unknown} [node]
	 * @returns {asm.Operand}
	 */
	getScratchVariable(node) {
		if (node) {
			this.accumulate(node);

			if (ast.Node.is(node, ast.identifier)) {
				// TODO: Support any constant operand here
				const [name] = node.args;
				assert(typeof name === 'string', 'Identifier is not a string');
				const declaration = this.get(name);

				if (
					declaration instanceof VariableDeclaration
					&& declaration.operands[0]
				) {
					return declaration.operands[0];
				}
			}

			const scratch = this.getScratchVariable();
			this.add(new asm.Instruction(asm.sta, scratch));
			return scratch;
		}

		if (this.scratchVariables.length > 0) {
			const operand = this.scratchVariables.pop();
			assert(operand);
			return operand;
		}

		const operand = new asm.Operand('scratch', undefined, 'scratch');
		const declaration = new VariableDeclaration([operand]);

		this.shared.deferredDeclarations.add(declaration);
		return operand;
	}

	/**
	 * @param {asm.Operand | undefined} operand
	 */
	relinquishScratchVariable(operand) {
		if (operand && operand.extra === 'scratch') {
			this.scratchVariables.push(operand);
		}
	}

	applyDeferred() {
		const declarations = new Set(this.shared.deferredDeclarations);
		this.shared.deferredDeclarations.clear();

		for (const declaration of declarations) {
			if (declaration instanceof VariableDeclaration) {
				for (const operand of declaration.operands) {
					this.add(new asm.Instruction(asm.data, operand));
				}
			} else {
				assert(
					declaration.body,
					'Deferred function declaration did not have a body',
				);
				assert(
					declaration.context,
					'Deferred function declaration without a context',
				);
				this.add(new asm.Instruction(asm.data, declaration.reference));
				declaration.context.apply(declaration.body);
				declaration.context.apply(new ast.Node(undefined, ast.statementReturn));
			}
		}
	}

	/**
	 * @param {unknown} list
	 */
	static applyList(list) {
		const context = new Context();
		assert(ast.Node.is(list, ast.list), 'Node is not a list');

		for (const item of list.args) {
			context.apply(item);
		}

		while (context.shared.deferredDeclarations.size > 0) {
			context.applyDeferred();
		}

		const [label, start, isr] = context.shared.instructions;
		assert(label);
		assert(start);
		assert(isr);

		if (!context.declarations.has('$isr')) {
			isr.into(new asm.Instruction(asm.blank));
			label.into(new asm.Instruction(asm.blank));
		}

		if (!context.declarations.has('$start')) {
			start.into(new asm.Instruction(asm.hlt));
		}

		context.shared.instructions.push(
			new asm.Instruction(asm.label, context.shared.postOperand),
		);

		/**
		 * @typedef {{next: number, map: Map<number, number>}} OperandInfo
		 * @type {Map<string, OperandInfo>}
		 */
		const operandNames = new Map();

		for (const i of context.shared.instructions) {
			if (!i.operand) {
				continue;
			}

			/** @type {OperandInfo} */
			const info = operandNames.get(i.operand.name) ?? {
				next: 0,
				map: new Map(),
			};

			operandNames.set(i.operand.name, info);

			if (!info.map.has(i.operand.id)) {
				info.map.set(i.operand.id, info.next++);
			}
		}

		/**
		 * @type {Set<asm.Operand>}
		 */
		const processedOperands = new Set();

		for (const i of context.shared.instructions) {
			if (!i.operand || processedOperands.has(i.operand)) {
				continue;
			}

			processedOperands.add(i.operand);
			const info = operandNames.get(i.operand.name);
			assert(info);
			const newId = info.map.get(i.operand.id);
			assert(newId !== undefined);
			i.operand.id = newId;
		}

		return context.toString();
	}

	/**
	 * @param {unknown} node
	 */
	apply(node) {
		if (!node) {
			return;
		}

		if (!ast.Node.is(node)) {
			throw new TypeError('Invalid node type for application');
		}

		switch (node.type) {
			case ast.assembly: {
				this.accumulate(node);
				break;
			}

			case ast.declarationVariable: {
				const [id, initializer] = node.args;
				assert(ast.Node.is(id, ast.identifier), 'Variable identifier missing');
				const defaultValues = this.evaluate(initializer, true);

				const [name, size = initializer ? defaultValues.length : 1] = id.args;
				assert(typeof name === 'string', 'Identifier is not a string');
				assert(typeof size === 'number', 'Variable size is not a number');

				this.declare(
					name,
					new VariableDeclaration(
						Array.from(
							{
								length: size,
							},
							(_, i) =>
								new asm.Operand(
									i ? `${name}_${i}` : name,
									defaultValues[i] ?? defaultValues.at(-1),
									'variable',
								),
						),
					),
				);
				break;
			}

			case ast.declarationFunction: {
				const [name, parameters, body] = node.args;
				assert(typeof name === 'string', 'Function name is not a string');
				assert(
					ast.Node.is(parameters, ast.list),
					'Function parameter list missing',
				);

				const forwardDeclaration = this.declarations.get(name);

				if (forwardDeclaration instanceof FunctionDeclaration) {
					assert(body, 'Multiple forward declarations with the same name');
					const context = Context.forFunction(this);
					context.currentFunction = forwardDeclaration;
					forwardDeclaration.body = body;
					forwardDeclaration.context = context;
				} else {
					const reference
						= {
							$start: this.shared.startOperand,
							$isr: this.shared.isrOperand,
						}[name] ?? new asm.Operand(name, undefined, 'function');

					const context = Context.forFunction(this);
					const declaration = new FunctionDeclaration(
						reference,
						parameters.args.flatMap(id => {
							assert(
								ast.Node.is(id, ast.identifier),
								'Parameter identifier missing',
							);

							const [name, size = 1] = id.args;
							assert(typeof name === 'string', 'Identifier is not a string');
							assert(
								typeof size === 'number',
								'Parameter size is not a number',
							);

							return Array.from(
								{
									length: size,
								},
								(_, i) =>
									new asm.Operand(
										i ? `${name}_${i}` : name,
										undefined,
										'parameter',
									),
							);
						}),
						body,
						body ? context : undefined,
					);
					context.currentFunction = declaration;
					this.declare(name, declaration);
				}

				if (body) {
					const declaration = this.declarations.get(name);
					assert(declaration instanceof FunctionDeclaration);
					assert(declaration.context);
					const operands = [...declaration.parameters];

					for (const id of parameters) {
						assert(
							ast.Node.is(id, ast.identifier),
							'Parameter identifier is missing',
						);

						const [name, size = 1] = id.args;
						assert(typeof name === 'string', 'Identifier is not a string');
						assert(typeof size === 'number', 'Parameter size is not a number');

						declaration.context.declare(
							name,
							new VariableDeclaration(
								Array.from(
									{
										length: size,
									},
									() => {
										const operand = operands.shift();
										assert(operand);
										return operand;
									},
								),
							),
						);
					}

					assert(operands.length === 0);
				}

				break;
			}

			case ast.statementIf: {
				const context = new Context(this);
				const else_ = new asm.Operand('else');
				const end_ = new asm.Operand('end');

				const [condition, trueBranch, falseBranch] = node.args;
				context.accumulate(condition);
				context.add(new asm.Instruction(asm.sna));
				context.add(new asm.Instruction(asm.bun, else_));
				context.apply(trueBranch);

				if (falseBranch) {
					context.add(new asm.Instruction(asm.bun, end_));
					context.add(new asm.Instruction(asm.label, else_));
					context.apply(falseBranch);
				} else {
					context.add(new asm.Instruction(asm.label, else_));
				}

				context.add(new asm.Instruction(asm.label, end_));
				break;
			}

			case ast.statementDo: {
				const context = new Context(this);
				const loop_ = new asm.Operand('loop');
				const end_ = new asm.Operand('end');
				context.continueOperand = loop_;
				context.breakOperand = end_;

				const [body, condition] = node.args;
				context.add(new asm.Instruction(asm.label, loop_));
				context.apply(body);
				context.accumulate(condition);
				context.add(new asm.Instruction(asm.spa));
				context.add(new asm.Instruction(asm.bun, loop_));
				break;
			}

			case ast.statementWhile: {
				const context = new Context(this);
				const loop_ = new asm.Operand('loop');
				const end_ = new asm.Operand('end');
				context.continueOperand = loop_;
				context.breakOperand = end_;

				const [condition, body] = node.args;
				context.add(new asm.Instruction(asm.label, loop_));
				context.accumulate(condition);
				context.add(new asm.Instruction(asm.sna));
				context.add(new asm.Instruction(asm.bun, end_));
				context.apply(body);
				context.add(new asm.Instruction(asm.bun, loop_));
				context.add(new asm.Instruction(asm.label, end_));
				break;
			}

			case ast.statementFor: {
				const context = new Context(this);
				const loop_ = new asm.Operand('loop');
				const end_ = new asm.Operand('end');
				context.continueOperand = loop_;
				context.breakOperand = end_;

				const [initializer, condition, step, body] = node.args;

				const inits = ast.Node.is(initializer, ast.list)
					? initializer.args
					: [initializer];

				for (const expression of inits) {
					if (
						ast.Node.is(expression, ast.set)
						&& ast.Node.is(expression.args[0], ast.identifier)
						&& typeof expression.args[0].args[0] === 'string'
						&& !context.get(expression.args[0].args[0])
					) {
						context.apply(
							new ast.Node(
								expression.args[0].pos,
								ast.declarationVariable,
								expression.args[0],
							),
						);
					} else if (
						ast.Node.is(expression, ast.identifier)
						&& typeof expression.args[0] === 'string'
						&& !context.declarations.has(expression.args[0])
					) {
						context.apply(
							new ast.Node(expression.pos, ast.declarationVariable, expression),
						);
					}
				}

				context.accumulate(initializer);
				context.add(new asm.Instruction(asm.label, loop_));
				context.accumulate(
					condition ?? new ast.Node(undefined, ast.literal, -1),
				);
				context.add(new asm.Instruction(asm.sna));
				context.add(new asm.Instruction(asm.bun, end_));
				context.apply(body);
				context.accumulate(step);
				context.add(new asm.Instruction(asm.bun, loop_));
				context.add(new asm.Instruction(asm.label, end_));
				break;
			}

			case ast.statementContinue: {
				if (!this.continueOperand) {
					throw new Error('Continue statement outside of loop');
				}

				this.add(new asm.Instruction(asm.bun, this.continueOperand));
				break;
			}

			case ast.statementBreak: {
				if (!this.breakOperand) {
					throw new Error('Break statement outside of loop');
				}

				this.add(new asm.Instruction(asm.bun, this.breakOperand));
				break;
			}

			case ast.statementReturn: {
				if (!this.currentFunction) {
					throw new Error('Return statement outside of function');
				}

				const [value] = node.args;
				this.accumulate(value);

				switch (this.currentFunction.reference) {
					case this.shared.startOperand: {
						this.add(new asm.Instruction(asm.hlt));
						break;
					}

					case this.shared.isrOperand: {
						this.add(
							new asm.Instruction(asm.bun, this.shared.isrStubOperand, true),
						);
						break;
					}

					default: {
						this.add(
							new asm.Instruction(
								asm.bun,
								this.currentFunction.reference,
								true,
							),
						);
					}
				}

				break;
			}

			case ast.statementExpression: {
				const [expression] = node.args;

				if (
					ast.Node.is(expression, ast.set)
					&& ast.Node.is(expression.args[0], ast.identifier)
					&& typeof expression.args[0].args[0] === 'string'
					&& !this.get(expression.args[0].args[0])
				) {
					this.apply(
						new ast.Node(
							expression.args[0].pos,
							ast.declarationVariable,
							expression.args[0],
						),
					);
				} else if (
					ast.Node.is(expression, ast.identifier)
					&& typeof expression.args[0] === 'string'
					&& !this.declarations.has(expression.args[0])
				) {
					this.apply(
						new ast.Node(expression.pos, ast.declarationVariable, expression),
					);
				}

				this.accumulate(expression);
				break;
			}

			case ast.statementVoid: {
				break;
			}

			case ast.statementSwitch:
			case ast.statementCase:
			case ast.statementDefault:
			case ast.statementConst: {
				throw new Error('TODO'); // TODO
			}

			case ast.list: {
				const context = new Context(this);

				for (const item of node) {
					context.apply(item);
				}

				break;
			}

			default: {
				throw new Error(`Unsupported node type for application: ${node.type}`);
			}
		}
	}

	/**
	 * @param {unknown} node
	 */
	accumulate(node) {
		if (!node) {
			return;
		}

		if (!ast.Node.is(node)) {
			throw new TypeError('Invalid node type for accumulation');
		}

		const evaluated = this.maybeEvaluate(node);

		if (evaluated) {
			assert(
				evaluated.length === 1,
				'Constant expression evaluated to multiple values',
			);
			this.loadConstant(evaluated[0]);
			return;
		}

		switch (node.type) {
			case ast.assembly: {
				this.add(
					new asm.Instruction(
						asm.raw,
						new asm.Operand(
							'asm',
							undefined,
							node.args.map(i => {
								if (ast.Node.is(i, ast.literal)) {
									return i.args[0];
								}

								if (ast.Node.is(i, ast.identifier)) {
									const [name] = i.args;
									assert(typeof name === 'string');
									const declaration = this.get(name);
									return declaration instanceof VariableDeclaration
										? declaration.operands[0]
										: declaration?.reference;
								}

								throw new TypeError('Invalid asm argument');
							}),
						),
					),
				);
				break;
			}

			case ast.postIncrement: {
				const [ref] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.add(new asm.Instruction(asm.inc));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.postDecrement: {
				const [ref] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.add(new asm.Instruction(asm.add, this.getScratchConstant(-1)));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.preIncrement: {
				const [ref] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.add(new asm.Instruction(asm.inc));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				this.add(new asm.Instruction(asm.add, this.getScratchConstant(-1)));
				break;
			}

			case ast.preDecrement: {
				const [ref] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.add(new asm.Instruction(asm.add, this.getScratchConstant(-1)));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				this.add(new asm.Instruction(asm.inc));
				break;
			}

			case ast.functionCall: {
				const [id, ...args] = node.args;
				if (ast.Node.is(id, ast.identifier)) {
					const [name] = id.args;
					assert(typeof name === 'string', 'Identifier is not a string');
					const fn = this.get(name);

					assert(
						fn instanceof FunctionDeclaration,
						'Identifier is not referring to a function',
					);
					assert(
						args.length === fn.parameters.length,
						'Mismatched number of arguments',
					);

					for (const i of fn.parameters.keys()) {
						this.accumulate(args[i]);
						this.add(new asm.Instruction(asm.sta, fn.parameters[i]));
					}

					this.add(new asm.Instruction(asm.bsa, fn.reference));
				} else if (ast.Node.is(id, ast.specialIdentifier)) {
					const [name] = id.args;
					assert(
						typeof name === 'string',
						'Special identifier is not a string',
					);

					switch (name) {
						case '$input': {
							assert(args.length === 0, '$input does not accept arguments');
							const loop_ = new asm.Operand('loop');
							this.add(new asm.Instruction(asm.label, loop_));
							this.add(new asm.Instruction(asm.ski));
							this.add(new asm.Instruction(asm.bun, loop_));
							this.add(new asm.Instruction(asm.inp));
							break;
						}

						case '$output': {
							assert(args.length === 1, '$output accepts exactly one argument');

							this.accumulate(args[0]);
							const loop_ = new asm.Operand('loop');
							this.add(new asm.Instruction(asm.label, loop_));
							this.add(new asm.Instruction(asm.sko));
							this.add(new asm.Instruction(asm.bun, loop_));
							this.add(new asm.Instruction(asm.out));
							break;
						}

						default: {
							throw new Error(`Unknown special identifier ${name}`);
						}
					}
				} else {
					assert(
						args.length === 0,
						'Cannot pass arguments to a pointer function call',
					);
					const scratch = this.getScratchVariable(
						new ast.Node(node.pos, ast.reference, id),
					);
					this.add(new asm.Instruction(asm.bsa, scratch, true));
				}

				break;
			}

			case ast.arrayAccess: {
				const [array, index] = node.args;

				if (ast.Node.is(array, ast.identifier)) {
					const [name] = array.args;
					assert(typeof name === 'string', 'Identifier is not a string');
					const declaration = this.get(name);
					assert(
						declaration instanceof VariableDeclaration,
						'Identifier does not refer to a variable',
					);
					const indexValue = this.evaluate(index);
					assert(indexValue.length === 1, 'Index evaluates to multiple values');
					this.add(
						new asm.Instruction(asm.lda, declaration.operands[indexValue[0]]),
					);
				} else {
					this.accumulate(
						new ast.Node(
							node.pos,
							ast.dereference,
							new ast.Node(
								node.pos,
								ast.add,
								new ast.Node(node.pos, ast.reference, array),
								index,
							),
						),
					);
				}

				break;
			}

			case ast.negative: {
				const [value] = node.args;

				if (ast.Node.is(value, ast.negative)) {
					const [realValue] = value.args;
					this.accumulate(realValue);
				} else {
					this.accumulate(value);
					this.add(new asm.Instruction(asm.cma));
					this.add(new asm.Instruction(asm.inc));
				}

				break;
			}

			case ast.logicalNot:
			case ast.bitwiseNot: {
				const [value] = node.args;

				if (
					ast.Node.is(value, ast.logicalNot)
					|| ast.Node.is(value, ast.bitwiseNot)
				) {
					const [realValue] = value.args;
					this.accumulate(realValue);
				} else {
					this.accumulate(value);
					this.add(new asm.Instruction(asm.cma));
				}

				break;
			}

			case ast.subtract: {
				const [a, b] = node.args;
				this.accumulate(
					new ast.Node(
						node.pos,
						ast.add,
						a,
						new ast.Node(node.pos, ast.negative, b),
					),
				);
				break;
			}

			case ast.shiftLeft: {
				const [left, right] = node.args;
				const rightValue = this.evaluate(right);
				assert(
					rightValue.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = rightValue;

				this.accumulate(left);

				if (places < 0 || places >= 16) {
					throw new RangeError(`Invalid shift left by ${places} bits`);
				} else if (places === 1) {
					this.add(new asm.Instruction(asm.cle));
					this.add(new asm.Instruction(asm.cil));
				} else if (places > 1) {
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cil : asm.cir),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF << places),
						),
					);
				}

				break;
			}

			case ast.shiftRight: {
				const [left, right] = node.args;
				const rightValue = this.evaluate(right);
				assert(
					rightValue.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = rightValue;

				this.accumulate(left);

				if (places < 0 || places >= 16) {
					throw new RangeError(`Invalid shift right by ${places} bits`);
				} else if (places === 1) {
					this.add(new asm.Instruction(asm.cle));
					this.add(new asm.Instruction(asm.cir));
				} else if (places > 1) {
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cir : asm.cil),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF >> places),
						),
					);
				}

				break;
			}

			case ast.arithmeticShiftRight: {
				const [left, right] = node.args;
				const rightValue = this.evaluate(right);
				assert(
					rightValue.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = rightValue;

				if (places < 0 || places >= 16) {
					throw new RangeError(
						`Invalid arithmetic shift right by ${places} bits`,
					);
				} else if (places >= 0 && places <= 3) {
					this.accumulate(left);

					for (let i = 0; i < places; i++) {
						this.add(new asm.Instruction(asm.cle));
						this.add(new asm.Instruction(asm.spa));
						this.add(new asm.Instruction(asm.cme));
						this.add(new asm.Instruction(asm.cir));
					}
				} else {
					const value = this.getScratchVariable(left);
					this.add(new asm.Instruction(asm.spa));
					this.loadConstant(~0xFF_FF >> places);
					this.add(new asm.Instruction(asm.sna));
					this.add(new asm.Instruction(asm.cla));
					const signedFill = this.getScratchVariable();
					this.add(new asm.Instruction(asm.sta, signedFill));
					this.add(new asm.Instruction(asm.lda, value));
					this.relinquishScratchVariable(value);
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cir : asm.cil),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF >> places),
						),
					);
					this.add(new asm.Instruction(asm.add, signedFill));
					this.relinquishScratchVariable(signedFill);
				}

				break;
			}

			case ast.dereference: {
				const [pointer] = node.args;
				const scratch = this.getScratchVariable(pointer);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.reference: {
				const [ref] = node.args;
				if (ast.Node.is(ref, ast.dereference)) {
					const [pointer] = ref.args;
					this.accumulate(pointer);
				} else if (ast.Node.is(ref, ast.arrayAccess)) {
					const [array, index] = ref.args;

					if (ast.Node.is(array, ast.identifier)) {
						const [name] = array.args;
						assert(typeof name === 'string', 'Identifier is not a string');
						const declaration = this.get(name);
						assert(
							declaration instanceof VariableDeclaration,
							'Identifier does not refer to a variable',
						);
						const parts = this.evaluate(index);
						assert(
							parts.length === 1,
							'Array index evaluates to multiple values',
						);
						assert(
							declaration.operands[parts[0]],
							'Variable does not have the given index',
						);
						this.add(
							new asm.Instruction(
								asm.lda,
								this.getScratchConstant(declaration.operands[parts[0]]),
							),
						);
					} else {
						const scratch = this.getScratchVariable(
							new ast.Node(node.pos, ast.reference, array),
						);
						this.accumulate(index);
						this.add(new asm.Instruction(asm.add, scratch));
						this.relinquishScratchVariable(scratch);
					}
				} else if (ast.Node.is(ref, ast.identifier)) {
					const [name] = ref.args;
					assert(typeof name === 'string', 'Identifier is not a string');
					const declaration = this.get(name);

					if (declaration instanceof VariableDeclaration) {
						this.add(
							new asm.Instruction(
								asm.lda,
								this.getScratchConstant(declaration.operands[0]),
							),
						);
					} else {
						assert(declaration, 'Identifier does not reference anything');
						this.add(
							new asm.Instruction(
								asm.lda,
								this.getScratchConstant(declaration.reference),
							),
						);
					}
				} else {
					throw new Error('Unsupported node type for reference');
				}

				break;
			}

			case ast.add: {
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'Add operand evaluates to multiple values',
					);

					switch (asm.mod(value[0])) {
						case 0: {
							this.accumulate(expression);
							break;
						}

						case 1: {
							this.accumulate(expression);
							this.add(new asm.Instruction(asm.inc));
							break;
						}

						case 0xFF_FF: {
							if (ast.Node.is(expression, ast.negative)) {
								this.accumulate(expression);
								this.add(new asm.Instruction(asm.cma));
								break;
							}

							// Fallthrough
						}

						default: {
							this.accumulate(expression);
							this.add(
								new asm.Instruction(asm.add, this.getScratchConstant(value[0])),
							);
						}
					}
				} else {
					const scratch = this.getScratchVariable(a);
					this.accumulate(b);
					this.add(new asm.Instruction(asm.add, scratch));
					this.relinquishScratchVariable(scratch);
				}

				break;
			}

			case ast.bitwiseAnd:
			case ast.logicalAnd: {
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'And operand evaluates to multiple values',
					);

					switch (asm.mod(value[0])) {
						case 0: {
							this.accumulate(expression);
							this.add(new asm.Instruction(asm.cla));
							break;
						}

						case 0xFF_FF: {
							this.accumulate(expression);
							break;
						}

						default: {
							this.accumulate(expression);
							this.add(
								new asm.Instruction(asm.and, this.getScratchConstant(value[0])),
							);
						}
					}
				} else {
					const scratch = this.getScratchVariable(a);
					this.accumulate(b);
					this.add(new asm.Instruction(asm.and, scratch));
					this.relinquishScratchVariable(scratch);
				}

				break;
			}

			case ast.bitwiseXor:
			case ast.logicalXor: {
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'Exclusive or operand evaluates to multiple values',
					);

					switch (asm.mod(value[0])) {
						case 0: {
							this.accumulate(expression);
							break;
						}

						case 0xFF_FF: {
							this.accumulate(expression);
							this.add(new asm.Instruction(asm.cma));
							break;
						}

						default: {
							const x = this.getScratchVariable(expression);
							this.add(
								new asm.Instruction(
									asm.and,
									this.getScratchConstant(~value[0]),
								),
							);
							this.add(new asm.Instruction(asm.cma));
							const z = this.getScratchVariable();
							this.add(new asm.Instruction(asm.sta, z));
							this.add(new asm.Instruction(asm.lda, x));
							this.relinquishScratchVariable(x);
							this.add(new asm.Instruction(asm.cma));
							this.add(
								new asm.Instruction(asm.and, this.getScratchConstant(value[0])),
							);
							this.add(new asm.Instruction(asm.cma));
							this.add(new asm.Instruction(asm.and, z));
							this.relinquishScratchVariable(z);
							this.add(new asm.Instruction(asm.cma));
						}
					}
				} else {
					const x = this.getScratchVariable(a);
					const y = this.getScratchVariable(b);
					this.add(new asm.Instruction(asm.cma));
					this.add(new asm.Instruction(asm.and, x));
					this.add(new asm.Instruction(asm.cma));
					const z = this.getScratchVariable();
					this.add(new asm.Instruction(asm.sta, z));
					this.add(new asm.Instruction(asm.lda, x));
					this.relinquishScratchVariable(x);
					this.add(new asm.Instruction(asm.cma));
					this.add(new asm.Instruction(asm.and, y));
					this.relinquishScratchVariable(y);
					this.add(new asm.Instruction(asm.cma));
					this.add(new asm.Instruction(asm.and, z));
					this.relinquishScratchVariable(z);
					this.add(new asm.Instruction(asm.cma));
				}

				break;
			}

			case ast.bitwiseOr:
			case ast.logicalOr: {
				// TODO: Logical operators should be short-circuiting
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'And operand evaluates to multiple values',
					);

					switch (asm.mod(value[0])) {
						case 0: {
							this.accumulate(expression);
							break;
						}

						case 0xFF_FF: {
							this.accumulate(expression);
							this.add(new asm.Instruction(asm.cla));
							this.add(new asm.Instruction(asm.cma));
							break;
						}

						default: {
							this.accumulate(expression);
							this.add(
								new asm.Instruction(
									asm.and,
									this.getScratchConstant(~value[0]),
								),
							);
							this.add(
								new asm.Instruction(asm.add, this.getScratchConstant(value[0])),
							);
						}
					}
				} else {
					this.accumulate(a);
					this.add(new asm.Instruction(asm.cma));
					const scratch = this.getScratchVariable();
					this.add(new asm.Instruction(asm.sta, scratch));
					this.accumulate(b);
					this.add(new asm.Instruction(asm.cma));
					this.add(new asm.Instruction(asm.and, scratch));
					this.relinquishScratchVariable(scratch);
					this.add(new asm.Instruction(asm.cma));
				}

				break;
			}

			case ast.lessThan: {
				const [left, right] = node.args;
				this.accumulate(
					new ast.Node(
						node.pos,
						ast.add,
						left,
						new ast.Node(node.pos, ast.negative, right),
					),
				);
				break;
			}

			case ast.lessOrEquals: {
				const [left, right] = node.args;
				this.accumulate(
					new ast.Node(
						node.pos,
						ast.bitwiseNot,
						new ast.Node(
							node.pos,
							ast.add,
							new ast.Node(node.pos, ast.negative, left),
							right,
						),
					),
				);
				break;
			}

			case ast.greaterThan: {
				const [left, right] = node.args;
				this.accumulate(
					new ast.Node(
						node.pos,
						ast.add,
						new ast.Node(node.pos, ast.negative, left),
						right,
					),
				);
				break;
			}

			case ast.greaterOrEquals: {
				const [left, right] = node.args;
				this.accumulate(
					new ast.Node(
						node.pos,
						ast.bitwiseNot,
						new ast.Node(
							node.pos,
							ast.add,
							left,
							new ast.Node(node.pos, ast.negative, right),
						),
					),
				);
				break;
			}

			case ast.equals: {
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'Equals operand evaluates to multiple values',
					);

					this.accumulate(
						new ast.Node(
							node.pos,
							ast.add,
							expression,
							new ast.Node(node.pos, ast.literal, -value[0]),
						),
					);
				} else {
					this.accumulate(
						new ast.Node(
							node.pos,
							ast.add,
							a,
							new ast.Node(node.pos, ast.negative, b),
						),
					);
				}

				this.add(new asm.Instruction(asm.cle));
				this.add(new asm.Instruction(asm.cme));
				this.add(new asm.Instruction(asm.sza));
				this.add(new asm.Instruction(asm.cme));
				this.add(new asm.Instruction(asm.cir));
				break;
			}

			case ast.notEquals: {
				const [a, b] = node.args;
				const i = this.maybeEvaluate(a);
				const j = this.maybeEvaluate(b);

				if (i || j) {
					const value = i || j;
					const expression = j ? a : b;
					assert(
						value?.length === 1,
						'Not equals operand evaluates to multiple values',
					);

					this.accumulate(
						new ast.Node(
							node.pos,
							ast.add,
							expression,
							new ast.Node(node.pos, ast.literal, -value[0]),
						),
					);
				} else {
					this.accumulate(
						new ast.Node(
							node.pos,
							ast.add,
							a,
							new ast.Node(node.pos, ast.negative, b),
						),
					);
				}

				this.add(new asm.Instruction(asm.cle));
				this.add(new asm.Instruction(asm.sza));
				this.add(new asm.Instruction(asm.cme));
				this.add(new asm.Instruction(asm.cir));
				break;
			}

			case ast.conditional: {
				const [condition, trueBranch, falseBranch] = node.args;
				const i = this.maybeEvaluate(condition);

				if (i) {
					assert(
						i.length === 1,
						'Ternary operand evaluates to multiple values',
					);

					this.accumulate(i[0] >= 0x80_00 ? trueBranch : falseBranch);
				} else {
					this.apply(
						new ast.Node(
							node.pos,
							ast.statementIf,
							condition,
							new ast.Node(node.pos, ast.statementExpression, trueBranch),
							new ast.Node(node.pos, ast.statementExpression, falseBranch),
						),
					);
				}

				break;
			}

			case ast.set: {
				const [ref, value] = node.args;
				if (ast.Node.is(ref, ast.specialIdentifier)) {
					const [name] = ref.args;
					assert(
						typeof name === 'string',
						'Special identifier is not a string',
					);

					switch (name) {
						case '$output': {
							this.accumulate(value);
							this.add(new asm.Instruction(asm.out));
							break;
						}

						case '$ien': {
							const result = this.evaluate(value);
							assert(
								result.length === 1,
								'$ien right hand side evaluates to multiple values',
							);
							const boolean = asm.mod(result[0]);
							this.loadConstant(boolean);
							this.add(
								new asm.Instruction(boolean >= 0x80_00 ? asm.ion : asm.iof),
							);
							break;
						}

						default: {
							throw new Error(`Unknown special identifier ${name}`);
						}
					}
				} else {
					const scratch = this.getScratchVariable(
						new ast.Node(node.pos, ast.reference, ref),
					);
					this.accumulate(value);
					this.add(new asm.Instruction(asm.sta, scratch, true));
					this.relinquishScratchVariable(scratch);
				}

				break;
			}

			case ast.setPlus: {
				const [ref, value] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.accumulate(value);
				this.add(new asm.Instruction(asm.add, scratch, true));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.setMinus: {
				const [ref, value] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.accumulate(value);
				this.add(new asm.Instruction(asm.cma));
				this.add(new asm.Instruction(asm.inc));
				this.add(new asm.Instruction(asm.add, scratch, true));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.setShiftLeft: {
				const [ref, value] = node.args;
				const right = this.evaluate(value);
				assert(
					right.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = right;

				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));

				if (places < 0 || places >= 16) {
					throw new RangeError(`Invalid shift left by ${places} bits`);
				} else if (places === 1) {
					this.add(new asm.Instruction(asm.cle));
					this.add(new asm.Instruction(asm.cil));
				} else if (places > 1) {
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cil : asm.cir),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF << places),
						),
					);
				}

				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);

				break;
			}

			case ast.setShiftRight: {
				const [ref, value] = node.args;
				const right = this.evaluate(value);
				assert(
					right.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = right;

				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));

				if (places < 0 || places >= 16) {
					throw new RangeError(`Invalid shift right by ${places} bits`);
				} else if (places === 1) {
					this.add(new asm.Instruction(asm.cle));
					this.add(new asm.Instruction(asm.cir));
				} else if (places > 1) {
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cir : asm.cil),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF >> places),
						),
					);
				}

				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);

				break;
			}

			case ast.setArithmeticShiftRight: {
				const [ref, value] = node.args;
				const right = this.evaluate(value);
				assert(
					right.length === 1,
					'Shift right hand side evaluates to multiple values',
				);
				const [places] = right;

				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);

				if (places < 0 || places >= 16) {
					throw new RangeError(
						`Invalid arithmetic shift right by ${places} bits`,
					);
				} else if (places >= 0 && places <= 3) {
					this.add(new asm.Instruction(asm.lda, scratch, true));

					for (let i = 0; i < places; i++) {
						this.add(new asm.Instruction(asm.cle));
						this.add(new asm.Instruction(asm.spa));
						this.add(new asm.Instruction(asm.cme));
						this.add(new asm.Instruction(asm.cir));
					}
				} else if (places > 3) {
					this.add(new asm.Instruction(asm.lda, scratch, true));
					this.add(new asm.Instruction(asm.spa));
					this.loadConstant(~0xFF_FF >> places);
					this.add(new asm.Instruction(asm.sna));
					this.add(new asm.Instruction(asm.cla));
					const signedFill = this.getScratchVariable();
					this.add(new asm.Instruction(asm.sta, signedFill));
					this.add(new asm.Instruction(asm.lda, scratch, true));
					const revPlaces = 17 - places;

					for (let i = 0; i < Math.min(places, revPlaces); i++) {
						this.add(
							new asm.Instruction(places <= revPlaces ? asm.cir : asm.cil),
						);
					}

					this.add(
						new asm.Instruction(
							asm.and,
							this.getScratchConstant(0xFF_FF >> places),
						),
					);
					this.add(new asm.Instruction(asm.add, signedFill));
					this.relinquishScratchVariable(signedFill);
				}

				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.setBitwiseAnd: {
				const [ref, value] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.accumulate(value);
				this.add(new asm.Instruction(asm.and, scratch, true));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.setBitwiseXor: {
				const [ref, value] = node.args;
				const a = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				const b = this.getScratchVariable(value);
				this.add(new asm.Instruction(asm.and, a, true));
				this.add(new asm.Instruction(asm.cma));
				const nand = this.getScratchVariable();
				this.add(new asm.Instruction(asm.sta, nand));
				this.add(new asm.Instruction(asm.and, a, true));
				this.add(new asm.Instruction(asm.cma));
				const left = this.getScratchVariable();
				this.add(new asm.Instruction(asm.sta, left));
				this.add(new asm.Instruction(asm.lda, nand));
				this.relinquishScratchVariable(nand);
				this.add(new asm.Instruction(asm.and, b));
				this.relinquishScratchVariable(b);
				this.add(new asm.Instruction(asm.cma));
				this.add(new asm.Instruction(asm.and, left));
				this.relinquishScratchVariable(left);
				this.add(new asm.Instruction(asm.cma));
				this.add(new asm.Instruction(asm.sta, a, true));
				this.relinquishScratchVariable(a);
				break;
			}

			case ast.setBitwiseOr: {
				// TODO: Logical operators should be short-circuiting
				const [ref, value] = node.args;
				const scratch = this.getScratchVariable(
					new ast.Node(node.pos, ast.reference, ref),
				);
				this.add(new asm.Instruction(asm.lda, scratch, true));
				this.add(new asm.Instruction(asm.cma));
				const not = this.getScratchVariable();
				this.add(new asm.Instruction(asm.sta, not));
				this.accumulate(value);
				this.add(new asm.Instruction(asm.cma));
				this.add(new asm.Instruction(asm.and, not));
				this.relinquishScratchVariable(not);
				this.add(new asm.Instruction(asm.cma));
				this.add(new asm.Instruction(asm.sta, scratch, true));
				this.relinquishScratchVariable(scratch);
				break;
			}

			case ast.identifier: {
				const [name] = node.args;
				assert(typeof name === 'string', 'Identifier is not a string');
				const declaration = this.get(name);
				assert(
					declaration instanceof VariableDeclaration,
					'Identifier does not reference a variable',
				);
				assert(declaration.operands[0], 'Variable has a zero size');
				this.add(new asm.Instruction(asm.lda, declaration.operands[0]));
				break;
			}

			case ast.sizeof: {
				const [name] = node.args;
				assert(typeof name === 'string', 'Identifier is not a string');
				const declaration = this.get(name);
				assert(
					declaration instanceof VariableDeclaration,
					'Sizeof does not reference a variable',
				);
				this.loadConstant(declaration.operands.length);
				break;
			}

			case ast.specialIdentifier: {
				const [name] = node.args;
				assert(typeof name === 'string', 'Special Identifier is not a string');

				switch (name) {
					case '$fgi': {
						this.add(new asm.Instruction(asm.cla));
						this.add(new asm.Instruction(asm.cma));
						this.add(new asm.Instruction(asm.ski));
						this.add(new asm.Instruction(asm.cma));
						break;
					}

					case '$fgo': {
						this.add(new asm.Instruction(asm.cla));
						this.add(new asm.Instruction(asm.cma));
						this.add(new asm.Instruction(asm.sko));
						this.add(new asm.Instruction(asm.cma));
						break;
					}

					case '$input': {
						this.add(new asm.Instruction(asm.inp));
						break;
					}

					case '$post': {
						this.loadConstant(this.shared.postOperand);
						break;
					}

					default: {
						throw new Error(`Unknown special identifier ${name}`);
					}
				}

				break;
			}

			case ast.literal: {
				const [value] = node.args;

				switch (typeof value) {
					case 'number': {
						this.loadConstant(value);
						break;
					}

					case 'string': {
						assert(
							value.length === 1,
							'Multi-character literal cannot be accumulated',
						);
						this.loadConstant(value.charCodeAt(0));
						break;
					}

					default: {
						throw new Error(`Invalid type of literal ${typeof value}`);
					}
				}

				break;
			}

			case ast.list: {
				for (const item of node) {
					this.accumulate(item);
				}

				break;
			}

			default: {
				throw new Error(`Unsupported node type for accumulation: ${node.type}`);
			}
		}
	}

	/**
	 * @template {any[]} T
	 * @param {T} nodes
	 */
	evaluateZipped(...nodes) {
		const values = nodes.map(i => this.evaluate(i));
		const max = Math.max(...values.map(i => i.length));
		assert(values.every(i => i.length === 1 || i.length === max));
		return Array.from(
			{
				length: max,
			},
			(_, i) =>
				/** @type {{[i in keyof T]: number}} */
				(
					values.map(j => {
						const value = j[i] ?? j[0];
						assert(value);
						return asm.mod(value);
					})
				),
		);
	}

	/**
	 * @param {unknown} node
	 * @param {boolean} [listIsArray]
	 * @returns {number[] | undefined}
	 */
	maybeEvaluate(node, listIsArray) {
		try {
			return this.evaluate(node, listIsArray);
		} catch {}
	}

	/**
	 * @param {unknown} node
	 * @param {boolean} [listIsArray]
	 * @returns {number[]}
	 */
	evaluate(node, listIsArray = false) {
		if (!node) {
			return [];
		}

		if (!ast.Node.is(node)) {
			throw new TypeError('Invalid node type for evaluation');
		}

		switch (node.type) {
			case ast.literal: {
				const [value] = node.args;

				switch (typeof value) {
					case 'number': {
						return [value];
					}

					case 'string': {
						return value.split('').map(i => {
							const charCode = i.charCodeAt(0);
							assert(charCode !== undefined);
							return charCode;
						});
					}

					default: {
						throw new Error('Unknown type for literal');
					}
				}
			}

			case ast.negative: {
				const [value] = node.args;
				return this.evaluate(value).map(i => -i);
			}

			case ast.logicalNot: {
				const [value] = node.args;
				return this.evaluate(value).map(i => (i ? 0 : -1));
			}

			case ast.bitwiseNot: {
				const [value] = node.args;
				return this.evaluate(value).map(i => ~i);
			}

			case ast.add: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => i + j);
			}

			case ast.subtract: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => i - j);
			}

			case ast.shiftLeft: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => {
					assert(j >= 0 && j < 16);
					return i << j;
				});
			}

			case ast.shiftRight: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => {
					assert(j >= 0 && j < 16);
					return i >> j;
				});
			}

			case ast.arithmeticShiftRight: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => {
					assert(j >= 0 && j < 16);
					i = asm.mod(i);
					return (i >> j) | asm.mod(i >= 0x80_00 ? ~0xFF_FF >> j : 0);
				});
			}

			case ast.bitwiseAnd: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => i & j);
			}

			case ast.bitwiseXor: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => i ^ j);
			}

			case ast.bitwiseOr: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => i | j);
			}

			case ast.lessThan: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i < j ? -1 : 0));
			}

			case ast.lessOrEquals: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i <= j ? -1 : 0));
			}

			case ast.greaterThan: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i > j ? -1 : 0));
			}

			case ast.greaterOrEquals: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i >= j ? -1 : 0));
			}

			case ast.equals: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i === j ? -1 : 0));
			}

			case ast.notEquals: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i === j ? 0 : -1));
			}

			case ast.logicalAnd: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i && j ? -1 : 0));
			}

			case ast.logicalXor: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i === j ? 0 : -1));
			}

			case ast.logicalOr: {
				const [a, b] = node.args;
				return this.evaluateZipped(a, b).map(([i, j]) => (i || j ? -1 : 0));
			}

			case ast.conditional: {
				const [condition, trueBranch, falseBranch] = node.args;
				return this.evaluateZipped(condition, trueBranch, falseBranch).map(
					([i, j, k]) => (i ? j : k),
				);
			}

			case ast.sizeof: {
				const [name] = node.args;
				assert(typeof name === 'string', 'Identifier is not a string');
				const declaration = this.get(name);
				assert(
					declaration instanceof VariableDeclaration,
					'Sizeof does not reference a variable',
				);
				return [declaration.operands.length];
			}

			case ast.list: {
				return listIsArray
					? node.args.flatMap(i => this.evaluate(i))
					: this.evaluate(node.args.at(-1));
			}

			default: {
				throw new Error(`Unsupported node type for evaluation: ${node.type}`);
			}
		}
	}

	toString() {
		return `\`include "preamble.sv"\n\`IMPORT(assembler)\n\n${this.shared.instructions.join(
			'\n',
		)}`;
	}
}
