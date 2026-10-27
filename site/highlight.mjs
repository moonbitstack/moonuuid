/**
 * A tiny MoonBit highlighter for the docs. It is deliberately small: it knows
 * comments, strings, numbers, keywords and type names, which is all the prose
 * on this site uses. Tokens are escaped before they reach the page.
 */

const KEYWORDS = new Set([
  "fn", "let", "pub", "priv", "struct", "enum", "suberror", "impl", "extend",
  "trait", "with", "derive", "match", "try", "catch", "raise", "for", "in",
  "if", "else", "guard", "return", "true", "false", "ignore", "type", "using",
  "mut", "const", "self", "Self", "as", "is", "async", "break", "continue",
]);

const ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" };

function esc(text) {
  return text.replace(/[&<>"]/g, (c) => ESCAPES[c]);
}

function span(cls, text) {
  return `<span class="tok-${cls}">${esc(text)}</span>`;
}

function moonbit(src) {
  let out = "";
  let i = 0;
  while (i < src.length) {
    const c = src[i];

    // line comment
    if (c === "/" && src[i + 1] === "/") {
      let j = src.indexOf("\n", i);
      if (j < 0) j = src.length;
      out += span("c", src.slice(i, j));
      i = j;
      continue;
    }

    // string
    if (c === '"') {
      let j = i + 1;
      while (j < src.length) {
        if (src[j] === "\\") {
          j += 2;
          continue;
        }
        if (src[j] === '"') {
          j += 1;
          break;
        }
        j += 1;
      }
      out += span("s", src.slice(i, j));
      i = j;
      continue;
    }

    // number, with MoonBit's integer and float suffixes
    if (c >= "0" && c <= "9") {
      const m = /^(?:0x[0-9A-Fa-f_]+|0b[01_]+|[0-9][0-9_]*(?:\.[0-9_]+)?)(?:UL|L|F|D)?/.exec(
        src.slice(i)
      );
      if (m) {
        out += span("n", m[0]);
        i += m[0].length;
        continue;
      }
    }

    // @package.path
    if (c === "@") {
      const m = /^@[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i));
      if (m) {
        out += span("p", m[0]);
        i += m[0].length;
        continue;
      }
    }

    // identifier
    if (/[A-Za-z_]/.test(c)) {
      const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i));
      const word = m[0];
      const cls = KEYWORDS.has(word) ? "k" : /^[A-Z]/.test(word) ? "t" : null;
      out += cls ? span(cls, word) : esc(word);
      i += word.length;
      continue;
    }

    out += esc(c);
    i += 1;
  }
  return out;
}

function shell(src) {
  return esc(src).replace(/^(moon|git|cd|curl|npm)\b/, '<span class="tok-k">$1</span>');
}

export function highlight(code, lang = "moonbit") {
  if (lang === "shell") return shell(code);
  if (lang === "text") return esc(code);
  return moonbit(code);
}
