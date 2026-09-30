#!/usr/bin/env python3
"""Build the proved-only manuscript and the frontier report from a Lean-checked card graph.

    card-graph <package-root> --library <Prefix> --lean > graph.json
    proved_manuscript.py --graph graph.json --cards <package-root>/cards \
        --manuscript <manuscript>/main.tex --out <dir> [--check]

Writes PROVED_MANUSCRIPT.tex and FRONTIER.md into --out. The output is a function of the graph,
the cards and the manuscript source only (no timestamps, no absolute paths). The script does not
judge proofs: a statement counts as proved exactly when the graph, checked by Lean, says so.

Exit codes: 0 ok; 1 input problem or stale output (--check); 2 the graph was not Lean-checked.
"""
import argparse
import functools
import glob
import json
import os
import re
import sys
import unicodedata

import yaml

TEX_NAME = "PROVED_MANUSCRIPT.tex"
FRONTIER_NAME = "FRONTIER.md"
ENVS = ("theorem", "lemma", "proposition", "corollary", "definition")
INPUT_RE = re.compile(r"\\input\{([^}]+)\}")
SETTLED_SHAPES = {"defined"}


class InputError(Exception):
    pass


# ---------------------------------------------------------------- reading inputs
def load_graph(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_cards(cards_dir):
    cards = {}
    for path in sorted(glob.glob(os.path.join(cards_dir, "*.yaml"))):
        with open(path, encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        if "id" in data:
            cards[data["id"]] = data
    return cards


@functools.lru_cache(maxsize=8)
def mask_comments(text):
    """`text` with every TeX comment blanked out, offsets preserved (an escaped percent is not one)."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "\\":
            out.append(text[i:i + 2])
            i += 2
        elif c == "%":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def read_manuscript(main_path):
    """Return (preamble, flattened text): \\input files are inlined, comments are not commands."""
    base = os.path.dirname(main_path)

    def inline(text, seen):
        out, last = [], 0
        for m in INPUT_RE.finditer(mask_comments(text)):
            name = m.group(1)
            path = os.path.join(base, name if name.endswith(".tex") else name + ".tex")
            out.append(text[last:m.start()])
            if path in seen:
                raise InputError("circular \\input of " + name)
            if not os.path.exists(path):
                raise InputError("input file not found: " + name)
            with open(path, encoding="utf-8") as f:
                out.append(inline(f.read(), seen | {path}))
            last = m.end()
        out.append(text[last:])
        return "".join(out)

    with open(main_path, encoding="utf-8") as f:
        flat = inline(f.read(), {main_path})
    cut = mask_comments(flat).find("\\begin{document}")
    if cut < 0:
        raise InputError("no \\begin{document} in the manuscript")
    return flat[:cut], flat


def label_position(flat, label):
    m = re.search(r"\\label\{" + re.escape(label) + r"\}", mask_comments(flat))
    return m.start() if m else None


def extract_statement(flat, label):
    """The theorem-like environment that holds \\label{label}, cut before any proof; None if absent."""
    pos = label_position(flat, label)
    if pos is None:
        return None
    masked = mask_comments(flat)
    for m in reversed(list(re.finditer(r"\\begin\{(" + "|".join(ENVS) + r")\*?\}", masked[:pos]))):
        tok = re.compile(r"\\(begin|end)\{" + m.group(1) + r"\*?\}")
        depth = 0
        for t in tok.finditer(masked, m.start()):
            depth += 1 if t.group(1) == "begin" else -1
            if depth == 0:
                if t.end() > pos:
                    cut = masked.find("\\begin{proof}", m.start(), t.end())
                    if cut < 0:
                        return flat[m.start():t.end()]
                    # a proof nested inside the environment: drop it and close the environment again
                    return flat[m.start():cut].rstrip() + "\n\\end{" + m.group(0)[len("\\begin{"):]
                break
    return None


# ---------------------------------------------------------------- the selection
def check_edges(nodes, edges):
    for e in edges:
        unknown = [x for x in [e["conclusion"], *e["premises"]] if x not in nodes]
        if unknown:
            raise InputError("edge %s names cards that are not in the graph: %s"
                             % (e.get("proof_module", "?"), ", ".join(sorted(set(unknown)))))


def detect_cycle(nodes, edges):
    # card-graph itself refuses a cyclic graph, so this only guards against hand-made input.
    graph = {}
    for e in edges:
        graph.setdefault(e["conclusion"], set()).update(e["premises"])
    state = {}

    def visit(n, path):
        state[n] = 1
        for p in sorted(graph.get(n, ())):
            if state.get(p) == 1:
                return path + [n, p]
            if p not in state:
                found = visit(p, path + [n])
                if found:
                    return found
        state[n] = 2
        return None

    for n in sorted(graph):
        if n not in state:
            found = visit(n, [])
            if found:
                return found
    return None


def select(graph):
    nodes = {n["id"]: n for n in graph["nodes"]}
    check_edges(nodes, graph["edges"])
    by_conclusion = {}
    for e in graph["edges"]:
        by_conclusion.setdefault(e["conclusion"], []).append(e)
    proved = sorted(i for i, n in nodes.items() if n["shape"] == "theorem" and n["status"] == "proved")
    included, chosen = set(), {}

    def unsettled(e):
        return [p for p in e["premises"] if not (nodes[p]["status"] in SETTLED_SHAPES or p in included)]

    changed = True
    while changed:                       # a premise theorem must itself be included
        changed = False
        for i in proved:
            if i in included:
                continue
            for e in sorted(by_conclusion.get(i, []), key=lambda e: e["proof_module"]):
                if not unsettled(e):
                    included.add(i)
                    chosen[i] = e
                    changed = True
                    break
    held = {}
    for i in proved:
        if i in included:
            continue
        options = by_conclusion.get(i, [])
        if not options:
            held[i] = ["(no proof module recorded)"]
            continue
        best = min(options, key=lambda e: (len(unsettled(e)), e["proof_module"]))
        held[i] = [nodes[p]["title"] for p in unsettled(best)]
    return nodes, by_conclusion, sorted(included), chosen, held, proved


def order(included, chosen, cards, flat):
    def key(i):
        block = ((cards[i].get("expressions") or {}).get("manuscript") or {}).get("block")
        pos = label_position(flat, block) if block else None
        return (pos if pos is not None else len(flat) + 1, i)

    remaining = set(included)
    out = []
    while remaining:
        ready = [i for i in remaining
                 if not any(p in remaining for p in chosen[i]["premises"] if p != i)]
        if not ready:
            raise InputError("dependency cycle among " + ", ".join(sorted(remaining)))
        nxt = min(ready, key=key)
        out.append(nxt)
        remaining.remove(nxt)
    return out


# ---------------------------------------------------------------- writing
# Symbols that common text fonts lack (they print as a missing-glyph box) are set in math mode.
# Bold letters stand in for blackboard bold so that no extra package is needed.
_MATH = {"\U0001D7D9": r"\mathbf{1}", "\u2ab0": r"\succeq", "\u2aaf": r"\preceq",
         "\u1d40": r"^{\mathsf{T}}", "\u207a": "^{+}", "\u207b": "^{-}",
         "\u00b9": "^{1}", "\u00b2": "^{2}", "\u00b3": "^{3}"}
_MATH.update({chr(0x2070 + d): "^{%d}" % d for d in (0, 4, 5, 6, 7, 8, 9)})       # superscript digits
_MATH.update({chr(0x2080 + d): "_{%d}" % d for d in range(10)})                     # subscript digits
_DIGITS = {"ZERO": "0", "ONE": "1", "TWO": "2", "THREE": "3", "FOUR": "4",
           "FIVE": "5", "SIX": "6", "SEVEN": "7", "EIGHT": "8", "NINE": "9"}


def _double_struck(c):
    """The bold letter or digit for a double-struck character, or None."""
    if ord(c) < 0x2100:
        return None
    name = unicodedata.name(c, "")
    if "DOUBLE-STRUCK" not in name:
        return None
    last = name.split()[-1]
    if " CAPITAL " in name and len(last) == 1:
        return last
    if " SMALL " in name and len(last) == 1:
        return last.lower()
    return _DIGITS.get(last)


def tex_escape(s):
    table = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$", "#": r"\#",
             "_": r"\_", "{": r"\{", "}": r"\}", "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}
    table.update({c: "$" + m + "$" for c, m in _MATH.items()})
    out = []
    for c in s:
        if c in table:
            out.append(table[c])
        elif _double_struck(c):
            out.append(r"$\mathbf{%s}$" % _double_struck(c))
        else:
            out.append(c)
    return "".join(out)


# hyperref redefines \ref when the document begins, so the wrapper is installed after it, by the
# same hook. A reference to a label that is not in this document prints the label itself; the
# starred form of \ref keeps working.
REF_FIX = (r"\makeatletter" "\n"
           r"\providecommand{\href}[2]{#2}" "\n"
           r"\AtBeginDocument{\let\pmOrigRef\ref" "\n"
           r"  \def\pmRefStar#1{\@ifundefined{r@#1}{\texttt{\detokenize{#1}}}{\pmOrigRef*{#1}}}" "\n"
           r"  \def\pmRefPlain#1{\@ifundefined{r@#1}{\texttt{\detokenize{#1}}}{\pmOrigRef{#1}}}" "\n"
           r"  \renewcommand{\ref}{\@ifstar\pmRefStar\pmRefPlain}}" "\n"
           r"\makeatother" "\n")


def summary_sentence(included, proved, total, tex_name=None):
    if included == proved:
        return f"{included} of {total} theorem cards are proved in Lean and appear here."
    return (f"{proved} of {total} theorem cards are proved in Lean; {included} of them appear here "
            "and the others are held back.")


def render_tex(preamble, ordered, nodes, cards, flat, chosen, total_theorems, proved_count):
    def block_of(i):
        return ((cards[i].get("expressions") or {}).get("manuscript") or {}).get("block") or ""

    def provenance(i):
        return (f"Lean: \\texttt{{{tex_escape(nodes[i].get('lean_name', ''))}}}; "
                f"card: \\texttt{{{tex_escape(i)}}}; manuscript label: \\texttt{{{tex_escape(block_of(i))}}}.")

    defs = []
    for i in ordered:
        for p in chosen[i]["premises"]:
            if nodes[p]["shape"] == "definition" and p not in defs:
                defs.append(p)

    def defkey(p):
        pos = label_position(flat, block_of(p))
        return (pos if pos is not None else len(flat) + 1, p)

    defs.sort(key=defkey)
    parts = [preamble.rstrip("\n") + "\n", REF_FIX,
             "\\title{Propositions proved in Lean}\n\\date{}\n\\begin{document}\n\\maketitle\n"
             "\\noindent " + summary_sentence(len(ordered), proved_count, total_theorems) + " "
             f"The rest of the proof work is in \\href{{run:{FRONTIER_NAME}}}{{\\texttt{{{FRONTIER_NAME}}}}}. "
             "Theorem and reference numbers are those of this document, not of the manuscript; "
             "each entry gives its manuscript label.\n"]
    if defs:
        parts.append("\n\\section*{Definitions used}\n")
        for p in defs:
            parts.append(f"\\paragraph{{{tex_escape(nodes[p]['title'])}}} {provenance(p)} "
                         f"{tex_escape(str(cards[p].get('natural', '')).strip())}\n")
    for i in ordered:
        block = block_of(i)
        parts.append(f"\n\\section{{{tex_escape(nodes[i]['title'])}}}\n\\noindent {provenance(i)}\n\n")
        stmt = extract_statement(flat, block) if block else None
        if stmt is None:
            parts.append("\\begin{quote}\n" + tex_escape(str(cards[i].get("natural", "")).strip()) + "\n\\end{quote}\n"
                         "\\noindent\\textit{(statement from card text; the manuscript environment was not found)}\n")
        else:
            parts.append(stmt.rstrip("\n") + "\n")
    parts.append("\n\\end{document}\n")
    return "".join(parts)


def render_frontier(nodes, by_conclusion, graph, ordered, held, total_theorems, proved_count, flat, cards):
    def pos(i):
        block = ((cards.get(i, {}).get("expressions") or {}).get("manuscript") or {}).get("block")
        p = label_position(flat, block) if block else None
        return (p if p is not None else len(flat) + 1, i)

    def line(i, extra=""):
        n = nodes[i]
        name = f", `{n['lean_name']}`" if n.get("lean_name") else ""
        return f"- {n['title']} (card `{i}`{name}){extra}"

    frontier = set(graph.get("frontier", []))
    open_ids = sorted((i for i, n in nodes.items() if n["shape"] == "theorem" and n["status"] == "open"), key=pos)
    unstated = sorted((i for i, n in nodes.items() if n["shape"] == "theorem" and n["status"] == "unformalized"), key=pos)
    out = ["# Frontier of the Lean proofs", "",
           summary_sentence(len(ordered), proved_count, total_theorems).replace("appear here", f"appear in `{TEX_NAME}`")
           + " The lists below are what remains, in two layers, plus proved cards that are held back.", "",
           "## Stated in Lean, not yet proved", ""]
    if any(i in frontier and not by_conclusion.get(i) for i in open_ids):
        out += ["Note: the frontier over-reports while proof edges are absent. A card with no proof module counts as "
                "ready, so this list is not yet an ordering of what to prove next.", ""]
    out += [line(i, " (on the frontier)" if i in frontier else "") for i in open_ids] or ["(none)"]
    out += ["", "## Not yet stated in Lean", ""]
    out += [line(i) for i in unstated] or ["(none)"]
    out += ["", "## Proved but held back", ""]
    out += [line(i, " (waiting for: " + ", ".join(held[i]) + ")") for i in sorted(held, key=pos)] or ["(none)"]
    return "\n".join(out) + "\n"


def build(graph, cards, main_path):
    preamble, flat = read_manuscript(main_path)
    nodes, by_conclusion, included, chosen, held, proved = select(graph)
    missing = sorted(i for i in nodes if i not in cards)
    if missing:
        raise InputError("card file missing for: " + ", ".join(missing))
    cycle = detect_cycle(nodes, graph["edges"])
    if cycle:
        raise InputError("dependency cycle: " + " -> ".join(cycle))
    ordered = order(included, chosen, cards, flat)
    total = sum(1 for n in nodes.values() if n["shape"] == "theorem")
    files = {TEX_NAME: render_tex(preamble, ordered, nodes, cards, flat, chosen, total, len(proved)),
             FRONTIER_NAME: render_frontier(nodes, by_conclusion, graph, ordered, held, total, len(proved), flat, cards)}
    return files, len(ordered), len(proved), total


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--graph", required=True)
    ap.add_argument("--cards", required=True)
    ap.add_argument("--manuscript", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args(argv)
    graph = load_graph(args.graph)
    if graph.get("check") != "lean":
        print("error: the graph is not Lean-checked (check = %r); produce it with `card-graph --lean` "
              "(card-graph <root> --library <Prefix> --lean)." % graph.get("check"), file=sys.stderr)
        return 2
    try:
        files, included, proved, total = build(graph, load_cards(args.cards), args.manuscript)
    except InputError as e:
        print("error: " + str(e), file=sys.stderr)
        return 1
    if args.check:
        stale = [name for name, text in files.items()
                 if not os.path.exists(os.path.join(args.out, name))
                 or open(os.path.join(args.out, name), encoding="utf-8").read() != text]
        for name in stale:
            print("stale: " + name, file=sys.stderr)
        return 1 if stale else 0
    os.makedirs(args.out, exist_ok=True)
    for name, text in files.items():
        with open(os.path.join(args.out, name), "w", encoding="utf-8") as f:
            f.write(text)
    print(f"{included} of {total} theorem cards included ({proved} proved)")
    print(os.path.join(args.out, TEX_NAME))
    print(os.path.join(args.out, FRONTIER_NAME))
    return 0


if __name__ == "__main__":
    sys.exit(main())
