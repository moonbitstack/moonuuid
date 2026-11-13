"""Run four implementations of RFC 9562 against each other, in both directions.

Each implementation prints and reads the same tab-separated lines (the format
is documented in src/examples/03-interop/main.mbt):

    make                    label<TAB>identifier, one per identifier it makes
    read <text>...          text<TAB>canonical<TAB>version<TAB>variant<TAB>
                            time<TAB>clock sequence<TAB>node<TAB>hex<TAB>urn

Every identifier any of them makes is then read by all four, and the fields
they report have to agree. Identifiers that carry the same label have to be
the same identifier, so a name-based or field-based version is compared value
for value, not just field for field.

Usage: python3 scripts/check_interop.py [--go-proxy URL]
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GO_DIR = ROOT / "integration" / "go-interop"
RUST_DIR = ROOT / "integration" / "rust-interop"
PY_DIR = ROOT / "integration" / "python-interop"
MOON_PKG = "src/examples/03-interop"

# Spellings every implementation reads, so the parse path is compared too.
SPELLINGS = [
    "c232ab00-9414-11ec-b3c8-9f6bdeced846",
    "C232AB00-9414-11EC-B3C8-9F6BDECED846",
    "c232ab00941411ecb3c89f6bdeced846",
    "{c232ab00-9414-11ec-b3c8-9f6bdeced846}",
    "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
    "00000000-0000-0000-0000-000000000000",
    "ffffffff-ffff-ffff-ffff-ffffffffffff",
]

# Text no implementation should read; each answers `!` in the second column.
REFUSALS = ["", "c232ab00", "not-a-uuid", "c232ab00-9414-11ec-b3c8-9f6bdeced84g"]


def run(command: list[str], cwd: Path) -> list[str]:
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit(
            "failed: %s\n%s%s"
            % (" ".join(command), result.stdout, result.stderr.strip())
        )
    return [line for line in result.stdout.splitlines() if line]


def command_for(name: str) -> tuple[list[str], Path]:
    if name == "moonuuid":
        return ["moon", "run", MOON_PKG, "--target", "native", "--"], ROOT
    if name == "go":
        return ["go", "run", "."], GO_DIR
    if name == "rust":
        return ["cargo", "run", "--quiet", "--"], RUST_DIR
    return [sys.executable, "main.py"], PY_DIR


def ask(name: str, args: list[str]) -> list[str]:
    command, cwd = command_for(name)
    return run(command + args, cwd)


def fields(line: str) -> list[str]:
    """The columns after the echoed text, which is what has to agree."""
    return line.split("\t")[1:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--go-proxy",
        default="",
        help="GOPROXY for this run, for machines that cannot reach proxy.golang.org",
    )
    args = parser.parse_args()
    if args.go_proxy:
        os.environ["GOPROXY"] = args.go_proxy

    names = ["moonuuid", "go", "rust", "python"]
    made = {}
    fresh = {}
    for name in names:
        rows = [line.split("\t") for line in ask(name, ["make"])]
        made[name] = {label: text for label, text in rows}
        rows = [line.split("\t") for line in ask(name, ["now"])]
        fresh[name] = {label: text for label, text in rows}
        print(
            "%-9s makes %d from fixed input and %d from the clock"
            % (name, len(made[name]), len(fresh[name]))
        )

    failures = []
    same = 0
    for name in names[1:]:
        shared = sorted(set(made["moonuuid"]) & set(made[name]))
        for label in shared:
            same += 1
            if made[name][label] != made["moonuuid"][label]:
                failures.append(
                    "label %s: moonuuid %s, %s %s"
                    % (label, made["moonuuid"][label], name, made[name][label])
                )
        print("%-9s shares %d labels with moonuuid" % (name, len(shared)))

    texts = sorted(
        {text for rows in made.values() for text in rows.values()}
        | {text for rows in fresh.values() for text in rows.values()}
    )
    to_read = texts + SPELLINGS + REFUSALS
    read = {name: {line.split("\t")[0]: line for line in ask(name, ["read", *to_read])} for name in names}

    comparisons = 0
    for text in to_read:
        ours = read["moonuuid"].get(text)
        if ours is None:
            failures.append("moonuuid said nothing about %r" % text)
            continue
        for name in names[1:]:
            theirs = read[name].get(text)
            if theirs is None:
                failures.append("%s said nothing about %r" % (name, text))
                continue
            comparisons += 1
            if fields(theirs) != fields(ours):
                failures.append(
                    "%r: moonuuid %s, %s %s" % (text, fields(ours), name, fields(theirs))
                )

    for text in REFUSALS:
        for name in names:
            if fields(read[name][text]) != ["!"]:
                failures.append("%s read %r instead of refusing it" % (name, text))

    for failure in failures:
        print("FAIL " + failure)
    print(
        "%d identifiers compared value for value, %d texts, %d field comparisons, %d differences"
        % (same, len(to_read), comparisons, len(failures))
    )
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
