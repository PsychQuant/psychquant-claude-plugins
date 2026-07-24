"""Shared LaTeX theorem-env parser (#115 M-5 dedup).

Single source of truth previously inline-copied across:
- ``scripts/audit-theorem-boundaries.py`` (#98 cross-check mode)
- ``scripts/validate-propositions.py`` R9 section (#100 containing_block-env check)

Drift surface eliminated: prior to dedup, ``_R9_TYPE_PREFIX_RE`` covered 7 env types
while audit-script ``TYPE_PREFIX_RE`` covered 4; M-1 (greedy ``\\ref``) and M-2
(inverted ``L<start>-L<end>``) had to be fixed symmetrically in both copies via
#100 Path B (commit ``f3512e3``). This module is the structural prevention.

Edge cases (documented limits — same as the originals)
------------------------------------------------------
- Only handles plain ``\\begin{X}`` (no starred ``\\begin{X*}``); grep-confirmed
  manuscript/main.tex never uses starred forms (#98 R-1).
- Treats ``proof`` as sibling of theorem/lemma/etc., not nested. main.tex
  confirms ``\\end{theorem}`` precedes ``\\begin{proof}`` for every numbered
  theorem (#98 R-1).
- ``\\label{...}`` association: each env binds to the nearest preceding label
  within 3 lines of its ``\\begin`` (covers the common pattern
  ``\\begin{theorem}\\n\\label{thm:foo}\\n...``).
- ``containing_block`` two formats coexist (#113):
  ``theorem:thm:eta-s`` (with type prefix, ``_stage2/theorem1.jsonl`` and pre-
  Phase-C ``main.jsonl``) and ``thm:eta-s`` (canonical, label-only post-#113).
  Cross-check normalizes by stripping
  ``^(theorem|lemma|proposition|corollary|proof|definition|remark|conjecture):``
  prefix, then matches the ``thm:`` / ``lem:`` part. Sub-paths like
  ``thm:gamma-g/proof/step2b`` use the segment **before** the first ``/``.
- ``TYPE_PREFIX_RE`` covers all 8 env types declared in main.tex L22-L28
  (#115 M-5 DP1: 7-type superset rather than audit-script's previous 4-type
  narrower form; forward-compat for Stage 3 extraction even though no current
  prop's ``containing_block`` uses the def/remark/conjecture prefixes).
"""

from __future__ import annotations

import re
import sys

# Synced with main.tex \newtheorem declarations (L22-L28).
# 7 declared envs + proof. Parser must recognize all declared types or future
# Stage 3 extraction into definition/remark/conjecture would silently bypass
# audit (DA F1 / Codex confirmed in /idd-verify #98).
ENV_TYPES: tuple[str, ...] = (
    "theorem", "lemma", "proposition", "corollary",
    "definition", "remark", "conjecture",
    "proof",
)
BEGIN_RE = re.compile(r"^\s*\\begin\{(" + "|".join(ENV_TYPES) + r")\}")
END_RE = re.compile(r"^\s*\\end\{(" + "|".join(ENV_TYPES) + r")\}")
LABEL_RE = re.compile(r"\\label\{([^}]+)\}")
# Non-greedy `[^\]]*?` captures the FIRST `\ref` in the proof title, not the
# last (#115 M-1 / #100 Path B fix — greedy `[^\]]*` would bind
# `[Proof of Theorem~\ref{thm:a}, using Lemma~\ref{lem:b}]` to lem:b).
PROOF_TARGET_RE = re.compile(r"\\begin\{proof\}\[[^\]]*?\\ref\{([^}]+)\}[^\]]*\]")
LOC_RE = re.compile(r"main\.tex:L(\d+)(?:-L(\d+))?")
# 7-type superset per #115 M-5 DP1 (unified with validator R9's wider form).
TYPE_PREFIX_RE = re.compile(
    r"^(theorem|lemma|proposition|corollary|proof|definition|remark|conjecture):"
)


def parse_envs(tex_text: str, *, warn_on_residue: bool = True) -> list[dict]:
    """Return ordered list of envs as ``{type, begin_line, end_line, label,
    proof_target}``.

    Uses a stack to match nested ``\\begin`` / ``\\end`` of the same type.
    For our manuscript the stack stays shallow (proof is sibling not nested
    in theorem) but the algorithm is correct under shallow-nesting anyway.

    Parameters
    ----------
    tex_text : str
        Raw LaTeX source.
    warn_on_residue : bool, default True
        If True, emit one stderr line per unmatched ``\\begin{...}`` entry
        remaining in the open stack after the main loop (#115 M-4 — silent
        drop previously masked real LaTeX errors). Audit-script ``--jsonl``
        CI gate keeps the default so authors see warnings; validator R9
        passes ``False`` to keep its ``[PASS]/[WARN]`` line clean.
    """
    lines = tex_text.splitlines()
    open_stack: list[dict] = []
    envs: list[dict] = []

    for idx, line in enumerate(lines, start=1):
        m_begin = BEGIN_RE.match(line)
        if m_begin:
            env_type = m_begin.group(1)
            entry: dict = {
                "type": env_type,
                "begin_line": idx,
                "label": None,
                "proof_target": None,
            }
            # Proof env carries [Proof of Theorem~\ref{<label>}] explicit binding
            if env_type == "proof":
                m_target = PROOF_TARGET_RE.search(line)
                if m_target:
                    entry["proof_target"] = m_target.group(1)
            # Search begin line itself + next 2 lines for first \label{}.
            # Begin-line scan (idx-1 in 0-indexed lines) catches the
            # `\begin{theorem}\label{thm:foo}` same-line pattern that the
            # original (idx, idx+3) range missed (Logic H-1 / Codex
            # /idd-verify #98).
            scan_start = max(0, idx - 1)
            scan_end = min(idx + 2, len(lines))
            for j in range(scan_start, scan_end):
                m_label = LABEL_RE.search(lines[j])
                if m_label:
                    entry["label"] = m_label.group(1)
                    break
            open_stack.append(entry)
            continue
        m_end = END_RE.match(line)
        if m_end:
            end_type = m_end.group(1)
            # Pop the most recent matching open
            for k in range(len(open_stack) - 1, -1, -1):
                if open_stack[k]["type"] == end_type:
                    entry = open_stack.pop(k)
                    entry["end_line"] = idx
                    envs.append(entry)
                    break

    # #115 M-4: surface unmatched \begin residue. Silent drop previously
    # masked malformed LaTeX (typo'd \end, mid-edit state, etc.). Non-blocking
    # — parser returns the matched inventory and lets caller decide severity.
    if warn_on_residue and open_stack:
        for entry in open_stack:
            print(
                f"WARN: parse_envs() — unmatched \\begin{{{entry['type']}}} "
                f"at line {entry['begin_line']} (no matching \\end)",
                file=sys.stderr,
            )

    # Sort by begin_line so output is deterministic
    envs.sort(key=lambda e: e["begin_line"])
    return envs


def normalize_containing_block(cb: str) -> str:
    """Strip type prefix (#113) and sub-path (proof/step segments).

    Examples
    --------
    >>> normalize_containing_block("theorem:thm:eta-s")
    'thm:eta-s'
    >>> normalize_containing_block("theorem:thm:eta-s/proof/s1")
    'thm:eta-s'
    >>> normalize_containing_block("thm:gamma-g/proof/step2b")
    'thm:gamma-g'
    >>> normalize_containing_block("thm:main")
    'thm:main'
    """
    cb = TYPE_PREFIX_RE.sub("", cb)
    return cb.split("/", 1)[0]


def parse_location(loc: str) -> tuple[int, int] | None:
    """Parse ``main.tex:L<start>[-L<end>]`` -> ``(start, end)`` or ``None``.

    Rejects inverted (``end < start``) and zero/negative-base ranges
    (#115 M-2 / #100 Path B fix). An inverted range could coincidentally pass
    a containment check, masking a real boundary mismatch.
    """
    m = LOC_RE.search(loc or "")
    if not m:
        return None
    start = int(m.group(1))
    end = int(m.group(2)) if m.group(2) else start
    if start < 1 or end < start:
        return None  # malformed: zero/negative base or inverted range
    return start, end


def build_associated(envs: list[dict]) -> dict[str, list[dict]]:
    """label -> [statement_env, ...associated_proof_envs] map.

    Proof env associates via priority order:

    1. Explicit binding via ``\\begin{proof}[Proof of Theorem~\\ref{<label>}]``
       argument
    2. Fallback proximity: most-recent statement whose ``end_line`` < proof
       ``begin_line``, gap <= 12 (gap can be 10 when a sibling corollary
       intervenes)
    """
    statement_envs = [
        e for e in envs if e["type"] != "proof" and e.get("label")
    ]
    proof_envs = [e for e in envs if e["type"] == "proof"]
    associated: dict[str, list[dict]] = {
        e["label"]: [e] for e in statement_envs
    }
    for p in proof_envs:
        target = p.get("proof_target")
        if target and target in associated:
            associated[target].append(p)
            continue
        candidates = [
            s for s in statement_envs if s["end_line"] < p["begin_line"]
        ]
        if not candidates:
            continue
        s = max(candidates, key=lambda x: x["end_line"])
        if p["begin_line"] - s["end_line"] <= 12:
            associated[s["label"]].append(p)
    return associated
