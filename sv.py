#!/usr/bin/env python3.12
from argparse import ArgumentParser, Namespace
from bdb import BdbQuit
from glob import glob
from io import TextIOWrapper
from json import dump, dumps
from os import PathLike, chdir, close
from pathlib import Path
from re import compile
from shutil import which
from subprocess import PIPE, Popen, run
from sys import stdout
from tempfile import mkstemp
from traceback import print_exception
from types import TracebackType
from typing import Iterable, Optional, Type, cast

import sys

try:
    from argcomplete import autocomplete  # type: ignore
except:

    def autocomplete(_: ArgumentParser):
        ...


type StrOrBytesPath = str | bytes | PathLike[str] | PathLike[bytes]
LINE_RE = compile(r"^(.*?)((?:\s+\\)*)$")
BACKSLASH_RE = compile(r"\\")
BACKSLASH_STR = " \\"
DOUBLE_NEWLINE_RE = compile(r"\n(?:\s*?\n)+")
DOUBLE_NEWLINE_STR = "\n\n"
MODULE_PATH_RE = compile(r"(?:/|^)[A-Z][^/]+\.sv$")
ARG_MAX = 4096


class FormatterNode(list["FormatterNode | str"]):
    @staticmethod
    def _format(
        child: "FormatterNode | str", custom_width: Optional[int] = None
    ) -> list[str]:
        if type(child) is str:
            return [child]

        assert type(child) is FormatterNode
        lines = [j for i in child for j in FormatterNode._format(i, custom_width)]

        if custom_width is None:
            width = max([len(i) for i in lines])
            lines = [
                j
                for i in child
                for j in FormatterNode._format(i, width - len(BACKSLASH_STR))
            ]
        else:
            width = custom_width

        return [i + " " * (width - len(i)) + BACKSLASH_STR for i in lines]

    def format(self):
        return "".join([f"{j}\n" for i in self for j in FormatterNode._format(i)])


class FormatterTree:
    def __init__(self) -> None:
        self.root = FormatterNode()
        self.stack = [self.root]

    def descend(self):
        node = FormatterNode()
        self.stack[-1].append(node)
        self.stack.append(node)

    def ascend(self):
        self.stack.pop()

    def to(self, depth: int):
        assert depth >= 0
        old_len = len(self.stack)
        new_len = depth + 1

        if old_len < new_len:
            for _ in range(old_len, new_len):
                self.descend()
        else:
            for _ in range(old_len, new_len, -1):
                self.ascend()

    def insert(self, value: str):
        self.stack[-1].append(value)


def format(source: str):
    tree = FormatterTree()

    for i in source.splitlines():
        match = LINE_RE.match(i)
        assert match is not None

        tree.to(len(BACKSLASH_RE.findall(match.group(2))))
        tree.insert(match.group(1))

    return DOUBLE_NEWLINE_RE.sub(DOUBLE_NEWLINE_STR, tree.root.format())


def run_iverilog(
    file: Path,
    *,
    output: Optional[Path] = None,
    output_format: Optional[str] = None,
    target_flags: list[str] = [],
    preprocess_only: bool = False,
    no_vpi: bool = False,
):
    args: list[StrOrBytesPath] = [
        "iverilog",
        "-g2012",
        "-Wall",
        "-Wno-timescale",  # Timescale is ALWAYS inherited from tap.sv
        "-I",
        ".",
        file.name,
    ]

    if not no_vpi:
        args += [
            "-L",
            Path("vpi").absolute().as_posix(),
            "-m",
            "io",
        ]

    if output is not None:
        args += ["-o", output.absolute().as_posix()]

    if output_format:
        args.append(f"-t{output_format}")

    if preprocess_only:
        args.append("-E")

    for i in target_flags:
        args.append(f"-p{i}")

    return run(args, cwd=file.parent, check=True)


def run_vvp(file: Path):
    args: list[StrOrBytesPath] = [file]
    return run(args, cwd=file.parent, check=True)


def run_vscode(
    *files: Path,
    wait: bool = False,
):
    args: list[StrOrBytesPath] = [
        "code",
        "-r",
        *[i.absolute().as_posix() for i in files],
    ]

    if wait:
        args.append("-w")

    return run(args, check=True)


def run_batch(args: list[str], *rest_: str, check: bool = True):
    args_len = sum([len(i.encode()) + 1 for i in args])
    rest = list(rest_)

    while rest:
        batch_args = args
        remaining = ARG_MAX - args_len

        while rest and remaining > 0:
            arg = rest.pop()
            batch_args.append(arg)
            remaining -= len(arg.encode()) + 1

        run(args, check=check)


def run_verible_formatter(*files: Path):
    files_str = [i.absolute().as_posix() for i in files]
    args = ["verible-verilog-format", "--inplace", "--column_limit", "80"]
    run_batch(args, *files_str, check=True)


def run_verible_syntax(*files: Path):
    files_str = [i.absolute().as_posix() for i in files]
    args = ["verible-verilog-syntax"]
    run_batch(args, *files_str, check=True)


def run_verilator(file: Path, *, no_multidriven: bool = False):
    args = [
        "verilator",
        "--lint-only",
        "-Wall",
        "-Wpedantic",
        "-Wno-PINCONNECTEMPTY",  # Better than simply not writing the pin.
        "-Wno-VARHIDDEN",  # Mostly edge cases. Low priority.
        "-Wno-DECLFILENAME",  # Usually, the input to verilator is preprocessed.
        "+1800-2012ext+sv",
        "--timing",
        "--top-module",
        file.stem.split(".", 1)[0],
        file.name,
    ]

    if no_multidriven:
        args.append("-Wno-MULTIDRIVEN")

    run(args, cwd=file.parent, check=True)


def run_vvp_streaming(file: Path):
    proc = Popen(file, stdout=PIPE)
    assert proc.stdout
    for line in TextIOWrapper(proc.stdout, encoding="utf-8"):
        yield line.removesuffix("\n")
    assert proc.wait() == 0


def run_curl(
    url: str,
    *,
    method: str = "",
    headers: dict[str, str] = {},
    input: Optional[bytes] = None,
):
    args: list[StrOrBytesPath] = ["curl"]

    if method:
        args += ["-X", method]

    for k, v in headers.items():
        args += ["-H", f"{k}: {v}"]

    if input is not None:
        args += ["--data-binary", "@-"]

    args.append(url)
    return run(args, input=input, check=True)


def run_xdg_open(url_or_path: StrOrBytesPath):
    return run(["xdg-open", url_or_path], check=True)


def run_make(*targets: str):
    args: list[StrOrBytesPath] = ["make"]

    for i in targets:
        args.append(i)

    return run(args, cwd=Path("vpi"), check=True)

def run_pnpm(*args: str):
    return run(["corepack", "pnpm", *args], cwd=Path("ckl"), check=True)

def run_gcc(*args: str):
    return run(["gcc", *args], check=True)

def run_node(program: StrOrBytesPath, *args: str):
    return run(["node", program, *args], check=True)

def formatFile(file: Path):
    with open(file, "r") as f:
        content = f.read()

    content = format(content)

    if file.name.endswith(".asm.sv"):
        content = "".join([i.strip() + "\n" for i in content.splitlines()])
        content = "".join(
            [
                (
                    "  "
                    if i.startswith("`ASM_")
                    and not i.startswith("`ASM_SUB")
                    and not i.startswith("`ASM_LABEL")
                    else ""
                )
                + i
                + "\n"
                for i in content.splitlines()
            ]
        )

    with open(file, "w") as f:
        f.write(content)


def mktemp(file: Optional[Path], suffix: str):
    temp = mkstemp(prefix=f"{file.stem}." if file else "", suffix=suffix)
    close(temp[0])
    return Path(temp[1])


class TestFile:
    def __init__(self, file: Path) -> None:
        self.failed = False
        self.path = file

    def is_failed(self):
        return self.failed

    def run(self, temp_file: Path):
        run_iverilog(self.path, output=temp_file)
        generator = run_vvp_streaming(temp_file)

        for line in generator:
            if line.startswith("not ok"):
                self.failed = True

            yield line


class TestDirectory:
    def __init__(self, dir: Path, included_files: list[Path]) -> None:
        self.path = dir
        self.files = [Path(dir, i) for i in glob("*", root_dir=dir)]
        self.subtests: list[TestDirectory | TestFile] = []

        for i in self.files:
            if i.is_dir():
                self.subtests.append(TestDirectory(i, included_files))
            elif MODULE_PATH_RE.search(str(i)) and i.absolute() in included_files:
                self.subtests.append(TestFile(i))

    def is_failed(self) -> bool:
        return any([i.is_failed() for i in self.subtests])

    def run(self, temp_file: Path) -> Iterable[str]:
        yield "TAP version 14"

        for i in self.subtests:
            yield f"# Subtest: {i.path}"

            for j in i.run(temp_file):
                if not j.startswith("TAP version "):
                    yield "    " + j

            if i.is_failed():
                yield f"not ok - {i.path}"
            else:
                yield f"ok - {i.path}"

        yield f"1..{len(self.subtests)}"


class ExceptionAggregator:
    def __init__(self) -> None:
        self.errors: list[Exception] = []

    def __enter__(self) -> None:
        pass

    def __exit__(
        self,
        exc_type: Optional[Type[Exception]],
        exc_val: Optional[Exception],
        exc_tb: Optional[TracebackType],
    ) -> bool:
        if (
            exc_type is BdbQuit
            or exc_type is SystemExit
            or exc_type is KeyboardInterrupt
        ):
            return False
        if exc_val is not None:
            self.errors.append(exc_val)
            print_exception(exc_val)
        return True

    def assert_no_errors(self):
        assert not self.errors


class Action:
    CKL = "ckl"
    COMPILE = "compile"
    FORMAT = "format"
    LINT = "lint"
    MAKE = "make"
    PREPROCESS = "preprocess"
    REMAINING_TESTS = "remaining-tests"
    RUN = "run"
    SYNTHESIZE = "synthesize"
    TEST = "test"


class Args(Namespace):
    target_flags: Optional[list[str]]
    action: Optional[str]
    file: Optional[str]
    files: Optional[list[str]]
    no_vpi: Optional[bool]
    no_iverilog: Optional[bool]
    no_verible: Optional[bool]
    no_verilator: Optional[bool]
    online: Optional[str]
    vscode: Optional[bool]
    out: Optional[str]
    reporter: Optional[str]
    sub_action: Optional[str]
    type: Optional[str]
    wait: Optional[bool]


def parse_args():
    parser = ArgumentParser()
    subparsers = parser.add_subparsers(dest="action", required=True)

    ckl = subparsers.add_parser(Action.CKL)
    compile = subparsers.add_parser(Action.COMPILE)
    format = subparsers.add_parser(Action.FORMAT)
    lint = subparsers.add_parser(Action.LINT)
    make = subparsers.add_parser(Action.MAKE)
    preprocess = subparsers.add_parser(Action.PREPROCESS)
    run = subparsers.add_parser(Action.RUN)
    synthesize = subparsers.add_parser(Action.SYNTHESIZE)
    test = subparsers.add_parser(Action.TEST)
    subparsers.add_parser(Action.REMAINING_TESTS)

    for i in {test, lint, format}:
        i.add_argument("files", nargs="*")

    for i in {synthesize, run, compile, preprocess, ckl}:
        i.add_argument("file")

    for i in {compile, preprocess, ckl}:
        i.add_argument("-o", "--out", required=True)

    run.add_argument("--no-vpi", action="store_true", dest="no_vpi")
    compile.add_argument("-t", "--type")
    compile.add_argument("-p", "--target-flag", nargs="*", dest="target_flags")
    test.add_argument("-r", "--reporter")
    lint.add_argument("--no-verilator", action="store_true", dest="no_verilator")
    lint.add_argument("--no-iverilog", action="store_true", dest="no_iverilog")
    lint.add_argument("--no-verible", action="store_true", dest="no_verible")
    make.add_argument("files", metavar="targets", nargs="*")
    synthesize.add_argument("-o", "--online")
    synthesize.add_argument("-v", "--vscode", action="store_true")
    synthesize.add_argument("-w", "--wait", action="store_true")

    autocomplete(parser)
    return cast(Args, parser.parse_args())


def with_suffix(path: str, ext: str):
    return Path(path).with_suffix("").with_suffix(ext).absolute().as_posix()


def fix_args(args: Args):
    while True:
        match args.action:
            case Action.FORMAT | Action.LINT if not args.files:
                args.files = glob("**/*.sv", recursive=True)

            case Action.TEST if not args.files:
                args.files = glob("test/**/*.sv", recursive=True)

            case _:
                break


sys.tracebacklimit = 0
chdir(Path(__file__).parent)

args = parse_args()
fix_args(args)

match args.action:
    case Action.SYNTHESIZE:
        assert args.file
        file = Path(args.file)

        temp_sv = mktemp(file, ".sv")
        run_iverilog(file, output=temp_sv, preprocess_only=True)
        run_verible_formatter(temp_sv)
        formatFile(temp_sv)

        if args.online:
            with open(temp_sv, "r") as f:
                content = f.read()

            print("> curl")
            run_curl(
                f"{args.online}/api/data",
                method="PUT",
                headers={"Content-Type": "application/json"},
                input=dumps({"": content}).encode(),
            )
            temp_sv.unlink()

            print("\n> xdg-open")
            run_xdg_open(f"{args.online}?data={file.stem}")
        elif args.vscode:
            json = {
                "sources": [
                    {"relpath": temp_sv.name},
                ],
                "options": {
                    "opt": True,
                    "transform": True,
                    "fsm": "yes",
                    "fsmexpand": True,
                },
                "devices": {},
                "connectors": [],
                "subcircuits": {},
            }

            temp_digitaljs = mktemp(file, ".digitaljs")

            with open(temp_digitaljs, "w") as f:
                dump(json, f, separators=(",", ":"))

            if args.wait:
                run_vscode(temp_digitaljs, wait=True)
                temp_sv.unlink()
                temp_digitaljs.unlink()
            else:
                run_vscode(temp_digitaljs)
        else:
            print("Synthesized at:", temp_sv)

    case Action.RUN:
        assert args.file
        file = Path(args.file)

        temp_sv = mktemp(file, "")
        run_iverilog(file, output=temp_sv, no_vpi=bool(args.no_vpi))

        run_vvp(temp_sv)
        temp_sv.unlink()

    case Action.COMPILE:
        assert args.file
        assert args.out
        run_iverilog(
            Path(args.file),
            output=Path(args.out),
            output_format=args.type,
            target_flags=args.target_flags or [],
        )

    case Action.PREPROCESS:
        assert args.file
        assert args.out
        out = Path(args.out)
        run_iverilog(Path(args.file), output=out, preprocess_only=True)
        run_verible_formatter(out)
        formatFile(out)

    case Action.FORMAT:
        assert args.files
        files = [Path(i) for i in args.files]

        exc_aggregator = ExceptionAggregator()

        with exc_aggregator:
            run_verible_formatter(*files)

        for file in files:
            print(">", file)
            with exc_aggregator:
                formatFile(file)

        exc_aggregator.assert_no_errors()

    case Action.LINT:
        assert args.files
        files = [Path(i) for i in args.files if MODULE_PATH_RE.search(i)]

        exc_aggregator = ExceptionAggregator()

        if not args.no_verible:
            with exc_aggregator:
                print("> verible")
                run_verible_syntax(*files)

        for file in files:
            if not args.no_verilator:
                print("> verilator", file)

                with exc_aggregator:
                    temp_sv = mktemp(file, ".sv")
                    try:
                        run_iverilog(file, output=temp_sv, preprocess_only=True)

                        with open(temp_sv, "r") as f:
                            content = f.read()

                        has_wor = " wor " in content
                        content = content.replace("$read_char(", "(0")
                        content = content.replace(" wor ", " tri ")

                        with open(temp_sv, "w") as f:
                            f.write(content)

                        run_verilator(temp_sv, no_multidriven=has_wor)
                    finally:
                        temp_sv.unlink()

            if not args.no_iverilog:
                print("> iverilog", file)

                with exc_aggregator:
                    run_iverilog(file, output_format="null")

        exc_aggregator.assert_no_errors()

    case Action.TEST:
        assert args.files
        tests = TestDirectory(Path("test"), [Path(i).absolute() for i in args.files])

        process = None
        out = None

        if stdout.isatty():
            if args.reporter:
                process = Popen(args.reporter, stdin=PIPE, text=True)
                out = process.stdin
            elif which("tap-mocha-reporter"):
                process = Popen(["tap-mocha-reporter", "dot"], stdin=PIPE, text=True)
                out = process.stdin

        for file in tests.run(mktemp(None, ".vvp")):
            print(file, file=out, flush=True)

        if out:
            out.close()

        if process:
            process.wait()

        assert not tests.is_failed()

    case Action.REMAINING_TESTS:
        tests = glob("test/**/*Test.sv", recursive=True)
        tested_files = {
            "src/" + i.removeprefix("test/").removesuffix("Test.sv") + ".sv"
            for i in tests
        }
        all_files = glob("src/**/*.sv", recursive=True)

        for file in all_files:
            if MODULE_PATH_RE.search(file) and file not in tested_files:
                print(">", file)

    case Action.MAKE:
        run_make(*args.files or [])
        if not args.files:
            run_pnpm("install")

    case Action.CKL:
        assert args.file
        assert args.out
        run_gcc("-E", "-ffreestanding", "-o", args.out, "-x", "c", args.file)
        run_node("ckl/index.js", args.out, args.out)

    case _:
        raise ValueError(f"Unknown action: {args.action}")
