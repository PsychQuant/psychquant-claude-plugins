"""Read skill frontmatter the way Claude Code reads it — or refuse to.

Shared by tests/che-archive-lines/test-plugin-layout.sh and
tests/che-telegram-mcp/test-plugin-layout.sh (#138, #139).

The layout tests parse frontmatter with PyYAML (YAML 1.1). Claude Code parses it
with Bun.YAML (YAML 1.2), and when that first parse fails it rewrites the block
(quoting values that contain `: `, `#`, `!`, `*`, …) and parses again. The two
readers disagree on more than the YAML version suggests. Found in #139 verify
rounds 1–4 and in the fuzz run below:

  - Python's \\s also matches NEL and \\x1c-\\x1f; JavaScript's does not.
  - PyYAML treats NEL, U+2028 and U+2029 as line breaks; Bun rejects the block,
    and Claude Code's rewrite then drops either the whole block or, in an LF
    file, only the key after the NEL (disable-model-invocation, say).
  - A quoted scalar left open on its line: PyYAML joins the next lines into
    it; Bun rejects the block, and Claude Code's rewrite can then read the
    following lines as keys (e.g. disable-model-invocation: false) while the
    test still sees one long description.
  - Bun treats `---` and `...` as document markers even inside a value
    (`description: x ...` reads as `x`).

So a test may only trust PyYAML on frontmatter inside a plain subset where both
agree and Bun's first parse succeeds. subset_problems() returns why a block is
outside it; an empty list means inside. The subset:

  - no tab, other control character, NEL, U+2028, U+2029 or BOM; no lone CR
  - no `---` and no `...` anywhere
  - every line is one of: `key:` | `key: value` | `<spaces>- value` |
    `# comment` | blank, optionally ending in CR (CRLF files)
  - a value is a double-quoted string closed on the same line with no
    backslash, a single-quoted string closed on the same line, or a plain
    scalar that does not start with an indicator or a quote and contains no
    `: ` and no ` #` (a trailing ` # comment` is allowed)
  - list items only under a `key:` with no value, all at one indentation
  - no key twice

Evidence: tests/frontmatter-subset-fuzz/run.sh generates random blocks heavy in
the cases above, keeps those subset_problems() accepts, and compares PyYAML
with Bun.YAML.parse. Two seeds × 50,000 blocks (11,433 accepted) on bun 1.3.11:
Bun's first parse never failed, and structure and string values always agreed.
The only differences left are scalar types (yes/on/1e0 are booleans or strings
depending on the reader); the layout tests compare the values they care about
as exact strings, so a type difference fails a check instead of passing it.
"""
import re

# JavaScript's \s, which Claude Code's frontmatter boundary regex uses.
JS_WS = "[\t\n\v\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]"
# Claude Code's own boundary: lazy, not anchored to a line start.
FM_RE = re.compile("---" + JS_WS + "*\n([\\s\\S]*?)---" + JS_WS + "*\n?")

_BAD = re.compile("[\x00-\x09\x0b\x0c\x0e-\x1f\x7f-\x9f\u2028\u2029\ufeff]|\r(?!\n)")
_KEY = r"[A-Za-z][A-Za-z0-9-]*"
_DQ = r'"[^"\\\r\n]*"'
_SQ = r"'(?:[^'\r\n]|'')*'"
_PLAIN = r"[^\s&*!|>%@`{}\[\],?#\"'-](?:[^\r\n:#]|:(?=[^ \r\n])|(?<=[^ ])#)*"
_COMMENT = r"(?: +#[^\r\n]*)?"
_VALUE = rf"(?:{_DQ}|{_SQ}|{_PLAIN})"
_KEY_ONLY = re.compile(rf"({_KEY}):{_COMMENT} *\r?")
_KEY_VALUE = re.compile(rf"({_KEY}): +{_VALUE} *{_COMMENT} *\r?")
_ITEM = re.compile(rf"( +)- +{_VALUE} *{_COMMENT} *\r?")
_SKIP = re.compile(r" *(?:#[^\r\n]*)?\r?")


def split(text):
    """(block, body) the way Claude Code splits a skill file, or (None, text).
    Read the file with newline="" so a lone CR stays a CR."""
    m = FM_RE.match(text)
    return (m.group(1), text[m.end():]) if m else (None, text)


def subset_problems(block):
    """Why `block` is outside the subset PyYAML and Claude Code read alike."""
    out = []
    if _BAD.search(block):
        out.append("contains a tab, control or line-separator character")
    if "---" in block or "..." in block:
        out.append("contains --- or ... (Bun.YAML treats both as document markers, even inside a value)")
    seen, prev, indent = set(), None, None
    for n, line in enumerate(block.split("\n"), 1):
        m = _KEY_ONLY.fullmatch(line) or _KEY_VALUE.fullmatch(line)
        if m:
            if m.group(1) in seen:
                out.append(f"line {n}: duplicate key {m.group(1)}")
            seen.add(m.group(1))
            prev, indent = ("key-only" if _KEY_ONLY.fullmatch(line) else "key-value"), None
            continue
        m = _ITEM.fullmatch(line)
        if m:
            if prev not in ("key-only", "item"):
                out.append(f"line {n}: list item not under a key without a value")
            elif indent is not None and len(m.group(1)) != indent:
                out.append(f"line {n}: list item indentation changes")
            prev, indent = "item", len(m.group(1))
            continue
        if _SKIP.fullmatch(line):
            continue
        out.append(f"line {n} is outside the plain YAML both parsers read alike: {line.strip()[:60]}")
    return out
