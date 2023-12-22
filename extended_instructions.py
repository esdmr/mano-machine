#!/usr/bin/env python3.12
from textwrap import dedent
from typing import Iterable, Optional


class Instruction:
    def __init__(
        self,
        names: set[str],
        code: int,
        *,
        inc: int = 0,
        ld: int = 0,
        clr: int = 0,
        j: int = 0,
        k: int = 0,
        pc: int = 0,
        s: int = 0,
        z: int = 0,
    ) -> None:
        self.names = names
        self.code = code
        self.inc = inc
        self.ld = ld
        self.clr = clr
        self.j = j
        self.k = k
        self.pc = pc
        self.s = s
        self.z = z

    def __add__(self, other: "Instruction") -> "Optional[Instruction]":
        has_side_effects = other.j + other.k

        if (
            self.j + other.j > 1
            or self.k + other.k > 1
            or self.ld + other.ld > 1
            or (self.code & other.code)
            or self.s + other.s > 2
            or (self.s + other.s == 2 and self.pc > 1)
            or self.z + other.z > 1
            or (self.s == 2 and self.pc + other.pc > 2)
            or (other.inc and self.clr and not has_side_effects)
            or (other.ld and self.clr and not has_side_effects)
            or (other.clr and self.ld and not has_side_effects)
            or (other.inc and self.ld and not has_side_effects)
            or (other.clr and self.inc and not has_side_effects)
            or (other.ld and self.inc and not has_side_effects)
            or ("CLA" in self.names and "CMA" in other.names)
            or ("CMA" in self.names and "CLA" in other.names)
            or ("CIL" in self.names and "INC" in other.names)
            or ("INC" in self.names and "CIL" in other.names)
            or ("CIR" in self.names and "INC" in other.names)
            or ("INC" in self.names and "CIR" in other.names)
        ):
            return

        comb = Instruction(
            names=self.names.union(other.names),
            code=self.code | other.code,
            inc=self.inc + other.inc,
            ld=self.ld + other.ld,
            clr=self.clr + other.clr,
            j=self.j + other.j,
            k=self.k + other.k,
            pc=self.pc + other.pc,
            s=self.s + other.s,
            z=self.z + other.z,
        )

        if comb.clr or comb.ld:
            comb.inc = 0

        if comb.clr:
            comb.ld = 0

        return comb

    @staticmethod
    def product(
        a: "Iterable[Instruction]", b: "Iterable[Instruction]"
    ) -> "list[Instruction]":
        instructions = [i + j for i in a for j in b]
        code = {i.code: i for i in instructions if i}
        return list(code.values())

    @staticmethod
    def simplify(names: set[str], result: str, *source: str) -> None:
        for i in source:
            if i not in names:
                return

        for i in source:
            names.remove(i)

        names.add(result)

    def __str__(self) -> str:
        names = self.names.copy()

        self.simplify(names, "SKP", "SPA", "SNA")
        self.simplify(names, "SAE", "SZA", "SZE")
        self.simplify(names, "SNE", "SNA", "SZE")
        self.simplify(names, "SPE", "SPA", "SZE")
        self.simplify(names, "SQA", "SNA", "SZA")
        self.simplify(names, "SQE", "SNA", "SAE")
        self.simplify(names, "CLR", "CLA", "CLE")
        self.simplify(names, "CER", "CLA", "CIR")
        self.simplify(names, "CEL", "CLA", "CIL")
        self.simplify(names, "CCA", "CLE", "CMA")
        self.simplify(names, "CCE", "CLA", "CME")
        self.simplify(names, "CMP", "CMA", "CME")
        self.simplify(names, "CLI", "INC", "CLE")
        self.simplify(names, "CMI", "INC", "CME")

        skip = next((i[1:] for i in names if i.startswith("S")), None)
        action = next((i[1:] for i in names if i.startswith("C")), None) or (
            "IN" if "INC" in names else None
        )

        name = skip + action if skip and action else "X" + "".join(names)

        return f"`ASM_REG_EXT_INST({name}, 12'b{self.code:012b})"


instructions = {
    Instruction({"CLA"}, 1 << 11, clr=1),
    Instruction({"CLE"}, 1 << 10, k=1),
    Instruction({"CMA"}, 1 << 9, ld=1),
    Instruction({"CME"}, 1 << 8, j=1, k=1),
    Instruction({"CIR"}, 1 << 7, ld=1, j=1, k=1),
    Instruction({"CIL"}, 1 << 6, ld=1, j=1, k=1),
    Instruction({"INC"}, 1 << 5, inc=1),
    Instruction({"SPA"}, 1 << 4, pc=1, s=1, z=1),
    Instruction({"SNA"}, 1 << 3, pc=1, s=1),
    Instruction({"SZA"}, 1 << 2, pc=1, z=1),
    Instruction({"SZE"}, 1 << 1, pc=1),
}

print(
    dedent(
        """\
        /**
        * Define a extended register instruction with given name and operand. The
        * resulting expression would have an opcode of 7, an addressing mode of 0, and
        * the given operand. The macro `ASM_<name>` would insert this instruction at
        * the current address.
        *
        * @param __ASM_NAME__ - name of instruction. It should be a valid identifier.
        * @param __ASM_OPR__ - operand. It should be a 12 bit integer expression.
        */
        `define ASM_REG_EXT_INSTR(__ASM_NAME__, __ASM_OPR__) \\
        `define ASM_``__ASM_NAME__                       \\ \\
            `ASM_DATA({4'o07, 12'(__ASM_OPR__)}, 1)

        // Register-reference Extension
        """
    )
)

combinations = instructions

for i in range(2, len(instructions)):
    combinations = Instruction.product(combinations, instructions)
    if combinations:
        print(*combinations, sep="\n")
