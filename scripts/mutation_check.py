"""Break one decision at a time and check that a test notices.

Each entry below changes a single line of the library to a plausible mistake.
The suite runs; if every test still passes, that decision is not covered and the
run fails. The file is put back byte for byte after every entry.

Usage: python3 scripts/mutation_check.py [--target wasm-gc] [-v]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (what breaks, file, text as it is, text as it would be if the decision were wrong)
MUTATIONS = [
    ("the variant bits are written over", "src/make.mbt", "| 0x8000000000000000UL", "| 0xC000000000000000UL"),
    ("the version bits are written over", "src/make.mbt", "(hi & 0xFFFFFFFFFFFF0FFFUL)", "(hi & 0xFFFFFFFFFFFFFFFFUL)"),
    ("version 1 lays the timestamp out", "src/make.mbt", "((t >> 48) & 0x0FFFUL)", "((t >> 44) & 0x0FFFUL)"),
    ("version 6 puts the high bits first", "src/make.mbt", "(((t >> 12) & 0xFFFFFFFFFFFFUL) << 16)", "(((t >> 16) & 0xFFFFFFFFFFFFUL) << 16)"),
    ("the version 7 counter keeps its top bit clear", "src/make.mbt", "(head & 0x1FFFFFFFFFFUL, tail)", "(head & 0x3FFFFFFFFFFUL, tail)"),
    ("the version 7 counter is split at bit 30", "src/make.mbt", "((counter >> 30) & 0x0FFFUL)", "((counter >> 29) & 0x0FFFUL)"),
    ("the version 7 tail keeps 32 bits", "src/make.mbt", "(counter & 0x3FFFFFFFUL)", "(counter & 0x1FFFFFFFUL)"),
    ("nanoseconds become 100-nanosecond ticks", "src/make.mbt", "unix_nanos / 100L", "unix_nanos / 10L"),
    ("a repeating timestamp moves on", "src/generator.mbt", "Some(prev) if t <= prev => prev + 1L", "Some(prev) if t <= prev => prev"),
    ("a clock that steps back moves on", "src/generator.mbt", "millis = prev + 1L", "millis = prev"),
    ("a counter that runs out moves on", "src/generator.mbt", "counter > 0x3FFFFFFFFFFUL", "counter > 0x7FFFFFFFFFFUL"),
    ("the clock sequence bits are masked", "src/generator.mbt", "(b[0].to_int() << 8)", "(b[0].to_int() << 7)"),
    ("the variant bits are read", "src/uuid.mbt", "(bits & 0b010UL) == 0UL", "(bits & 0b100UL) == 0UL"),
    ("the version is only read for RFC variants", "src/uuid.mbt", "if self.variant() == Rfc {", "if true {"),
    ("version 6's timestamp is put back together", "src/uuid.mbt", "(self.hi >> 32 << 28)", "(self.hi >> 32 << 27)"),
    ("version 7's timestamp is read", "src/uuid.mbt", "Some(7) => self.hi >> 16", "Some(7) => self.hi >> 15"),
    ("the clock sequence is 14 bits", "src/uuid.mbt", "((self.lo >> 48) & 0x3FFFUL)", "((self.lo >> 48) & 0xFFFFUL)"),
    ("the node is 48 bits", "src/uuid.mbt", "(self.lo & 0xFFFFFFFFFFFFUL)", "(self.lo & 0xFFFFFFFFFFFUL)"),
    ("the low half is the second eight bytes", "src/uuid.mbt", "bytes[i + 8]", "bytes[i + 7]"),
    ("writing bytes takes the most significant first", "src/uuid.mbt", "8 * (7 - i % 8)", "8 * (i % 8)"),
    ("more than 32 digits is refused", "src/uuid.mbt", "if digits.length() == 32 {", "if digits.length() == 33 {"),
    ("a refusal points at the character", "src/uuid.mbt", "at=places[at],", "at=at,"),
    ("the little-endian form swaps the fields", "src/uuid.mbt", "be[guid_order[i]]", "be[i]"),
    ("the little-endian form reads the fields back", "src/uuid.mbt", "bytes[guid_order[i]]", "bytes[i]"),
    ("nil is the identifier of zeros", "src/uuid.mbt", "self == nil", "self != nil"),
    ("the name is hashed after the namespace", "src/make.mbt", "let h = @sha1.Hasher::new()\n  h.write(space.bytes())\n  h.write(@utf8.encode(name))", "let h = @sha1.Hasher::new()\n  h.write(@utf8.encode(name))\n  h.write(space.bytes())"),
    ("braces are set aside", "src/uuid.mbt", "while start < end && chars[start] == '{' {", "while start < end && chars[start] == '[' {"),
    ("a short byte string says how long it should be", "src/uuid.mbt", "    raise Size(want=16, got=bytes.length())\n  }\n  of16(bytes)", "    raise Size(want=17, got=bytes.length())\n  }\n  of16(bytes)"),
]

FAILED = re.compile(r'^\[moonbitstack/moonuuid\] test \S+ \("([^"]+)"\) failed', re.M)


def run_tests(target: str) -> tuple[int, list[str], str]:
    result = subprocess.run(
        ["moon", "test", "--target", target],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    output = result.stdout + result.stderr
    return result.returncode, FAILED.findall(output), output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="wasm-gc")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    survived = []
    broke = []
    for index, (what, name, before, after) in enumerate(MUTATIONS, 1):
        path = ROOT / name
        original = path.read_bytes()
        text = original.decode("utf-8")
        if text.count(before) != 1:
            print("%2d  %-55s SKIP: the text appears %d times" % (index, what, text.count(before)))
            survived.append(what)
            continue
        try:
            path.write_bytes(text.replace(before, after, 1).encode("utf-8"))
            code, failed, output = run_tests(args.target)
        finally:
            path.write_bytes(original)
        if "Error:" in output and "failed:" not in output and not failed:
            print("%2d  %-55s DID NOT BUILD" % (index, what))
            broke.append(what)
            continue
        if failed:
            print("%2d  %-55s %d red: %s" % (index, what, len(failed), failed[0]))
            if args.verbose:
                for one in failed:
                    print("       - " + one)
        else:
            print("%2d  %-55s NOTHING WENT RED" % (index, what))
            survived.append(what)

    # The tree has to be exactly as it was.
    dirty = subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"], cwd=ROOT, capture_output=True, text=True).stdout
    print("\n%d mutations, %d seen by a test, %d unseen, %d did not build" % (len(MUTATIONS), len(MUTATIONS) - len(survived) - len(broke), len(survived), len(broke)))
    for what in survived:
        print("unseen: " + what)
    for what in broke:
        print("did not build: " + what)
    if dirty.strip():
        print("the working tree changed during the run:\n" + dirty)
    return 1 if survived or broke else 0


if __name__ == "__main__":
    sys.exit(main())
