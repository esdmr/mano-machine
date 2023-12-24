import process from 'node:process';
import fs from 'node:fs/promises';
import assert from 'node:assert';
import * as nearley from '@esdmr/nearley';
import grammar from './grammar.js';
import {Context} from './gen.js';

const [input, output = `${input.replace(/\.ckl$/, '')}.asm.sv`]
	= process.argv.slice(2);
assert(input, 'Input file missing');
assert(output, 'Output file missing');

const content = await fs.readFile(input, 'utf8');

const parser = new nearley.Parser(grammar);
parser.feed(content);

await fs.writeFile(output, `${Context.applyList(parser.results[0])}\n`, 'utf8');
