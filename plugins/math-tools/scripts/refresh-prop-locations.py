#!/usr/bin/env python3
"""Refresh propositions location field from current main.tex (#106 Option 1).

For each prop in a propositions JSONL file, find the actual line range where
prop.text appears in main.tex and update the `location` field accordingly.

Uses validator's `normalize_for_match` throughout: an R1 existence check
against the whole-text normalized form, then a windowed locator that
normalizes each candidate MAX_SPAN-line window as one whole string and tests
substring containment. Normalizing whole windows (rather than per line) makes
context-dependent rules — macro / comment / math-delimiter stripping whose
span crosses a source-wrap boundary — resolve correctly, which the earlier
per-line search space could not do (#137).

Usage:
    python3 scripts/refresh-prop-locations.py --jsonl PATH [--tex PATH] [--dry-run]

Exits:
    0 — all props refreshed (or already accurate)
    1 — at least one prop's text not found (R1) or not anchorable (windowed)
    2 — usage / IO error

Refs PsychQuantHsu/psychophysical_representations#106
Refs PsychQuantHsu/psychophysical_representations#137
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_TEX = SCRIPT_DIR.parent / "manuscript" / "main.tex"

# Windowed-locator span: each candidate window is MAX_SPAN source lines. The
# longest range-form prop in main.jsonl spans 12 source lines; 40 gives >3x
# headroom. A prop whose true source span exceeds MAX_SPAN cannot be anchored
# and is reported as a loud `anchor_failed` (#137).
MAX_SPAN = 40


def load_validator():
    """Import validate-propositions.py via importlib (filename has hyphen)."""
    spec = importlib.util.spec_from_file_location(
        "validator", SCRIPT_DIR / "validate-propositions.py"
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load validate-propositions.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def precompute_window_norms(tex_lines: list[str], normalize_fn) -> list[str]:
    """Normalized form of the MAX_SPAN-line window starting at each line.

    `window_norms[s]` (0-indexed) is `normalize_fn` applied to the joined block
    `tex_lines[s : s + MAX_SPAN]`. Computed once per run; `find_prop_span` then
    locates props by cheap substring checks against this cache.

    Each window is normalized as one whole multi-line string, so
    context-dependent rules in `normalize_for_match` (macro / comment /
    math-delimiter stripping whose span crosses a source-wrap boundary) resolve
    correctly — which the earlier per-line search space could not do (#137).
    """
    return [
        normalize_fn("\n".join(tex_lines[s:s + MAX_SPAN]))
        for s in range(len(tex_lines))
    ]


def _grow_end(
    normalized_prop: str, tex_lines: list[str], normalize_fn, start: int
) -> int | None:
    """Smallest end line `e` (>= start) such that the normalized join of
    `tex_lines[start..e]` contains `normalized_prop`.

    None when no `e` within MAX_SPAN lines works (defensive — a caller only
    grows from a `start` whose MAX_SPAN window already contained the prop).
    """
    last = min(start + MAX_SPAN, len(tex_lines))
    for end in range(start, last + 1):
        if normalized_prop in normalize_fn("\n".join(tex_lines[start - 1:end])):
            return end
    return None


def find_prop_span(
    normalized_prop: str,
    window_norms: list[str],
    tex_lines: list[str],
    normalize_fn,
    claimed_start: int | None,
) -> tuple[int, int] | None:
    """Locate a prop's (start_line, end_line) in main.tex via windowed search.

    `normalized_prop` is the prop's text already passed through `normalize_fn`.
    `window_norms[s]` is the normalized MAX_SPAN-line window starting at the
    1-indexed line `s + 1` (see `precompute_window_norms`).

    `starts` collects every 1-indexed line whose MAX_SPAN-window contains the
    prop. Distinct occurrences are then separated:

    - Common case — no window contains the prop more than once: each maximal
      contiguous run of `starts` is exactly one occurrence, and its MAX is the
      true start line (a window starting at `s` contains the prop iff `s` is at
      or before the start, so the largest such `s` is the start). No extra
      normalization — fast.
    - Duplicate case — some window contains the prop twice (a verbatim repeat
      within MAX_SPAN lines): each `start` is resolved to the minimal end line
      of its span via `_grow_end`. One distinct end line is one occurrence, and
      the largest start resolving to it is that occurrence's true start.

    Among occurrences, the one whose start is nearest `claimed_start` wins (the
    first if there is no claim) — the duplicate-text disambiguation contract.

    Returns None when the prop matches no window — genuinely un-anchorable
    within MAX_SPAN lines (source span longer, or absent). The caller counts
    this as a loud `anchor_failed` — never a silent mis-write.
    """
    if not normalized_prop.strip():
        return None  # empty / whitespace-only prop — not locatable

    starts = [
        t
        for t in range(1, len(window_norms) + 1)
        if normalized_prop in window_norms[t - 1]
    ]
    if not starts:
        return None

    if any(window_norms[t - 1].count(normalized_prop) >= 2 for t in starts):
        # A window sees the prop twice — resolve each start to its span's end
        # line; one distinct end == one occurrence, largest start wins per end.
        by_end: dict[int, int] = {}
        for t in starts:
            e = _grow_end(normalized_prop, tex_lines, normalize_fn, t)
            if e is not None and t > by_end.get(e, 0):
                by_end[e] = t
        occurrences = sorted((t, e) for e, t in by_end.items())
    else:
        # Each contiguous run of `starts` is one occurrence; run-max is the
        # true start line.
        occ_starts: list[int] = []
        run_max = starts[0]
        for s in starts[1:]:
            if s == run_max + 1:
                run_max = s
            else:
                occ_starts.append(run_max)
                run_max = s
        occ_starts.append(run_max)
        occurrences = [
            (t, _grow_end(normalized_prop, tex_lines, normalize_fn, t))
            for t in occ_starts
        ]

    occurrences = [(t, e) for t, e in occurrences if e is not None]
    if not occurrences:
        return None

    if claimed_start is not None:
        return min(occurrences, key=lambda oc: abs(oc[0] - claimed_start))
    return occurrences[0]


def parse_claimed_loc(loc_str: str) -> tuple[int | None, int | None]:
    m = re.match(r"main\.tex:L(\d+)(?:-L(\d+))?", loc_str or "")
    if not m:
        return None, None
    return int(m.group(1)), int(m.group(2)) if m.group(2) else int(m.group(1))


def refresh_jsonl(
    jsonl_path: Path, tex_path: Path, dry_run: bool
) -> tuple[int, int, int, int]:
    """Refresh location fields in jsonl_path.

    Returns (props_total, props_updated, props_match_failed, props_anchor_failed).
    """
    validator = load_validator()
    normalize = validator.normalize_for_match

    tex_text = tex_path.read_text()
    tex_lines = tex_text.split("\n")
    # Whole-text normalized form for the R1 existence check. The windowed
    # locator (precompute_window_norms + find_prop_span) then resolves each
    # prop to a line span (#137).
    normalized_tex = normalize(tex_text)
    window_norms = precompute_window_norms(tex_lines, normalize)

    props = []
    with jsonl_path.open() as fp:
        for line in fp:
            line = line.strip()
            if line:
                props.append(json.loads(line))

    updated = 0
    match_failed = 0
    anchor_failed = 0
    new_lines = []

    for p in props:
        text = p.get("text", "")
        claimed_start, claimed_end = parse_claimed_loc(p.get("location", ""))
        normalized_text = normalize(text)

        # Empty / whitespace-only prop.text: `"" in anything` is always True, so
        # it would slip past the R1 containment check and be silently relocated
        # to L1. Reject as match_failed instead (#123 F3).
        if not normalized_text.strip():
            match_failed += 1
            print(
                f"⚠ {p['id'][:8]} ({p.get('location','?')}): prop.text empty / whitespace-only — cannot locate",
                file=sys.stderr,
            )
            new_lines.append(p)
            continue

        # R1 normalize-aware existence check (whole-text)
        if normalized_text not in normalized_tex:
            match_failed += 1
            print(
                f"⚠ {p['id'][:8]} ({p.get('location','?')}): text (normalized) NOT in main.tex — leaving location unchanged",
                file=sys.stderr,
            )
            new_lines.append(p)
            continue

        # Map to actual line span via the windowed locator (#137)
        span = find_prop_span(
            normalized_text, window_norms, tex_lines, normalize, claimed_start
        )
        if span is None:
            # R1 (whole-text) passed but the prop is not anchorable within
            # MAX_SPAN lines. Surface loudly; never silently mis-write
            # `location`.
            anchor_failed += 1
            print(
                f"⚠ {p['id'][:8]} ({p.get('location','?')}): R1 passes but anchor failed — location unchanged",
                file=sys.stderr,
            )
            new_lines.append(p)
            continue

        actual_start, actual_end = span
        new_loc = (
            f"main.tex:L{actual_start}-L{actual_end}"
            if actual_end > actual_start
            else f"main.tex:L{actual_start}"
        )

        if new_loc != p.get("location", ""):
            updated += 1
            if not dry_run:
                p["location"] = new_loc
            print(
                f"✓ {p['id'][:8]}: {p.get('location','?')} → {new_loc}",
                file=sys.stderr,
            )
        new_lines.append(p)

    if not dry_run:
        # Write back preserving JSON structure (one object per line, no trailing newline weirdness)
        with jsonl_path.open("w") as fp:
            for p in new_lines:
                fp.write(json.dumps(p, ensure_ascii=False) + "\n")

    return len(props), updated, match_failed, anchor_failed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jsonl", type=Path, required=True, help="propositions JSONL path")
    parser.add_argument("--tex", type=Path, default=DEFAULT_TEX, help="manuscript .tex path")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="show what would change without writing",
    )
    args = parser.parse_args()

    if not args.jsonl.exists():
        print(f"error: jsonl not found: {args.jsonl}", file=sys.stderr)
        return 2
    if not args.tex.exists():
        print(f"error: tex not found: {args.tex}", file=sys.stderr)
        return 2

    total, updated, match_failed, anchor_failed = refresh_jsonl(
        args.jsonl, args.tex, args.dry_run
    )

    print(f"\n=== {args.jsonl.name} ===", file=sys.stderr)
    print(f"total props: {total}", file=sys.stderr)
    print(f"updated: {updated}", file=sys.stderr)
    print(f"R1 match failed: {match_failed}", file=sys.stderr)
    print(f"anchor failed: {anchor_failed}", file=sys.stderr)
    if args.dry_run:
        print(f"(dry-run — no changes written)", file=sys.stderr)

    return 1 if (match_failed > 0 or anchor_failed > 0) else 0


if __name__ == "__main__":
    sys.exit(main())
