#!/usr/bin/env python3
"""Render the body of the API reference from the package interface.

The public surface comes from src/pkg.generated.mbti. The prose comes from the
`///` comments in src/*.mbt. Everything is sorted, so two runs on the same
sources produce byte-identical output; CI relies on that.

What lands in site/content/api-body.mjs is markup only: the page shell, the
navigation and the footer come from the same pug templates the other pages use,
so the reference cannot drift away from them.
"""

from __future__ import annotations

import html
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src"
MBTI = SRC / "pkg.generated.mbti"
OUT = REPO / "site" / "content" / "api-body.mjs"
SOURCES = [SRC / "uuid.mbt", SRC / "generator.mbt", SRC / "make.mbt"]

TRAIT_OF = {
    "equal": "Eq",
    "not_equal": "Eq",
    "compare": "Compare",
    "op_lt": "Compare",
    "op_le": "Compare",
    "op_ge": "Compare",
    "op_gt": "Compare",
    "hash": "Hash",
    "hash_combine": "Hash",
    "to_repr": "Debug",
    "output": "Show",
    "to_string": "Show",
    "to_json": "ToJson",
    "from_json": "FromJson",
}


# --------------------------------------------------------------------------
# text helpers
# --------------------------------------------------------------------------

def js_string(value: str) -> str:
    """A JS string literal holding `value`, newlines and all."""
    return json.dumps(value, ensure_ascii=False)


def esc(value: str) -> str:
    return html.escape(value, quote=True)


def inline(text: str) -> str:
    """Escape, then turn `backticked` runs into code elements."""
    pieces = esc(text).split("`")
    out = []
    for index, piece in enumerate(pieces):
        out.append(f"<code>{piece}</code>" if index % 2 else piece)
    return "".join(out)


def render_doc(lines: list[str]) -> str:
    text = " ".join(line.strip() for line in lines).strip()
    if not text:
        return ""
    return f"<p>{inline(text)}</p>"


def plain_doc(lines: list[str]) -> str:
    return re.sub(r"\s+", " ", " ".join(lines)).replace("`", "").strip()


def attr(text: str) -> str:
    return esc(re.sub(r"\s+", " ", text).strip())


# --------------------------------------------------------------------------
# signature parsing
# --------------------------------------------------------------------------

def parse_fn(body: str) -> tuple[str, str, str]:
    """Split `NAME(params) -> ret` (the part after `fn `)."""
    body = body.strip()
    name, rest = body.split("(", 1)
    depth = 1
    index = 0
    while index < len(rest) and depth > 0:
        char = rest[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        index += 1
    params = rest[: index - 1].strip().rstrip(",")
    after = rest[index:].strip()
    ret = after[2:].strip() if after.startswith("->") else ""
    return name.strip(), params, ret


def collect_decl(lines: list[str], start: int) -> tuple[str, int]:
    """Join a declaration up to its opening brace (or the end of the line)."""
    first = lines[start].strip()
    buffer = first
    consumed = 1
    if not (first.startswith("pub let") and "{" not in first):
        while "{" not in buffer and start + consumed < len(lines):
            buffer += " " + lines[start + consumed].strip()
            consumed += 1
    if "{" in buffer:
        buffer = buffer.split("{", 1)[0]
    if buffer.strip().startswith("pub let") and "=" in buffer:
        buffer = buffer.split("=", 1)[0]
    buffer = re.sub(r"\s+", " ", buffer).strip()
    return buffer, consumed


def classify(decl: str):
    text = decl.strip()
    if text.startswith("pub(all) "):
        text = text[len("pub(all) "):]
    elif text.startswith("pub "):
        text = text[len("pub "):]

    if text.startswith("struct "):
        name = text.split()[1]
        return "struct", name, f"struct {name}"
    if text.startswith("enum "):
        name = text.split()[1]
        return "enum", name, f"enum {name}"
    if text.startswith("suberror "):
        name = text.split()[1]
        return "suberror", name, f"suberror {name}"
    if text.startswith("let "):
        match = re.match(r"let (\w+)\s*:\s*(.+)", text)
        if match:
            return "let", match.group(1), f"let {match.group(1)} : {match.group(2).strip()}"
    if text.startswith("impl "):
        match = re.match(r"impl (.+?)(?: with |$)", text)
        if match:
            trait_for = match.group(1).strip().replace("@json.", "")
            return "impl", "impl:" + trait_for, "impl " + trait_for
    if text.startswith("fn "):
        name, params, ret = parse_fn(text[len("fn "):])
        sig = f"fn {name}({params})"
        if ret:
            sig += f" -> {ret}"
        return "fn", name, sig
    return None, None, None


# --------------------------------------------------------------------------
# sources: docs, constructor docs, signatures
# --------------------------------------------------------------------------

def parse_sources(paths: list[Path]):
    docs: dict[str, list[str]] = {}
    ctors: dict[str, list[str]] = {}
    sigs: dict[str, str] = {}

    for path in paths:
        lines = path.read_text(encoding="utf-8").splitlines()
        pending: list[str] = []
        i = 0
        while i < len(lines):
            stripped = lines[i].strip()

            if stripped == "///|":
                pending = []
                i += 1
                continue
            if stripped.startswith("///"):
                text = stripped[3:]
                if text.startswith(" "):
                    text = text[1:]
                pending.append(text)
                i += 1
                continue
            if not stripped:
                i += 1
                continue

            if stripped.startswith("pub ") or stripped.startswith("pub(all) "):
                decl, consumed = collect_decl(lines, i)
                kind, key, sig = classify(decl)
                if key:
                    if pending:
                        docs[key] = pending
                    if sig:
                        sigs[key] = sig

                if kind in ("struct", "enum", "suberror"):
                    body_start = i + consumed
                    end = body_start
                    while end < len(lines) and not lines[end].strip().startswith("}"):
                        end += 1
                    if kind in ("enum", "suberror") and key:
                        parse_ctor_docs(lines, body_start, end, key, ctors)
                    i = end + 1
                    pending = []
                    continue

                pending = []
                i += consumed
                continue

            pending = []
            i += 1

    return docs, ctors, sigs


def parse_ctor_docs(lines: list[str], start: int, end: int, typename: str, out: dict[str, list[str]]) -> None:
    pending: list[str] = []
    i = start
    while i < end:
        stripped = lines[i].strip()
        if stripped == "///|":
            pending = []
        elif stripped.startswith("///"):
            text = stripped[3:]
            if text.startswith(" "):
                text = text[1:]
            pending.append(text)
        elif stripped:
            match = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", stripped)
            if match:
                out[f"{typename}::{match.group(1)}"] = pending
            pending = []
        i += 1


# --------------------------------------------------------------------------
# interface
# --------------------------------------------------------------------------

def parse_mbti(text: str):
    values = []
    functions = []
    types = []
    by_name = {}

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("}") or stripped.startswith("package") or stripped.startswith("import"):
            i += 1
            continue

        match = re.match(r"pub(?:\(all\))? (struct|enum|suberror) (\w+)", stripped)
        if match:
            kind, name = match.group(1), match.group(2)
            item = {"kind": kind, "name": name, "ctors": [], "methods": [], "impls": []}
            types.append(item)
            by_name[name] = item
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("}"):
                body = lines[i].strip()
                if body and not body.startswith("//"):
                    ctor = re.match(r"(\w+)(.*)", body)
                    if ctor:
                        item["ctors"].append({"name": ctor.group(1), "sig": body})
                i += 1
            i += 1
            continue

        match = re.match(r"pub let (\w+) : (.+)", stripped)
        if match:
            values.append({"name": match.group(1), "sig": f"let {match.group(1)} : {match.group(2).strip()}"})
            i += 1
            continue

        if stripped.startswith("pub fn "):
            name, params, ret = parse_fn(stripped[len("pub fn "):])
            sig = f"fn {name}({params})"
            if ret:
                sig += f" -> {ret}"
            if "::" in name:
                typename, method = name.split("::", 1)
                owner = by_name.get(typename)
                if owner is not None:
                    owner["methods"].append({"name": method, "key": name, "sig": sig})
                else:
                    functions.append({"name": name, "sig": sig})
            else:
                functions.append({"name": name, "sig": sig})
            i += 1
            continue

        match = re.match(r"pub impl (.+) for (\w+)", stripped)
        if match:
            trait = match.group(1).strip().replace("@json.", "")
            owner = by_name.get(match.group(2))
            if owner is not None and trait not in owner["impls"]:
                owner["impls"].append(trait)
            i += 1
            continue

        i += 1

    return values, functions, types


# --------------------------------------------------------------------------
# rendering
# --------------------------------------------------------------------------

def method_doc(owner, method, docs, impl_docs) -> str:
    doc = render_doc(docs.get(method["key"], []))
    if doc:
        return doc
    trait = TRAIT_OF.get(method["name"])
    if not trait:
        return ""
    impl_doc = render_doc(impl_docs.get(f"impl:{trait} for {owner['name']}", []))
    if impl_doc:
        return impl_doc
    return f"<p>From <code>{esc(trait)}</code>.</p>"


def ctors_html(owner, ctor_docs) -> str:
    if not owner["ctors"]:
        return ""
    items = []
    for ctor in owner["ctors"]:
        args = ctor["sig"][len(ctor["name"]):]
        doc_lines = ctor_docs.get(f"{owner['name']}::{ctor['name']}", [])
        doc = inline(plain_doc(doc_lines))
        tail = f"<span>{doc}</span>" if doc else ""
        items.append(
            f'<li><b>{esc(ctor["name"])}</b>{esc(args)} {tail}</li>'
        )
    return '<ul class="constructors">' + "".join(items) + "</ul>"


def entry(kind_label: str, name: str, sig: str, doc_lines: list[str], extra: str = "") -> str:
    doc = render_doc(doc_lines)
    text = attr(f"{name} {sig} {plain_doc(doc_lines)}")
    return (
        f'<article class="api-entry" id="{esc(name)}" data-name="{esc(name)}" data-text="{text}">'
        f'<div class="api-entry__head">'
        f'<span class="api-entry__name">{esc(name)}</span>'
        f'<span class="api-entry__kind">{esc(kind_label)}</span>'
        f'<span class="api-entry__sig">{esc(sig)}</span>'
        f"</div>"
        f'<div class="api-entry__doc">{doc}</div>'
        f"{extra}"
        f"</article>"
    )


def type_entry(owner, docs, ctor_docs, sigs, impl_docs) -> str:
    methods = sorted(owner["methods"], key=lambda m: m["name"].lower())
    members = []
    for method in methods:
        sig = sigs.get(method["key"], method["sig"])
        doc = method_doc(owner, method, docs, impl_docs)
        anchor = f"{owner['name']}.{method['name']}"
        text = attr(f"{method['name']} {sig} {plain_doc(docs.get(method['key'], []))}")
        members.append(
            f'<div class="member" id="{esc(anchor)}" data-text="{text}">'
            f'<div class="member__sig">{esc(sig)}</div>'
            f'<div class="member__doc">{doc}</div>'
            f"</div>"
        )

    extra = ctors_html(owner, ctor_docs)
    if members:
        extra += '<div class="members">' + "".join(members) + "</div>"
    if owner["impls"]:
        badges = "".join(f"<code>{esc(t)}</code>" for t in sorted(owner["impls"]))
        extra += f'<p class="impl-line"><span class="api-entry__kind">implements</span>{badges}</p>'

    sig = sigs.get(owner["name"], f"{owner['kind']} {owner['name']}")
    return entry(owner["kind"], owner["name"], sig, docs.get(owner["name"], []), extra)


def group_html(anchor: str, title: str, lead: str, body: str) -> str:
    return (
        f'<section class="api-group" id="{anchor}">'
        f"<h2>{esc(title)}</h2><p>{inline(lead)}</p>"
        f"{body}</section>"
    )


# --------------------------------------------------------------------------
# shell (mirrors the pug partials)
# --------------------------------------------------------------------------

FILTER = """(function () {
  var input = document.getElementById("api-filter");
  if (!input) return;
  var entries = Array.prototype.slice.call(document.querySelectorAll(".api-entry"));
  var groups = Array.prototype.slice.call(document.querySelectorAll(".api-group"));
  var empty = document.getElementById("api-empty");
  function run() {
    var query = input.value.trim().toLowerCase();
    var shown = 0;
    entries.forEach(function (entry) {
      var own = !query || (entry.getAttribute("data-text") || "").toLowerCase().indexOf(query) !== -1;
      var members = Array.prototype.slice.call(entry.querySelectorAll(".member"));
      var memberHit = false;
      members.forEach(function (member) {
        var hit = !query || (member.getAttribute("data-text") || "").toLowerCase().indexOf(query) !== -1;
        member.style.display = (own || hit) ? "" : "none";
        if (hit) memberHit = true;
      });
      var show = own || memberHit;
      entry.style.display = show ? "" : "none";
      if (show) shown += 1;
    });
    groups.forEach(function (group) {
      var any = Array.prototype.slice.call(group.querySelectorAll(".api-entry")).some(function (entry) {
        return entry.style.display !== "none";
      });
      group.style.display = any ? "" : "none";
    });
    if (empty) empty.style.display = shown ? "none" : "block";
  }
  input.addEventListener("input", run);
})();"""


def sidebar(values, functions, types, errors) -> str:
    parts = ['<nav class="api-nav">']

    def simple(title, items):
        links = "".join(f'<a href="#{esc(name)}">{esc(name)}</a>' for name in items)
        return f'<div class="api-nav__group"><div class="api-nav__title">{esc(title)}</div>{links}</div>'

    def with_methods(title, owners):
        chunks = [f'<div class="api-nav__group"><div class="api-nav__title">{esc(title)}</div>']
        for owner in owners:
            chunks.append(f'<a href="#{esc(owner["name"])}">{esc(owner["name"])}</a>')
            for method in sorted(owner["methods"], key=lambda m: m["name"].lower()):
                anchor = f"{owner['name']}.{method['name']}"
                chunks.append(f'<a class="sub" href="#{esc(anchor)}">{esc(method["name"])}</a>')
        chunks.append("</div>")
        return "".join(chunks)

    parts.append(simple("Values", [v["name"] for v in values]))
    parts.append(simple("Functions", [f["name"] for f in functions]))
    parts.append(with_methods("Types", types))
    parts.append(with_methods("Errors", errors))
    parts.append("</nav>")
    return "".join(parts)


def main() -> None:
    docs, ctor_docs, sigs = parse_sources(SOURCES)
    values, functions, types_all = parse_mbti(MBTI.read_text(encoding="utf-8"))

    for item in values:
        item["doc"] = docs.get(item["name"], [])
    for item in functions:
        item["doc"] = docs.get(item["name"], [])
        item["sig"] = sigs.get(item["name"], item["sig"])
    for owner in types_all:
        for method in owner["methods"]:
            method["doc"] = docs.get(method["key"], [])

    values.sort(key=lambda v: v["name"].lower())
    functions.sort(key=lambda f: f["name"].lower())
    types = sorted([t for t in types_all if t["kind"] != "suberror"], key=lambda t: t["name"].lower())
    errors = sorted([t for t in types_all if t["kind"] == "suberror"], key=lambda t: t["name"].lower())
    impl_docs = {key: value for key, value in docs.items() if key.startswith("impl:")}

    value_entries = "".join(entry("value", v["name"], v["sig"], v["doc"]) for v in values)
    function_entries = "".join(
        entry("function", f["name"], f["sig"], f["doc"]) for f in functions
    )
    type_entries = "".join(type_entry(t, docs, ctor_docs, sigs, impl_docs) for t in types)
    error_entries = "".join(type_entry(t, docs, ctor_docs, sigs, impl_docs) for t in errors)

    content = (
        '<div class="shell">'
        '<header class="page-head">'
        '<p class="kicker">reference · one package</p>'
        "<h1>API reference</h1>"
        '<p class="lead">Every public value, function, type and method in '
        "<code>moonbitstack/moonuuid</code>. Signatures are the package interface; "
        "the notes are the doc comments.</p>"
        "</header>"
        '<div class="api-layout">'
        '<aside class="api-side">'
        '<input id="api-filter" class="api-filter" type="search" placeholder="Filter the API…" aria-label="Filter the API">'
        + sidebar(values, functions, types, errors)
        + "</aside>"
        '<div class="api-body">'
        '<div id="api-empty" class="api-empty">Nothing matches that filter.</div>'
        + group_html(
            "group-values",
            "Values",
            "Constants the package exports: the nil and max identifiers, the four namespaces, and the offset between the Gregorian and Unix epochs.",
            value_entries,
        )
        + group_html(
            "group-functions",
            "Functions",
            "Free functions that read text or make one version each.",
            function_entries,
        )
        + group_html(
            "group-types",
            "Types",
            "The identifier and the generator, with the methods that read or write them.",
            type_entries,
        )
        + group_html(
            "group-errors",
            "Errors",
            "The refusal that a parse or a byte-count check raises.",
            error_entries,
        )
        + "</div></div></div>"
    )

    module = (
        "// Generated by scripts/gen_api.py from src/. Do not edit.\n"
        "export const body = "
        + js_string(content)
        + ";\n\nexport const filter = "
        + js_string(FILTER)
        + ";\n"
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(module)

    print(f"api   <- {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
