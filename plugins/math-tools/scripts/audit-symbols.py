#!/usr/bin/env python3
"""audit-symbols.py — Rule R1 detector: working-file path leak in \\texttt{...}

See .claude/rules/manuscript-consistency-audit.md §9 Pattern 1, 3, 4 for examples.

Usage:
    python3 scripts/audit-symbols.py --manuscript-root manuscript/ [--report-format json|md]

Exit code:
    0 — clean (zero findings)
    1 — at least one finding
    2 — tool error (missing file, IO error)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

# Rule R1 pattern: \texttt{...} containing a file path with code extension
CODE_EXTENSIONS = ("py", "md", "tex", "sh", "rs", "swift", "R", "jl")
TEXTTT_RE = re.compile(
    r"\\texttt\{([^}]+)\}",
    re.MULTILINE,
)
# Anchored path pattern (fix for #50 F-Logic-H1): prevents prose-prefix swallow.
# Old pattern `[\w/.\-\\() ]+\.ext` greedily matched preceding words (e.g.
# "See file foo.py" matched whole phrase including prose).
#
# New pattern: path body has no spaces, optionally followed by ONE parenthesized
# group with leading whitespace (the only legit space-in-filename case, e.g.
# `note (Hsu 2024-02).tex`). For prose like "See file foo.py", the body match
# breaks at the first space — regex restarts and finds just "foo.py".
PATH_WITH_EXT_RE = re.compile(
    r"[\w/.\-\\]+"           # path body (no whitespace)
    r"(?:\s+\([^)]*\))?"     # optional " (extra)" group for filenames with parens
    r"\.(?:" + "|".join(CODE_EXTENSIONS) + r")\b",
)

# White-list: paths that legitimately appear in \texttt{}
# L1 fix: hard-coded "refs.bib" was too narrow; allow common .bib filenames
WHITELIST_EXACT = {"refs.bib", "bibliography.bib", "references.bib"}
# L1 fix (cont'd): also whitelist any .bib basename pattern via path-tail check
WHITELIST_SUFFIX = (".bib",)

# Severity classification
# M1 fix: widen to match hyphen and subdir paths (e.g. analysis/sub/foo-bar.py)
DEFINITE_PATTERNS = (
    re.compile(r"analysis/[\w\-/.]+\.py"),
    re.compile(r"manuscript/docs/[\w\-_/. ]+\.md"),
    re.compile(r"note\s*\([^)]+\)\.tex"),
    re.compile(r"manuscript/docs/[\w\-_/. ]+\.tex"),
)
LIKELY_EXTENSIONS = ("tex", "sh")


@dataclass
class Finding:
    rule: str
    severity: str
    file: str
    line: int
    match: str
    context: str
    proposed_fix: str


def is_comment_line(text_line: str) -> bool:
    """Return True if the line is a LaTeX comment (first non-whitespace char is %)."""
    stripped = text_line.lstrip()
    return stripped.startswith("%")


def collect_bibliography_refs(content: str) -> set[str]:
    """Extract file basenames from bibliography declarations.

    M2 fix: handle both BibTeX-classic (\\bibliography{X}) and biblatex
    (\\addbibresource{X.bib}, \\bibresource{X.bib}) directives.
    """
    refs: set[str] = set()
    # BibTeX-classic: \bibliography{X,Y} (no extension on names)
    for m in re.finditer(r"\\bibliography\{([^}]+)\}", content):
        for name in m.group(1).split(","):
            name = name.strip()
            if name:
                refs.add(name + ".bib" if not name.endswith(".bib") else name)
                refs.add(name)
    # biblatex: \addbibresource{X.bib} or \bibresource{X.bib}
    for m in re.finditer(r"\\(?:addbibresource|bibresource)\{([^}]+)\}", content):
        name = m.group(1).strip()
        if name:
            refs.add(name)
            # Also add without .bib suffix for tolerance
            if name.endswith(".bib"):
                refs.add(name[:-4])
    return refs


def classify_severity(path_str: str) -> str:
    """Map a detected path to severity per SOP §6."""
    for pat in DEFINITE_PATTERNS:
        if pat.search(path_str):
            return "definite"
    ext = path_str.rsplit(".", 1)[-1] if "." in path_str else ""
    if ext in LIKELY_EXTENSIONS:
        return "likely"
    return "suspicious"


def propose_fix(path_str: str, severity: str) -> str:
    if severity == "definite":
        if path_str.endswith(".py"):
            return "刪除句 — formal manuscript 不引用 working scripts"
        if path_str.endswith(".md"):
            return "改成 content-based description,或刪 parenthetical"
        if "note" in path_str.lower():
            return "刪 parenthetical (working note 引用),保留 sub-section 標籤"
    if severity == "likely":
        return "review:確認非合法 reference,改 content-based 或加入 white-list"
    return "review:可能 false positive,確認 context"


def scan_file(path: Path, content: str, whitelist_bibs: set[str]) -> list[Finding]:
    """Scan content for Rule R1 violations. Skip comment lines."""
    findings: list[Finding] = []
    lines = content.splitlines()
    for line_no, line_text in enumerate(lines, start=1):
        if is_comment_line(line_text):
            continue
        for m in TEXTTT_RE.finditer(line_text):
            inner = m.group(1)
            # Look for code-extension path inside the \texttt content
            # Need to unescape `\_` → `_` and `\ ` → ` ` for matching
            inner_unescaped = inner.replace(r"\_", "_").replace(r"\ ", " ")
            path_match = PATH_WITH_EXT_RE.search(inner_unescaped)
            if not path_match:
                continue
            path_str = path_match.group(0)
            # L1 fix: extend whitelist to any .bib suffix
            if (
                path_str in WHITELIST_EXACT
                or path_str in whitelist_bibs
                or any(path_str.endswith(suf) for suf in WHITELIST_SUFFIX)
            ):
                continue
            severity = classify_severity(path_str)
            context_start = max(0, line_no - 2)
            context_end = min(len(lines), line_no + 1)
            context = "\n".join(lines[context_start:context_end])
            findings.append(
                Finding(
                    rule="R1",
                    severity=severity,
                    file=str(path),
                    line=line_no,
                    match=path_str,
                    context=context,
                    proposed_fix=propose_fix(path_str, severity),
                )
            )
    return findings


def emit_json(findings: list[Finding]) -> str:
    severity_counts = {sev: 0 for sev in ("definite", "likely", "suspicious", "FYI")}
    for f in findings:
        severity_counts[f.severity] = severity_counts.get(f.severity, 0) + 1
    report = {
        "rule": "R1",
        "tool": "audit-symbols.py",
        "version": "0.1.0",
        "severity_counts": severity_counts,
        "total": len(findings),
        "findings": [asdict(f) for f in findings],
    }
    return json.dumps(report, indent=2, ensure_ascii=False)


def emit_md(findings: list[Finding]) -> str:
    if not findings:
        return "# Audit (R1 symbols) — Clean\n\nZero findings.\n"
    out: list[str] = ["# Audit (R1 symbols)\n"]
    by_severity: dict[str, list[Finding]] = {}
    for f in findings:
        by_severity.setdefault(f.severity, []).append(f)
    for sev in ("definite", "likely", "suspicious", "FYI"):
        items = by_severity.get(sev, [])
        if not items:
            continue
        out.append(f"\n## {sev.capitalize()} ({len(items)})\n")
        for idx, f in enumerate(items, start=1):
            out.append(f"### F{sev[:3].upper()}-{idx}: `{f.match}`")
            out.append(f"- **Location**: `{f.file}:{f.line}`")
            out.append(f"- **Proposed fix**: {f.proposed_fix}")
            out.append(f"- **Context**:\n```\n{f.context}\n```\n")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Rule R1 detector: \\texttt{} working-file path leak")
    parser.add_argument("--manuscript-root", required=True, type=Path,
                        help="path to manuscript repo root (containing main.tex)")
    parser.add_argument("--report-format", choices=("json", "md"), default="md")
    args = parser.parse_args()

    root: Path = args.manuscript_root
    main_tex = root / "main.tex"
    if not main_tex.exists():
        sys.stderr.write(f"error: {main_tex} not found\n")
        return 2

    try:
        content = main_tex.read_text(encoding="utf-8")
    except OSError as e:
        sys.stderr.write(f"error: cannot read {main_tex}: {e}\n")
        return 2

    whitelist_bibs = collect_bibliography_refs(content)
    findings = scan_file(main_tex, content, whitelist_bibs)

    if args.report_format == "json":
        sys.stdout.write(emit_json(findings))
    else:
        sys.stdout.write(emit_md(findings))

    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
