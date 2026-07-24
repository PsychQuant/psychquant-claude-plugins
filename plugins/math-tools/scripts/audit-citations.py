#!/usr/bin/env python3
"""audit-citations.py — Rule R2 + R2-bis detector.

Rule R2: citation label leak — \\citet[Theorem~\\texttt{snake_case_id}]{X}
    Detects citation argument containing snake_case identifier inside \\texttt{},
    which is typically a leaked LaTeX \\label{} ID from another paper's source.

Rule R2-bis: bib cross-check — \\cite{key} ↔ refs.bib @type{key, ...}
    Detects:
    - definite: \\cite{X} but X not in refs.bib (missing entry)
    - FYI: @type{X} in refs.bib but X not cited (orphan entry)

See .claude/rules/manuscript-consistency-audit.md §9 Pattern 2, 5 for examples.

Usage:
    python3 scripts/audit-citations.py --manuscript-root manuscript/ [--report-format json|md]

Exit code:
    0 — clean
    1 — at least one finding (any severity)
    2 — tool error
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

# R2: citation optional argument containing \texttt{snake_case_id}
# LaTeX may escape underscore as \_ inside \texttt{}, so match \\? before _
# Match identifiers with ≥1 underscore (escaped or not)
# M4 fix: allow digits in identifier tokens (e.g. exact_var_2, mse_l1).
# Each underscore-separated segment may start with a letter or digit and contain
# alphanumerics; first segment must start with a letter to avoid pure-numeric ids.
_SNAKE_ID = r"[a-zA-Z][a-zA-Z0-9]*(?:\\?_[a-zA-Z0-9]+)+"
R2_RE = re.compile(
    r"\\cite[tp]?\s*\[([^\]]*?\\texttt\{" + _SNAKE_ID + r"\}[^\]]*?)\]\{([^}]+)\}",
    re.MULTILINE,
)

# Also catch the parenthetical pattern: \citet{X} (\texttt{label_id})
R2_PAREN_RE = re.compile(
    r"\\cite[tp]?\{[^}]+\}\s*\(\s*\\texttt\{" + _SNAKE_ID + r"\}\s*\)",
    re.MULTILINE,
)

# R2-bis: extract all citation keys
# M6 fix: extend to biblatex commands (\footcite, \nocite, \autocite, \parencite,
# \textcite, \smartcite, \citeauthor, \citeyear, \citetitle).
# Pattern: any \cmd that contains "cite" as substring (covers \cite, \citet,
# \citep, \citealp, \citealt, \citeauthor, \citeyear, \footcite, \nocite,
# \autocite, \parencite, \textcite, \smartcite, etc.), with optional star and
# optional [opt] arg.
CITE_RE = re.compile(
    r"\\(?:[a-zA-Z]*cite[a-zA-Z]*)\*?\s*(?:\[[^\]]*\])?\s*\{([^}]+)\}",
    re.MULTILINE,
)

# refs.bib parsing: only known BibTeX entry types (NOT @string / @comment / @preamble
# which are BibTeX directives, not bibliography entries). Fix for #42 F-Logic-C2:
# previous broad `@\w+` matched directives and polluted orphan-FYI signal.
BIB_ENTRY_RE = re.compile(
    r"@(?:article|book|inproceedings|incollection|techreport|misc|"
    r"phdthesis|mastersthesis|unpublished|manual|booklet|conference|"
    r"proceedings|inbook|online)\s*\{\s*([^,\s}]+)\s*[,}]",
    re.MULTILINE | re.IGNORECASE,
)


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
    return text_line.lstrip().startswith("%")


def strip_comments(content: str) -> str:
    """Remove LaTeX % comments line-by-line for cite-key extraction (keeps line breaks).

    Fix for #50 F-Logic-H2: previously only full-line `^%` comments were stripped.
    Inline `text % comment` would leak — `\\cite{wrong}` inside an inline comment
    was counted as cited, producing false R2-bis missing-entry findings.

    LaTeX comment rule: `%` outside math/verbatim, NOT preceded by `\\`, comments
    out everything to end-of-line. `\\%` is a literal percent sign (not comment).
    """
    out_lines = []
    inline_comment_re = re.compile(r"(?<!\\)%.*$")
    for line in content.splitlines():
        if is_comment_line(line):
            out_lines.append("")
        else:
            # Strip inline % comment (negative-lookbehind preserves \% literal)
            out_lines.append(inline_comment_re.sub("", line))
    return "\n".join(out_lines)


def find_line_no(content: str, char_offset: int) -> int:
    """Map a character offset to 1-indexed line number."""
    return content[: char_offset + 1].count("\n") + 1


def detect_r2(content: str, tex_file: Path) -> list[Finding]:
    """R2: label leak inside citation optional argument.

    Uses stripped content (full-line + inline % comments removed) so labels inside
    LaTeX comments are NOT flagged (fix for #50 F-Logic-H2, R2 side of comment leak).
    """
    findings: list[Finding] = []
    stripped = strip_comments(content)
    lines = content.splitlines()
    for m in R2_RE.finditer(stripped):
        line_no = find_line_no(stripped, m.start())
        if is_comment_line(lines[line_no - 1]):
            continue
        context_start = max(0, line_no - 2)
        context_end = min(len(lines), line_no + 1)
        context = "\n".join(lines[context_start:context_end])
        findings.append(
            Finding(
                rule="R2",
                severity="likely",
                file=str(tex_file),
                line=line_no,
                match=m.group(0),
                context=context,
                proposed_fix="替換 snake_case label 為 content-based 描述,e.g. `Theorem on $\\eta = f(s)$ case`",
            )
        )
    for m in R2_PAREN_RE.finditer(stripped):
        line_no = find_line_no(stripped, m.start())
        if is_comment_line(lines[line_no - 1]):
            continue
        context_start = max(0, line_no - 2)
        context_end = min(len(lines), line_no + 1)
        context = "\n".join(lines[context_start:context_end])
        findings.append(
            Finding(
                rule="R2",
                severity="likely",
                file=str(tex_file),
                line=line_no,
                match=m.group(0),
                context=context,
                proposed_fix="刪除 parenthetical (snake_case label leak),或改 content-based 描述",
            )
        )
    return findings


def detect_r2bis(content: str, tex_file: Path, bib_keys: set[str]) -> list[Finding]:
    """R2-bis: bib cross-check (orphan / missing)."""
    findings: list[Finding] = []
    cited_keys: set[str] = set()
    stripped = strip_comments(content)
    for m in CITE_RE.finditer(stripped):
        for key in m.group(1).split(","):
            key = key.strip()
            if key:
                cited_keys.add(key)

    # Missing: cite but not in bib (definite)
    missing = cited_keys - bib_keys
    for key in sorted(missing):
        # Find the line where this missing key is cited
        # F4 fix: strip each split-key before equality test — e.g. \cite{A, Missing}
        # produces ["A", " Missing"]; without strip, "Missing" != " Missing" and
        # the loop never matches → line_no stays 0.
        line_no = 0
        for m in CITE_RE.finditer(content):
            split_keys = [k.strip() for k in m.group(1).split(",")]
            if key in split_keys:
                line_no = find_line_no(content, m.start())
                break
        findings.append(
            Finding(
                rule="R2-bis",
                severity="definite",
                file=str(tex_file),
                line=line_no,
                match=key,
                context=f"\\cite*{{{key}}} but {key} not in refs.bib",
                proposed_fix=f"加 {key} 條目到 refs.bib,或修正 cite key typo",
            )
        )

    # Orphan: in bib but never cited (FYI)
    orphans = bib_keys - cited_keys
    for key in sorted(orphans):
        findings.append(
            Finding(
                rule="R2-bis",
                severity="FYI",
                file=str(tex_file),
                line=0,
                match=key,
                context=f"@type{{{key}, ...}} in refs.bib but never cited",
                proposed_fix=f"考慮刪除 {key} 條目,或確認是否預期但漏 cite",
            )
        )

    return findings


def emit_json(findings: list[Finding]) -> str:
    severity_counts = {sev: 0 for sev in ("definite", "likely", "suspicious", "FYI")}
    for f in findings:
        severity_counts[f.severity] = severity_counts.get(f.severity, 0) + 1
    report = {
        "rule": "R2 + R2-bis",
        "tool": "audit-citations.py",
        "version": "0.1.0",
        "severity_counts": severity_counts,
        "total": len(findings),
        "findings": [asdict(f) for f in findings],
    }
    return json.dumps(report, indent=2, ensure_ascii=False)


def emit_md(findings: list[Finding]) -> str:
    if not findings:
        return "# Audit (R2 + R2-bis citations) — Clean\n\nZero findings.\n"
    out: list[str] = ["# Audit (R2 + R2-bis citations)\n"]
    by_severity: dict[str, list[Finding]] = {}
    for f in findings:
        by_severity.setdefault(f.severity, []).append(f)
    for sev in ("definite", "likely", "suspicious", "FYI"):
        items = by_severity.get(sev, [])
        if not items:
            continue
        out.append(f"\n## {sev.capitalize()} ({len(items)})\n")
        for idx, f in enumerate(items, start=1):
            out.append(f"### F{sev[:3].upper()}-{idx}: `{f.match}` ({f.rule})")
            out.append(f"- **Location**: `{f.file}:{f.line}`" if f.line else f"- **Source**: `{f.file}` (bib-only)")
            out.append(f"- **Proposed fix**: {f.proposed_fix}")
            out.append(f"- **Context**:\n```\n{f.context}\n```\n")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Rule R2 + R2-bis detector: citation label leak + bib cross-check")
    parser.add_argument("--manuscript-root", required=True, type=Path)
    parser.add_argument("--report-format", choices=("json", "md"), default="md")
    args = parser.parse_args()

    root: Path = args.manuscript_root
    main_tex = root / "main.tex"
    refs_bib = root / "refs.bib"
    if not main_tex.exists():
        sys.stderr.write(f"error: {main_tex} not found\n")
        return 2

    try:
        tex_content = main_tex.read_text(encoding="utf-8")
        bib_content = refs_bib.read_text(encoding="utf-8") if refs_bib.exists() else ""
    except OSError as e:
        sys.stderr.write(f"error: cannot read input: {e}\n")
        return 2

    bib_keys: set[str] = set()
    for m in BIB_ENTRY_RE.finditer(bib_content):
        bib_keys.add(m.group(1))

    findings = detect_r2(tex_content, main_tex)
    findings.extend(detect_r2bis(tex_content, main_tex, bib_keys))

    if args.report_format == "json":
        sys.stdout.write(emit_json(findings))
    else:
        sys.stdout.write(emit_md(findings))

    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
