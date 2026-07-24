#!/usr/bin/env python3
"""audit-code-manuscript.py — Rule R3 detector: code/manuscript symbol drift.

Compares Python AST symbols in analysis/*.py against backtick code references
in manuscript/docs/*.md (excluding frozen subdirs).

Detection:
- definite: manuscript references `X` but X not defined in code (dangling)
- FYI: code defines X but manuscript never mentions it (stale code candidate)

See .claude/rules/manuscript-consistency-audit.md §9 Pattern 6 for example.

Excluded manuscript paths (frozen historical record):
- manuscript/docs/rounds/
- manuscript/docs/legacy/
- manuscript/docs/audit/  (audit reports themselves)

Usage:
    python3 scripts/audit-code-manuscript.py --manuscript-root manuscript/ --code-root analysis/

Exit code:
    0 — clean
    1 — at least one finding
    2 — tool error
"""
from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

BACKTICK_CODE_RE = re.compile(r"`([a-zA-Z_][a-zA-Z0-9_]*)`")

EXCLUDED_DOC_DIRS = ("rounds", "legacy", "audit", "archive", "archived")

# LaTeX label / cite key / bib entry patterns used to build R3 allowlist.
# Identifiers appearing in any of these contexts are NOT code symbols; they are
# LaTeX-domain names (theorem labels, citation keys, bibliography entries).
# Without this allowlist, R3 mis-categorises 86+ such names as "definite drift"
# on a real manuscript — the v0.1 calibration defect noted in #42 verify F-R3-Cal.
LATEX_LABEL_RE = re.compile(r"\\label\{([^}]+)\}")
LATEX_CITE_RE = re.compile(r"\\cite[a-z]*\*?\s*(?:\[[^\]]*\])?\s*\{([^}]+)\}")
BIB_ENTRY_RE = re.compile(
    r"@(?:article|book|inproceedings|incollection|techreport|misc|"
    r"phdthesis|mastersthesis|unpublished|manual|booklet|conference|"
    r"proceedings|inbook|online)\s*\{\s*([^,\s}]+)\s*[,}]",
    re.IGNORECASE,
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


def extract_code_symbols(py_file: Path) -> set[str]:
    """Extract function names + module-level variable names from a Python file.

    SyntaxError / OSError → warn to stderr (fix for #42 F-Codex-F6: silent swallow
    previously hid tool errors as manuscript drift). Returns empty set, but warning
    surfaces the parse failure so user can diagnose.
    """
    try:
        tree = ast.parse(py_file.read_text(encoding="utf-8"), filename=str(py_file))
    except SyntaxError as exc:
        sys.stderr.write(f"warning: {py_file}: syntax error at line {exc.lineno}: {exc.msg}\n")
        return set()
    except OSError as exc:
        sys.stderr.write(f"warning: {py_file}: {exc}\n")
        return set()
    symbols: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            symbols.add(node.name)
    # Module-level assignments
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for tgt in node.targets:
                if isinstance(tgt, ast.Name):
                    symbols.add(tgt.id)
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            symbols.add(node.target.id)
        # C3 fix: capture import aliases at module level
        # `from X import Y as Z` → Z is callable as a symbol in this module
        # `import X as Y` → Y is callable
        elif isinstance(node, ast.ImportFrom):
            for alias in node.names:
                symbols.add(alias.asname or alias.name)
        elif isinstance(node, ast.Import):
            for alias in node.names:
                # `import X.Y` → top-level name is `X` unless aliased
                symbols.add(alias.asname or alias.name.split(".")[0])
    return symbols


def collect_all_code_symbols(code_root: Path) -> tuple[set[str], dict[str, list[Path]]]:
    """Walk code_root for *.py, return (union of symbols, symbol → files map)."""
    all_symbols: set[str] = set()
    symbol_to_files: dict[str, list[Path]] = {}
    for py in sorted(code_root.rglob("*.py")):
        if py.name.startswith("test_"):
            continue
        syms = extract_code_symbols(py)
        for s in syms:
            symbol_to_files.setdefault(s, []).append(py)
            all_symbols.add(s)
    return all_symbols, symbol_to_files


def extract_md_backtick_refs(md_file: Path) -> list[tuple[str, int]]:
    """Return list of (identifier, line_no) for backtick code refs in markdown."""
    refs: list[tuple[str, int]] = []
    try:
        content = md_file.read_text(encoding="utf-8")
    except OSError:
        return refs
    # Skip fenced code blocks — both ``` and ~~~ delimiters per CommonMark spec.
    # Fix for #50 F-Logic-H4: previously only ``` was recognized, so backtick refs
    # inside ~~~-fenced blocks leaked through and produced false R3 findings.
    # Tracking: enter fence on first marker, exit only on matching marker (so a
    # ~~~ block can contain ``` text and vice versa).
    fence_marker: str | None = None
    for line_no, line in enumerate(content.splitlines(), start=1):
        stripped = line.lstrip()
        if fence_marker is None:
            if stripped.startswith("```"):
                fence_marker = "```"
                continue
            if stripped.startswith("~~~"):
                fence_marker = "~~~"
                continue
        else:
            if stripped.startswith(fence_marker):
                fence_marker = None
                continue
            # Inside fence — skip all backtick scanning
            continue
        for m in BACKTICK_CODE_RE.finditer(line):
            refs.append((m.group(1), line_no))
    return refs


def collect_latex_allowlist(manuscript_root: Path, extra_tex_roots: list[Path] | None = None) -> set[str]:
    """Collect LaTeX labels + cite keys + bib entry keys to suppress R3 false positives.

    Identifiers used as LaTeX labels, citations, or bib entries are LaTeX-domain
    names — NOT Python code symbols. R3 should not flag them as "missing code drift".

    Scans `manuscript_root/**/*.{tex,bib}` plus any paths in `extra_tex_roots`
    (typically the upper repo's `references/` directory, since manuscript/docs/*.md
    often references labels in working-note .tex files outside the submodule).

    Fixes #42 verify F-R3-Cal: 86 false positives on real manuscript, all of which
    were LaTeX labels / cite keys / bib keys mis-classified as code symbols.
    """
    scan_roots: list[Path] = [manuscript_root]
    if extra_tex_roots:
        scan_roots.extend(p for p in extra_tex_roots if p.exists())

    allowlist: set[str] = set()
    for root in scan_roots:
        for tex_path in root.rglob("*.tex"):
            try:
                content = tex_path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for m in LATEX_LABEL_RE.finditer(content):
                allowlist.add(m.group(1).strip())
            for m in LATEX_CITE_RE.finditer(content):
                for key in m.group(1).split(","):
                    key = key.strip()
                    if key:
                        allowlist.add(key)
        for bib_path in root.rglob("*.bib"):
            try:
                content = bib_path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for m in BIB_ENTRY_RE.finditer(content):
                allowlist.add(m.group(1).strip())
    return allowlist


def is_excluded_doc_path(path: Path, docs_root: Path) -> bool:
    """Check if path is under an excluded subdir of docs_root."""
    try:
        rel = path.relative_to(docs_root)
    except ValueError:
        return False
    parts = rel.parts
    return len(parts) >= 1 and parts[0] in EXCLUDED_DOC_DIRS


def emit_json(findings: list[Finding]) -> str:
    severity_counts = {sev: 0 for sev in ("definite", "likely", "suspicious", "FYI")}
    for f in findings:
        severity_counts[f.severity] = severity_counts.get(f.severity, 0) + 1
    report = {
        "rule": "R3",
        "tool": "audit-code-manuscript.py",
        "version": "0.1.0",
        "severity_counts": severity_counts,
        "total": len(findings),
        "findings": [asdict(f) for f in findings],
    }
    return json.dumps(report, indent=2, ensure_ascii=False)


def emit_md(findings: list[Finding]) -> str:
    if not findings:
        return "# Audit (R3 code-manuscript drift) — Clean\n\nZero findings.\n"
    out: list[str] = ["# Audit (R3 code-manuscript drift)\n"]
    by_severity: dict[str, list[Finding]] = {}
    for f in findings:
        by_severity.setdefault(f.severity, []).append(f)
    for sev in ("definite", "likely", "suspicious", "FYI"):
        items = by_severity.get(sev, [])
        if not items:
            continue
        out.append(f"\n## {sev.capitalize()} ({len(items)})\n")
        for idx, f in enumerate(items, start=1):
            out.append(f"### FR3-{sev[:3].upper()}-{idx}: `{f.match}`")
            loc = f"`{f.file}:{f.line}`" if f.line else f"`{f.file}` (code-only)"
            out.append(f"- **Location**: {loc}")
            out.append(f"- **Proposed fix**: {f.proposed_fix}")
            out.append(f"- **Context**: {f.context}\n")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Rule R3: code/manuscript symbol drift")
    parser.add_argument("--manuscript-root", required=True, type=Path)
    parser.add_argument("--code-root", required=True, type=Path)
    parser.add_argument(
        "--latex-source-root",
        type=Path,
        action="append",
        default=None,
        help="extra dir(s) to scan for \\label / \\cite / @bib to extend R3 allowlist. "
        "Defaults to <manuscript-root parent>/references/ if it exists.",
    )
    parser.add_argument("--report-format", choices=("json", "md"), default="md")
    parser.add_argument(
        "--fyi-min-length",
        type=int,
        default=6,
        help="Minimum length for FYI 'code-defined but not in manuscript' findings (M5 fix; default 6).",
    )
    args = parser.parse_args()

    manuscript_root: Path = args.manuscript_root
    code_root: Path = args.code_root
    extra_tex_roots: list[Path] = list(args.latex_source_root or [])
    # Auto-discover sibling references/ (project convention: working-note .tex
    # files live there, and manuscript/docs/*.md often references their labels).
    if not extra_tex_roots:
        sibling_refs = manuscript_root.parent / "references"
        if sibling_refs.exists() and sibling_refs.is_dir():
            extra_tex_roots.append(sibling_refs)
    if not manuscript_root.exists():
        sys.stderr.write(f"error: {manuscript_root} not found\n")
        return 2
    if not code_root.exists():
        sys.stderr.write(f"error: {code_root} not found\n")
        return 2

    docs_root = manuscript_root / "docs"
    code_symbols, symbol_to_files = collect_all_code_symbols(code_root)
    latex_allowlist = collect_latex_allowlist(manuscript_root, extra_tex_roots)
    fyi_min_length: int = args.fyi_min_length

    findings: list[Finding] = []
    manuscript_refs: dict[str, list[tuple[Path, int]]] = {}

    if docs_root.exists():
        for md in sorted(docs_root.rglob("*.md")):
            if is_excluded_doc_path(md, docs_root):
                continue
            for ref, line_no in extract_md_backtick_refs(md):
                manuscript_refs.setdefault(ref, []).append((md, line_no))

    # definite: manuscript refs not defined in code AND not a LaTeX-domain name
    for ref, locations in manuscript_refs.items():
        if ref in code_symbols:
            continue
        # Skip common English words / single-char / very short identifiers (likely not code)
        if len(ref) < 3 or ref.lower() in {"and", "the", "for", "not", "but"}:
            continue
        # Require identifier with underscore or camelCase pattern (more likely code)
        if "_" not in ref and not any(c.isupper() for c in ref[1:]):
            continue
        # R3 calibration (fix for #42 F-R3-Cal): if ref is a LaTeX label / cite key
        # / bib entry, it is a LaTeX-domain name, not a code symbol. Demote to FYI.
        in_latex_domain = ref in latex_allowlist
        for md_path, line_no in locations:
            findings.append(
                Finding(
                    rule="R3",
                    severity="FYI" if in_latex_domain else "definite",
                    file=str(md_path),
                    line=line_no,
                    match=ref,
                    context=(
                        f"manuscript references `{ref}` (LaTeX label/cite/bib entry) "
                        "— not a code symbol; informational only"
                        if in_latex_domain
                        else f"manuscript references `{ref}` but no such symbol in {code_root}"
                    ),
                    proposed_fix=(
                        f"OK: `{ref}` 是 LaTeX label / cite key,非 code drift"
                        if in_latex_domain
                        else f"檢查:`{ref}` 是 typo / renamed / removed from code? 對齊命名"
                    ),
                )
            )

    # FYI: code symbols not mentioned in manuscript (private helpers?)
    referenced = set(manuscript_refs.keys())
    for sym, files in symbol_to_files.items():
        if sym in referenced:
            continue
        # Skip dunder, private (single-leading underscore), and common builtins
        if sym.startswith("_") or sym in {"main", "args", "parser", "__name__"}:
            continue
        # M5 fix: threshold tunable via --fyi-min-length CLI arg (default 6)
        # Previously hard-coded 6 silently dropped short but meaningful symbols
        # like `fit`, `mse`, `r2`.
        if len(sym) < fyi_min_length:
            continue
        findings.append(
            Finding(
                rule="R3",
                severity="FYI",
                file=str(files[0]),
                line=0,
                match=sym,
                context=f"code defines `{sym}` but manuscript never references it",
                proposed_fix=f"確認 `{sym}` 是 private helper(則 rename `_{sym}`) 或 stale code(可刪)",
            )
        )

    if args.report_format == "json":
        sys.stdout.write(emit_json(findings))
    else:
        sys.stdout.write(emit_md(findings))

    return 0 if not findings else 1


if __name__ == "__main__":
    sys.exit(main())
