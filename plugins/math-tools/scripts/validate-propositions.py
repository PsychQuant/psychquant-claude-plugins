#!/usr/bin/env python3
"""Validate proposition-iso between manuscript/main.tex and propositions store.

Per SCHEMA.md (#69 Locke project, #77 storage refactor): each declarative
clause in main.tex corresponds to exactly one proposition in
manuscript/propositions/main.jsonl (with metadata in _meta.json sidecar).
Legacy single-file main.json is still readable via --json for migration
transition.

Usage:
    python3 scripts/validate-propositions.py [--jsonl PATH] [--meta PATH] [--tex PATH] [--strict]
    python3 scripts/validate-propositions.py --json PATH [--tex PATH] [--strict]   # legacy

Exit codes:
    0 — all checks pass
    1 — at least one error (iso break / cite resolve / contradiction)
    2 — script invocation error (file missing, parse failure)

Checks:
    R1 prop-subset-check — every prop.text substring-matches .tex after normalize (Phase 1)
    R1.5 surjective coverage — every top-level \\section has >=1 prop (Phase 1)
    R2 cite        — every Pxxx in cites resolves to existing prop
    R3 DAG         — no cycles; orphan props warned (no cited_by, not axiom).
                     #83: structural_leaf_types extended for Phase 2 claim_types
                     (connective / reference / scope_qualifier).
    R4 contradict  — known mechanical patterns: boundary axiom violations,
                     orphan structural references (Track A without Track B)
    R7 id-format   — schema v1.2 UUID v7 identity contract (Spectra change
                     migrate-prop-id-to-stable-uuid Task 2.1): id field MUST
                     match canonical UUID v7 layout; no parallel identifier
                     field (display_id / P_id / ordinal / serial). Skipped
                     for v1.1 or missing schema_version (backward compat).
    R8 unique-ids  — every prop.id MUST be unique across the propositions
                     list (Spectra change migrate-prop-id-to-stable-uuid
                     Task 3.2).
    R9 env-consist — schema invariant introduced by #100: for theorem-like
                     containing_block (thm:/lem:/prop:/cor:/def:/rem:/conj:
                     after prefix-strip + sub-path normalization),
                     prop.location range MUST fall within the real
                     `\\begin{env}...\\end{env}` line range parsed from
                     main.tex. WARN-as-baseline (exit 0); see #114 known
                     drift. Skipped silently for non-env containing_block
                     (sec:*/discussion/abstract) and when env_map is empty.

Refs PsychQuantHsu/psychophysical_representations#69
"""
import argparse
import json
import re
import sys
from pathlib import Path
from collections import defaultdict

# #115 R-1 mitigation: insert script dir on sys.path BEFORE importing from
# _lib, so cross-cwd invocation resolves `_lib` relative to the script.
sys.path.insert(0, str(Path(__file__).parent))

from _lib.latex_env_parser import (  # noqa: E402  (sys.path setup must precede)
    build_associated as _r9_build_associated,
    normalize_containing_block as _r9_normalize_containing_block,
    parse_envs as _r9_parse_envs_shared,
    parse_location as _r9_parse_location,
)


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_JSONL = REPO_ROOT / "manuscript" / "propositions" / "main.jsonl"
DEFAULT_META = REPO_ROOT / "manuscript" / "propositions" / "_meta.json"
DEFAULT_JSON = REPO_ROOT / "manuscript" / "propositions" / "main.json"  # legacy fallback
DEFAULT_TEX = REPO_ROOT / "manuscript" / "main.tex"

# R7 id-format: canonical UUID v7 (RFC 9562 §5.7), 8-4-4-4-12 hex lowercased
# with version field `7` and IETF variant top bits `10` (hex digit in 8/9/a/b).
UUID_V7_REGEX = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)

# R7 id-format: parallel identifier fields forbidden under v1.2+ schema —
# storage holds only `id` (UUID); display ordinals are derived at view time.
FORBIDDEN_PARALLEL_ID_FIELDS = ("display_id", "P_id", "ordinal", "serial")


def _version_at_least(version: str, threshold: str) -> bool:
    """Compare dotted version strings numerically (e.g. '1.2' >= '1.1' → True)."""
    try:
        v = tuple(int(x) for x in version.split("."))
        t = tuple(int(x) for x in threshold.split("."))
    except ValueError:
        # Unparseable version → conservative: not at threshold
        return False
    return v >= t


# --------- helpers ---------


def load_props_jsonl(jsonl_path: Path, meta_path: Path | None = None):
    """Load propositions from JSONL + optional _meta.json sidecar.

    JSONL format (1 prop per line) replaces Phase 1 single-JSON storage to keep
    read/write token cost bounded as the manuscript grows. Empty lines + lines
    starting with `//` are skipped (allow handwritten comments in fixtures).

    Returns (data, props, by_id) — `data` mirrors the legacy single-JSON root
    shape (schema_version, source, coverage, axioms, propositions) so the
    rest of the validator stays unchanged.
    """
    if meta_path is not None and meta_path.exists():
        with meta_path.open() as fp:
            data = json.load(fp)
    else:
        data = {}

    props = []
    with jsonl_path.open() as fp:
        for line_no, raw in enumerate(fp, 1):
            line = raw.strip()
            if not line or line.startswith("//"):
                continue
            try:
                props.append(json.loads(line))
            except json.JSONDecodeError as e:
                raise ValueError(f"JSONL line {line_no} parse error: {e}") from e

    data["propositions"] = props
    # Build by_id with last-wins semantics; duplicate detection moved to R8
    # (check_unique_ids) so the finding rendering pipeline can apply v1.2
    # display-ordinal formatting. Missing-id guard (#87): explicit
    # ValueError gets caught by main()'s handler → clean exit 2 (parse error)
    # instead of bare KeyError → exit 1 with traceback.
    by_id = {}
    for i, p in enumerate(props):
        if "id" not in p:
            raise ValueError(f"prop at index {i} missing required 'id' field")
        by_id[p["id"]] = p
    return data, props, by_id


def load_props(json_path: Path):
    """Load propositions JSON (legacy single-file form).

    Retained for fixtures still using the pre-JSONL layout. New code should
    prefer load_props_jsonl. main() auto-routes by file extension.
    """
    with json_path.open() as fp:
        data = json.load(fp)
    props = data.get("propositions", [])
    # Build by_id with last-wins semantics; duplicate detection moved to R8
    # (check_unique_ids) so the finding rendering pipeline can apply v1.2
    # display-ordinal formatting. Missing-id guard (#87): explicit
    # ValueError gets caught by main()'s handler → clean exit 2 (parse error)
    # instead of bare KeyError → exit 1 with traceback.
    by_id = {}
    for i, p in enumerate(props):
        if "id" not in p:
            raise ValueError(f"prop at index {i} missing required 'id' field")
        by_id[p["id"]] = p
    return data, props, by_id


def load_tex(tex_path: Path):
    """Load .tex as a single string + line-indexed map (1-based)."""
    with tex_path.open() as fp:
        text = fp.read()
    return text, text.splitlines()


def normalize_for_match(s: str) -> str:
    """Whitespace-collapsed string for verbatim comparison.

    LaTeX has \n line wraps that don't affect semantics. Collapse runs of
    whitespace (incl. newlines) to single spaces so a prop.text that's
    a single-line copy matches a multi-line .tex sentence.

    Math delimiter equivalence: \\[ \\] / \\begin{equation}...\\end{equation}
    / $ $ / $$ $$ all represent math mode and prop authors may use either
    when transcribing. Normalize all to canonical inline `$` for matching.
    Also strip `\\quad`, `\\,`, `\\;` and similar spacing macros and
    `\\text{...}` wrappers commonly used in display math that don't appear
    when prop.text uses inline form.
    """
    # 1. Strip ALL math-mode delimiters (display + inline) — math content stays
    #    but delimiter placement (which differs between prop's inline form and
    #    .tex's display form) is normalized out.
    s = re.sub(r"\\\[", " ", s)
    s = re.sub(r"\\\]", " ", s)
    s = re.sub(r"\\begin\{equation\*?\}", " ", s)
    s = re.sub(r"\\end\{equation\*?\}", " ", s)
    s = re.sub(r"\$\$", " ", s)
    s = re.sub(r"\$", " ", s)
    # 2. Strip math-mode spacing macros: \quad, \qquad, \,, \;, \!, \:
    s = re.sub(r"\\quad\b", " ", s)
    s = re.sub(r"\\qquad\b", " ", s)
    s = re.sub(r"\\[,;!:]", " ", s)
    # 3. Inline `\text{X}` → just X (literal text without macro)
    s = re.sub(r"\\text\{([^}]*)\}", r"\1", s)
    # 3a. Strip structural macros (paragraph / section / subsection / textbf):
    #     `\paragraph{Affine.}` → `Affine`, etc. Prop text often uses bare
    #     label form ("Affine:") while .tex uses paragraph form. Normalize
    #     both to plain content. Also strip trailing `.` in label form.
    s = re.sub(r"\\paragraph\{([^}]*?)\.?\}", r"\1", s)
    s = re.sub(r"\\subsection\{([^}]*)\}", r"\1", s)
    s = re.sub(r"\\section\*?\{([^}]*)\}", r"\1", s)
    s = re.sub(r"\\textbf\{([^}]*?)\.?\}", r"\1", s)
    s = re.sub(r"\\emph\{([^}]*)\}", r"\1", s)
    s = re.sub(r"\\textit\{([^}]*)\}", r"\1", s)
    # 3a.1. Strip LaTeX line comments `% ... <newline>` — these never
    #       appear in prop.text but pollute .tex normalized form.
    s = re.sub(r"%[^\n]*\n", "\n", s)
    # 3a.2. Strip `\item` / `\noindent` markers — list/section structure.
    s = re.sub(r"\\item\b\s*", "", s)
    s = re.sub(r"\\noindent\b\s*", "", s)
    # 3a.3. Strip `\begin{...}` / `\end{...}` environment markers (after
    #       the equation versions handled above). Other envs (itemize,
    #       enumerate, lemma, theorem, proof, align*) are scaffolding.
    s = re.sub(r"\\begin\{(itemize|enumerate|center|tabular|lemma|theorem|proof|abstract|document|align|gather|cases)\*?\}(?:\[[^\]]*\])?", "", s)
    s = re.sub(r"\\end\{(itemize|enumerate|center|tabular|lemma|theorem|proof|abstract|document|align|gather|cases)\*?\}", "", s)
    # 3a.3.1. Strip align-environment markers: `&=` → `=`, `\\` line cont,
    #         `&` alone → space.
    s = re.sub(r"&\s*=", "=", s)
    s = re.sub(r"\\\\\s*", " ", s)
    s = re.sub(r"\s&\s", " ", s)
    # 3a.4. (removed #140) Used to strip `Case (X)` / `Sub-case (X)` /
    #       `Note row N:` labels under the assumption that they only appeared
    #       prop-side as AI extraction artifacts. The Theorem-1 staging
    #       revision introduced 24+ literal `Case (X)` and `Sub-case (X)`
    #       occurrences directly into main.tex (formal case introductions
    #       like `\emph{Case (A): both $\rho$ and ...}`, inline narrative
    #       references, etc.), so stripping symmetrically from both sides
    #       removed meaningful content and collapsed short props like
    #       `"This is Case (D)."` to the degenerate fragment `"This is."`
    #       — the root cause behind #139's R13 false-positive that the
    #       degeneracy guard in `_find_start_anchor` had to defend against.
    #       Removed entirely; empirical run on the live 342-prop main.jsonl
    #       confirms zero R1/R3/R13 regressions and the #139 un-anchorable
    #       informational disappears (prop now anchors correctly).
    # 3a.5. Strip a leading "label: " pattern (single hyphenated word followed
    #       by colon-space). Prop text often writes "Log-root: u(y) = ..." but
    #       .tex (post `\textbf{}` strip) gives "Log-root u(y) = ...". Apply
    #       only at logical sentence starts (beginning of string or right after
    #       a period+space). Conservative: single hyphenated word only.
    s = re.sub(r"(^|\.\s+)([A-Za-z][\w\-]{2,30}):\s+(?=[A-Za-z\\])", r"\1\2 ", s)
    # 3a.6. Also strip multi-word labels with σ/ρ macros for case_split props:
    #       "σ-constant + log u, v: u = ..." → "σ-constant + log u, v u = ..."
    #       Targeted pattern: starts with σ/ρ unicode or backslash-sigma/rho,
    #       allows commas + words + spaces, ends at `:` before letter/macro.
    s = re.sub(r"(^|\.\s+)([σρ\\][\w\-, +\\σρ]{3,80}?):\s+(?=[a-zA-Z\\])", r"\1\2 ", s)
    # 3b. Strip `\citep[...]{X}` / `\citet[...]{X}` argument bracket
    #     (rare cases where prop omits the optional arg)
    # (Skip — both sides should preserve verbatim. Only strip if needed.)
    # 3c. Strip `\,` followed by punctuation collapse from step 5
    # 4. Final whitespace collapse (also handles double-spaces from delimiter strip)
    s = re.sub(r"\s+", " ", s.strip())
    # 5. Collapse space-before-punctuation (handles cases like `$ \pi $.` vs `\pi.`
    #    where stripping inline-$ leaves space, but display-$ end has none)
    s = re.sub(r"\s+([.,;:])", r"\1", s)
    # 6. Unicode Greek → LaTeX command. Some props author the Unicode char
    #    directly (σ, ρ, λ, ...) while .tex always uses LaTeX commands
    #    ($\sigma$, $\rho$, ...). Normalize both to the LaTeX form.
    greek_map = {
        # Greek lowercase
        "α": r"\alpha", "β": r"\beta", "γ": r"\gamma", "δ": r"\delta",
        "ε": r"\varepsilon", "ζ": r"\zeta", "η": r"\eta", "θ": r"\theta",
        "ι": r"\iota", "κ": r"\kappa", "λ": r"\lambda", "μ": r"\mu",
        "ν": r"\nu", "ξ": r"\xi", "π": r"\pi", "ρ": r"\rho",
        "σ": r"\sigma", "τ": r"\tau", "υ": r"\upsilon", "φ": r"\varphi",
        "χ": r"\chi", "ψ": r"\psi", "ω": r"\omega",
        # Greek uppercase
        "Γ": r"\Gamma", "Δ": r"\Delta", "Θ": r"\Theta", "Λ": r"\Lambda",
        "Ξ": r"\Xi", "Π": r"\Pi", "Σ": r"\Sigma", "Φ": r"\Phi",
        "Ψ": r"\Psi", "Ω": r"\Omega",
        # Math relations
        "≠": r"\neq", "≤": r"\leq", "≥": r"\geq", "≡": r"\equiv",
        "≈": r"\approx", "∼": r"\sim",
        # Set operators
        "∈": r"\in", "∉": r"\notin", "⊂": r"\subset", "⊃": r"\supset",
        "⊆": r"\subseteq", "⊇": r"\supseteq", "∪": r"\cup", "∩": r"\cap",
        "∅": r"\emptyset",
        # Arrows
        "→": r"\to", "←": r"\leftarrow", "↔": r"\leftrightarrow",
        "⇒": r"\Rightarrow", "⇐": r"\Leftarrow", "⇔": r"\Leftrightarrow",
        "↦": r"\mapsto",
        # Math constants
        "∞": r"\infty", "∂": r"\partial", "∇": r"\nabla",
        # Other operators
        "⋅": r"\cdot", "×": r"\times", "∘": r"\circ",
        "±": r"\pm", "∓": r"\mp", "·": r"\cdot",
    }
    for unicode_ch, latex_cmd in greek_map.items():
        # Replace unicode → latex command + space (mimics `$\sigma$` → `\sigma `)
        # Use lookahead to avoid double-spacing if next char is already space
        s = s.replace(unicode_ch, latex_cmd + " ")
    # Re-collapse whitespace after greek mapping (introduces extra spaces)
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s+([.,;:])", r"\1", s)
    return s


# --------- R1: prop-subset-check (Phase 1 partial-bijection) ---------


def check_iso(props, tex_string):
    """R1 prop-subset-check (Phase 1 partial-bijection).

    For each prop, verify prop.text appears as a substring in tex_string after
    normalization. This proves propositions ⊆ tex via substring proxy.

    LIMITATION (Phase 1): substring containment is NOT a verbatim bijection.
    Two props may both substring-match the same .tex sentence (violates
    injectivity). The complementary direction (every .tex claim region has
    ≥1 prop covering it — surjectivity) is checked in R1.5. Full bijection
    contract awaits Phase 2 clause-level re-extraction (see issue #77).

    Returns list of (prop_id, error_msg) tuples.
    """
    errors = []
    normalized_tex = normalize_for_match(tex_string)
    for p in props:
        text_norm = normalize_for_match(p["text"])
        if text_norm not in normalized_tex:
            errors.append((
                p["id"],
                f"text not found in .tex (location={p.get('location', '?')})"
            ))
    return errors


# --------- R1.5: surjective coverage (section-level, Phase 1) ---------


def _parse_location_range(loc):
    """Parse 'main.tex:L<start>-L<end>' or 'main.tex:L<line>' → (start, end).

    Returns (None, None) when unparseable (caller treats as no coverage).
    """
    m = re.match(r"[^:]+:L(\d+)(?:-L(\d+))?", loc or "")
    if not m:
        return None, None
    start = int(m.group(1))
    end = int(m.group(2)) if m.group(2) else start
    return start, end


def check_surjective_coverage(props, tex_string):
    """R1.5 surjective coverage at top-level section granularity.

    Find every top-level section command in tex; for each section [start, end]
    check that at least one prop's location overlaps the range. Sections with
    zero props → warning. Errors are NOT raised (Phase 1 heterogeneous-
    granularity prototype may legitimately under-extract some sections —
    see #77).

    Matches all top-level section variants:
        \\section{Title}              standard
        \\section*{Title}             unnumbered (e.g. Acknowledgments)
        \\section[short]{Title}       optional short title
        \\section*[short]{Title}      both forms combined

    Returns (errors, warnings) where errors is always empty in Phase 1.
    """
    section_pattern = re.compile(r"^\\section\*?(?:\[[^\]]*\])?\{", re.MULTILINE)
    sections = []
    lines = tex_string.split("\n")
    section_starts = [
        i + 1
        for i, line in enumerate(lines)
        if section_pattern.match(line)
    ]
    if not section_starts:
        return [], []
    total_lines = len(lines)
    for idx, start in enumerate(section_starts):
        end = (
            section_starts[idx + 1] - 1
            if idx + 1 < len(section_starts)
            else total_lines
        )
        title = lines[start - 1].strip()[:80]
        sections.append((start, end, title))

    warnings = []
    for start, end, title in sections:
        covered = False
        for p in props:
            p_start, p_end = _parse_location_range(p.get("location"))
            if p_start is None:
                continue
            if p_start <= end and p_end >= start:
                covered = True
                break
        if not covered:
            warnings.append((
                f"section:L{start}",
                f"no prop covers section (L{start}-{end}): {title}",
            ))
    return [], warnings


# --------- R2: cite resolve ---------


def check_cites(props_by_id):
    """R2: every cites entry MUST resolve to a sibling prop's id.

    Under schema v1.1 ids are P/C-prefix sequential strings; under schema v1.2+
    ids are canonical UUID v7. The resolution semantics are identical in both
    cases — string equality against props_by_id keys. Cites to non-existing
    ids (including legacy P-prefix strings appearing in a migrated v1.2 file)
    produce an undefined-cite finding. Schema-level format enforcement on the
    id field itself is handled by R7 (see check_id_format).
    """
    errors = []
    for pid, p in props_by_id.items():
        for cited in p.get("cites", []):
            if cited not in props_by_id:
                errors.append((pid, f"cites undefined {cited}"))
    return errors


# --------- R3: DAG + orphan ---------


def check_dag(props_by_id):
    """Cycle detection via DFS. Build reverse-cites map for orphan analysis."""
    errors = []
    warnings = []

    # Build adjacency: p_id -> list of cited p_ids
    graph = {pid: p.get("cites", []) for pid, p in props_by_id.items()}

    # Cycle detection (Tarjan-light: 3-color DFS)
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {pid: WHITE for pid in graph}

    def dfs(node, path):
        if color[node] == GRAY:
            cycle_start = path.index(node)
            errors.append((
                node,
                f"cycle: {' -> '.join(path[cycle_start:] + [node])}",
            ))
            return
        if color[node] == BLACK:
            return
        color[node] = GRAY
        for neighbor in graph[node]:
            if neighbor in graph:
                dfs(neighbor, path + [node])
        color[node] = BLACK

    for pid in graph:
        if color[pid] == WHITE:
            dfs(pid, [])

    # Orphan detection: prop is not cited by anything AND is not a structural
    # leaf type (axiom, definition, commentary, restatement, plus Phase 2
    # clause-level types).
    cited_by = defaultdict(set)
    for pid, cites in graph.items():
        for c in cites:
            cited_by[c].add(pid)

    # Structural leaf types: claim_types that legitimately do not get cited
    # because they ARE the cite anchors / structural glue, not derived claims.
    # Extended in #83 (Stage 2 prereq) for Phase 2 clause-level claim_types
    # — connective/reference/scope_qualifier carry no propositional content
    # of their own and should not warn R3 when they have no inbound cites.
    # #92: restatement added — restatement props re-state earlier claims and
    # are legitimately leaf-like in discussion contexts.
    # #112: case_split added — structural anchors (\item enumerate headers,
    # case-X intros). The case CONTENT (display_equation / claim that follow)
    # carries semantic dependencies, not the header.
    structural_leaf_types = {
        "axiom", "definition", "commentary", "restatement",
        # Phase 2 clause-level (#77 / #83):
        "connective", "reference", "scope_qualifier",
        # #112:
        "case_split",
    }
    for pid, p in props_by_id.items():
        if pid not in cited_by:
            ct = p.get("claim_type", "claim")
            # only warn for non-structural types
            if ct not in structural_leaf_types:
                warnings.append((
                    pid,
                    f"orphan: not cited by any other prop (claim_type={ct})",
                ))

    return errors, warnings


# --------- R4: mechanical contradictions ---------


def check_contradictions(props, props_by_id):
    """Phase 1 mechanical pattern matching for known invariant violations.

    Pattern A (#60 Theorem 1 boundary, #103 framework-aware refinement):
        IF there exists axiom prop with assert containing "eta(1,s) = s"
        AND that same axiom prop does NOT contain conditional-framework
            signal phrases (per CONDITIONAL_SIGNAL_PHRASES)
        AND there exists prop with hypothesis containing "eta(lambda,s) = f(s)"
        AND there exists case_split prop claiming "f may be any continuous"
        THEN violation (boundary forces f=id, contradicting case_split).

        Framework-aware short-circuit (#103, 2026-05-16):
        Post-#60 Path C the manuscript framework treats boundary conditions
        as conditional (per Doble-Hsu 2020 + Gselmann-Doble-Hsu 2025), not
        universal. The axiom prop's assert text now reads e.g. "Boundary
        conditions (η(1,s)=s, ...) are imposed locally in theorems that
        invoke them — not part of universal similarity definition (per
        DobleHsu2020 / GselmannDobleHsu2025 framework)". Regex still matches
        `η(1,s)=s` substring, so we additionally check whether the same
        axiom prop's asserts contain conditional-framework signal phrases.
        If so, the axiom is NOT asserting a universal boundary → PATTERN-A
        does not fire. See #103 + tests/test_validate_propositions.py
        ::TestR4PatternAFrameworkAware F1 (regression) + F2 (bug fix).

    Pattern B (#68 Track A without Track B): RETIRED 2026-05-14 (#73 Path A).
        Originally detected "Track A" mention without "Track B" counterpart
        to catch dichotomy orphans like #68. After #68 + #75 docs cleanup,
        PATTERN-B is dead-code-on-arrival (no remaining substantive Track A/B
        in main.tex; living docs preserve retired vocab inside frozen
        subregions per `code-and-manuscript-sync.md` exception). Retired per
        Path A decision in #73. SCHEMA.md §R4 marks deprecated.
        Validator no longer owns docs/ vocabulary surface — future drift
        addressed by `manuscript-consistency-audit.md` SOP audit-time
        detection (per SOP §5 trigger times: major rewrite, pre-submission,
        new phase). On-demand `./scripts/run-audit.sh manuscript/` runs the
        full R1+R2+R3 chain but does NOT specifically grep for Track A/B
        vocabulary — that remains an explicit human review step today.

    Pattern C (#61 H bijection coherence):
        Already encoded as evidence-bearing prop content (P011-P013); just
        sanity check the chain exists.

    Returns (errors, warnings).
    """
    errors = []
    warnings = []

    # Pattern A: boundary axiom + non-identity F hypothesis + extension claim
    # Round 2.5 (#72): patterns converted to whitespace-insensitive regex.
    # Round 1.5 (#80 verify F1): added `\b` word boundary to prevent substring
    # leak — without it, regex `eta` would match `theta` / `beta` / `zeta`,
    # false-firing PATTERN-A on unrelated symbols. Word boundary ensures the
    # match anchors on `eta` as a standalone token (preceded by start-of-string,
    # whitespace, or non-word like `\\`/`$`).
    # Disclosure (per /idd-verify --pr 70 round 1, /idd-verify --pr 80 round 1):
    # these are still hard-coded fingerprint substrings tuned for the #60
    # incident wording. Future boundary-axiom violations with different vocab
    # (e.g. "$f$ is unconstrained", `\\eta|_{\\lambda=1} = s`,
    # `\\eta(\\boldsymbol{1}, s) = s`) may MISS. Phase 2 #77 clause-level may
    # support SAT-style generalization. See #74 rollback_60_real for proof
    # that current regex catches the real historical state.
    boundary_re = re.compile(r"\beta\s*\(\s*1\s*,\s*s\s*\)\s*=\s*s", re.IGNORECASE)
    boundary_re_greek = re.compile(r"\bη\s*\(\s*1\s*,\s*s\s*\)\s*=\s*s")

    # #103 framework-aware signal phrases — if any axiom prop containing the
    # boundary substring ALSO contains one of these phrases in its asserts,
    # treat the axiom as conditional-framework (post-#60 Path C state per
    # DobleHsu2020 / GselmannDobleHsu2025), NOT a universal claim.
    # OR-of-N substrings (case-insensitive substring match) — robust to author
    # rephrasing as long as one canonical idiom remains. Future variants can
    # be added via separate PR; F1 regression test (rollback_60_real fixture)
    # protects against accidentally loosening detection.
    CONDITIONAL_SIGNAL_PHRASES = [
        "imposed locally",
        "invoked locally",
        "applied locally",
        "not part of universal",
        "not universal",
        "framework of \\citet{doblehsu",
        "per doblehsu2020",
        "per gselmanndoblehsu2025",
        "conditional boundary",
        "conditional in theorems",
    ]

    def _axiom_frames_conditionally(prop):
        """Return True if prop has at least one assert containing any
        conditional-framework signal phrase (case-insensitive substring)."""
        for a in prop.get("asserts", []):
            a_lower = a.lower()
            for phrase in CONDITIONAL_SIGNAL_PHRASES:
                if phrase in a_lower:
                    return True
        return False

    # Two-tier check: axiom-with-boundary-substring exists AND that axiom is
    # NOT framed conditionally.
    has_universal_boundary_eta = any(
        p.get("claim_type") == "axiom"
        and any(
            boundary_re.search(a) or boundary_re_greek.search(a)
            for a in p.get("asserts", [])
        )
        and not _axiom_frames_conditionally(p)
        for p in props
    )
    hypothesis_re = re.compile(r"\beta\s*\(\s*lambda\s*,\s*s\s*\)\s*=\s*f\s*\(\s*s\s*\)", re.IGNORECASE)
    hypothesis_re_greek = re.compile(r"\bη\s*\(\s*λ\s*,\s*s\s*\)\s*=\s*f\s*\(\s*s\s*\)")
    has_eta_eq_f_hypothesis = any(
        p.get("claim_type") == "hypothesis"
        and any(
            hypothesis_re.search(a) or hypothesis_re_greek.search(a)
            for a in p.get("asserts", [])
        )
        for p in props
    )
    # Extension claim: English prose, less likely to whitespace-vary
    has_f_extension_claim = any(
        any(
            "f may be any" in a.lower()
            or "any continuous map" in a.lower()
            or "f-extended" in a.lower()
            for a in p.get("asserts", [])
        )
        for p in props
    )
    if has_universal_boundary_eta and has_eta_eq_f_hypothesis and has_f_extension_claim:
        errors.append((
            "PATTERN-A",
            "boundary axiom η(1,s)=s + hypothesis η=f(s) + 'f may be any' claim "
            "→ contradiction: boundary forces f=id (Iverson framework)"
        ))

    # Pattern B: RETIRED 2026-05-14 per #73 Path A (see function docstring).
    # Dead-code-on-arrival after #68 + #75 docs cleanup eliminated Track A/B
    # vocabulary from manuscript + living docs. Future docs/ drift caught by
    # docs grep + audit chain instead.

    # Pattern C: H bijection coherence (sanity check Path A chain present)
    h_def_props = [
        p for p in props
        if "H" in p.get("introduces", [])
    ]
    if h_def_props:
        h_intro = h_def_props[0]
        # Verify the prop ALSO asserts boundary H(0) = 0
        has_boundary = any(
            "H(0) = 0" in a or "boundary" in a.lower()
            for a in h_intro.get("asserts", [])
        )
        if not has_boundary:
            warnings.append((
                h_intro["id"],
                f"H is introduced as bijection but no 'H(0) = 0' boundary "
                f"asserted — potential #61-style incoherence"
            ))

    return errors, warnings


# --------- main ---------


def check_unique_ids(props: list[dict]) -> list[tuple[str, str]]:
    """R8: every prop.id MUST be unique across the propositions list.

    Returns a list of (pid, msg) error tuples for any duplicated id. The id
    appears in the (pid, msg) tuple as the source prop id; the rendering
    pipeline in main() applies v1.2 display-ordinal formatting if enabled.
    """
    errors: list[tuple[str, str]] = []
    seen: dict[str, int] = {}
    for line_idx, prop in enumerate(props, start=1):
        pid = prop.get("id", "?")
        if pid in seen:
            first = seen[pid]
            errors.append(
                (
                    pid,
                    f"duplicate proposition id (also seen at entry {first}; "
                    f"current entry {line_idx})",
                )
            )
        else:
            seen[pid] = line_idx
    return errors


# --------- R9: containing_block-env consistency (#100) ---------
#
# LaTeX env parser imported from scripts/_lib/latex_env_parser.py (#115 M-5
# dedup; previously inline-copied per /idd-plan #100 DP1). Both this script
# and scripts/audit-theorem-boundaries.py now share the same parser module,
# eliminating the drift surface that propagated M-1 (greedy \ref) and M-2
# (inverted L<start>-L<end>) symmetrically through #100 Path B.
#
# Note: R9 calls `_r9_parse_envs_shared(tex_string, warn_on_residue=False)`
# (see check_r9_containing_block_env_consistency below) to keep stderr clean —
# audit-script is the CI gate caller that should surface unmatched \begin
# warnings; R9 is informational ([PASS]/[WARN]) so the stderr noise would
# confuse output parsers.


def check_r9_containing_block_env_consistency(
    props: list[dict], tex_string: str
) -> tuple[list[tuple[str, str]], int, dict[str, int]]:
    """R9: assert prop.location ⊆ env line range for theorem-like cb (#100).

    Per /idd-plan #100 DP4 (WARN-as-baseline): returns warnings list, never
    errors. Caller uses warning count for exit code 0 (informational).

    Returns:
        (warnings, env_count, stats)
        - warnings: list of (pid, msg) for props whose location escapes its
          declared env range
        - env_count: total theorem-like envs parsed (0 → silent skip per DP6)
        - stats: skip-transparency counters (#116) — `checked` (props that
          reached the containment check), `skipped_non_main_tex` (location
          lacks a `main.tex:` prefix R9 can parse), `skipped_malformed_loc`
          (location has a `main.tex:` prefix but an inverted / zero-base
          range rejected by `_r9_parse_location` per #100 Path B)
    """
    stats = {"checked": 0, "skipped_non_main_tex": 0, "skipped_malformed_loc": 0}
    if not tex_string:
        return ([], 0, stats)
    # #115 M-4: R9 is informational ([PASS]/[WARN]) — pass warn_on_residue=False
    # so unmatched \begin doesn't fire stderr noise that would confuse output
    # parsers. The audit-script (`audit-theorem-boundaries.py --jsonl`) keeps
    # the default True and is the loud CI-gate caller.
    envs = _r9_parse_envs_shared(tex_string, warn_on_residue=False)
    associated = _r9_build_associated(envs)
    if not associated:
        return ([], 0, stats)  # DP6 silent skip when no theorem-like envs

    warnings: list[tuple[str, str]] = []
    for prop in props:
        cb_raw = prop.get("containing_block", "")
        loc_raw = prop.get("location", "")
        if not cb_raw or not loc_raw:
            continue  # DP7 schema field presence is R3's job
        label = _r9_normalize_containing_block(cb_raw)
        if label not in associated:
            continue  # DP6 non-env cb (sec:*/discussion/abstract) silent skip
        # #116: classify by a strict `main.tex:` prefix BEFORE parsing. R9 only
        # checks main.tex locations; a non-main.tex location is skipped and
        # counted. The prefix gate must precede _r9_parse_location() because
        # the shared LOC_RE (in scripts/_lib/latex_env_parser.py) uses a
        # non-anchored `.search()` — a non-main location whose string merely
        # *contains* `main.tex:` (`not_main.tex:L12`, `chapters/main.tex:L12`)
        # would otherwise parse via the embedded substring and be miscounted
        # as `checked` (Codex /idd-verify #116).
        if not loc_raw.startswith("main.tex:"):
            stats["skipped_non_main_tex"] += 1
            continue
        loc_range = _r9_parse_location(loc_raw)
        if loc_range is None:
            # has a `main.tex:` prefix but a malformed range (inverted /
            # zero-base, rejected by _r9_parse_location per #100 Path B).
            # Counter-only — no WARN escalation (#116 scope boundary).
            stats["skipped_malformed_loc"] += 1
            continue
        stats["checked"] += 1
        l_start, l_end = loc_range
        allowed = associated[label]
        ok = any(
            env["begin_line"] <= l_start and l_end <= env["end_line"]
            for env in allowed
        )
        if not ok:
            allowed_str = ", ".join(
                f"{env['type']}:L{env['begin_line']}-L{env['end_line']}"
                for env in allowed
            )
            pid = prop.get("id", "?")
            warnings.append(
                (
                    pid,
                    f"R9: prop containing_block={cb_raw!r} location={loc_raw} "
                    f"outside env [{allowed_str}]",
                )
            )
    return (warnings, len(associated), stats)


# --------- R10: claim_type vs asserts compatibility (#90) ---------
#
# Phase 2 LLM mistag guard. R3 exempts `structural_leaf_types`
# (connective / reference / scope_qualifier) from the orphan check —
# but the exemption applies REGARDLESS of `asserts` content. A
# content-bearing prop mistagged as `connective` (e.g. "Hence,
# F = id" carrying a real equality assertion) slips past R1 + R3.
# Per SCHEMA.md, `connective` / `reference` are pure structural glue
# with empty `asserts`; non-empty is either schema misuse or LLM mistag.
# `scope_qualifier` is intentionally NOT in `must_be_empty` — these props
# typically carry 1 short assert documenting the scope.

_R10_MUST_BE_EMPTY = frozenset({"connective", "reference"})


def check_r10_claim_type_asserts_consistency(
    props: list[dict],
) -> list[tuple[str, str]]:
    """R10: connective / reference claim_types must have empty asserts (#90).

    Phase 2 LLM mistag guard. Returns errors (FAIL severity, exit 1) — no
    WARN-as-baseline policy, both `main.jsonl` and `_stage2/theorem1.jsonl`
    baselines are clean as of #90.

    Returns:
        errors: list of (pid, msg) for props violating the must_be_empty
        contract.
    """
    errors: list[tuple[str, str]] = []
    for prop in props:
        ct = prop.get("claim_type")
        if ct not in _R10_MUST_BE_EMPTY:
            continue
        asserts = prop.get("asserts") or []
        if len(asserts) > 0:
            pid = prop.get("id", "?")
            errors.append(
                (
                    pid,
                    f"R10: claim_type={ct} requires empty asserts "
                    f"(got {len(asserts)} assert(s))",
                )
            )
    return errors


# --------- R11: evidence_class enum membership (#119) ---------
#
# SCHEMA.md defines `evidence_class` as a closed 5-element enum but
# prose-only — no rule enforced membership. R10 guards the symmetric
# `claim_type`/`asserts` compatibility; R11 is its counterpart for the
# `evidence_class` enum. The Phase 2 clause-level LLM extractor
# hallucinated out-of-enum values (`definitional`, `claim`) that slipped
# past R1-R10. Schema-gated v1.2+ (mirrors R7) for legacy backward-compat.

_R11_ALLOWED_EVIDENCE_CLASS = frozenset(
    {"verified", "derived", "hypothesized", "conventional", "open"}
)


def check_r11_evidence_class_enum(
    data: dict | None, props: list[dict]
) -> tuple[bool, list[tuple[str, str]]]:
    """R11 v1.2+ evidence_class enum membership check (#119).

    Returns (skipped, errors). When the schema_version in `data` (read from
    _meta.json) is less than 1.2 or absent, the check is skipped. Under v1.2+
    every prop's `evidence_class` MUST be a member of the canonical enum
    (`verified | derived | hypothesized | conventional | open`). FAIL severity
    (exit 1) — symmetric to R10, no WARN-as-baseline policy.
    """
    schema_version = (data or {}).get("schema_version") or ""
    if not schema_version or not _version_at_least(schema_version, "1.2"):
        return True, []

    errors: list[tuple[str, str]] = []
    for prop in props:
        # R11 validates the value when present; absence is not an enum
        # violation (whether evidence_class is mandatory is a separate
        # concern R11 does not adjudicate).
        if "evidence_class" not in prop:
            continue
        ec = prop.get("evidence_class")
        if ec not in _R11_ALLOWED_EVIDENCE_CLASS:
            pid = prop.get("id", "?")
            errors.append(
                (
                    pid,
                    f"R11: evidence_class={ec!r} is not in the canonical enum "
                    "{verified, derived, hypothesized, conventional, open}",
                )
            )
    return False, errors


# --------- R12: claim_type enum membership (#124) ---------
#
# SCHEMA.md defines `claim_type` as a closed 12-element enum but prose-only —
# no rule enforced membership. R10 guards the symmetric claim_type↔asserts
# compatibility (only for `connective`/`reference` subset); R11 guards the
# evidence_class enum. R12 is the claim_type-enum counterpart: an extractor
# that hallucinates a non-canonical claim_type (the failure mode #119
# documented for evidence_class) would mis-route R3's structural_leaf_types
# exemption silently. Schema-gated v1.2+ (mirrors R7 + R11).

_R12_ALLOWED_CLAIM_TYPE = frozenset(
    {
        "axiom",
        "definition",
        "hypothesis",
        "claim",
        "case_split",
        "display_equation",
        "restatement",
        "commentary",
        "example",
        "connective",
        "reference",
        "scope_qualifier",
    }
)


def check_r12_claim_type_enum(
    data: dict | None, props: list[dict]
) -> tuple[bool, list[tuple[str, str]]]:
    """R12 v1.2+ claim_type enum membership check (#124).

    Returns (skipped, errors). When the schema_version in `data` (read from
    _meta.json) is less than 1.2 or absent, the check is skipped. Under v1.2+
    every prop's `claim_type` MUST be a member of the canonical 12-element
    enum (`axiom | definition | hypothesis | claim | case_split |
    display_equation | restatement | commentary | example | connective |
    reference | scope_qualifier`). FAIL severity (exit 1) — symmetric to R10
    + R11, no WARN-as-baseline policy.
    """
    schema_version = (data or {}).get("schema_version") or ""
    if not schema_version or not _version_at_least(schema_version, "1.2"):
        return True, []

    errors: list[tuple[str, str]] = []
    for prop in props:
        # R12 validates the value when present; absence is not an enum
        # violation (whether claim_type is mandatory is R3's call via its
        # `.get("claim_type", "claim")` default, not R12's concern).
        if "claim_type" not in prop:
            continue
        ct = prop.get("claim_type")
        if ct not in _R12_ALLOWED_CLAIM_TYPE:
            pid = prop.get("id", "?")
            errors.append(
                (
                    pid,
                    f"R12: claim_type={ct!r} is not in the canonical enum "
                    "{axiom, definition, hypothesis, claim, case_split, "
                    "display_equation, restatement, commentary, example, "
                    "connective, reference, scope_qualifier}",
                )
            )
    return False, errors


# --------- R13: location line-anchoring (verify-tex-prop-correspondence) ---------

# Single-line `location` start-anchor parameters. R13_MAX_SPAN bounds the
# forward window scanned to locate a proposition's true starting line;
# R13_START_TOLERANCE is the inclusive line-delta allowed between the declared
# single-line `location` and the text's true start before a drift WARN fires.
# Calibrated against manuscript/propositions/main.jsonl (2026-05-19,
# verify-tex-prop-correspondence task 1.5): at R13_START_TOLERANCE = 2 all 88
# single-line-location props anchor with zero false-positive WARN, so the
# default needed no adjustment.
R13_MAX_SPAN = 30
R13_START_TOLERANCE = 2


def _location_is_range(loc):
    """True when `loc` is the range form `<file>:L<a>-L<b>`; False for the
    single-line form `<file>:L<a>` (interpreted as a start-anchor)."""
    return bool(re.search(r":L\d+-L\d+", loc or ""))


def _find_start_anchor(text_norm, lines, declared_start):
    """True starting line of a single-line-form proposition's text.

    Scans candidate start lines `s` in [declared-R13_MAX_SPAN, declared+
    R13_MAX_SPAN]. Among the `s` whose forward window of R13_MAX_SPAN lines
    still contains `text_norm`, the true start is the largest such `s`: once
    `s` advances past the real start the text's head leaves the window, so the
    last `s` that still contains it is exactly where the text begins.

    The "largest s is the true start" invariant assumes `text_norm` uniquely
    identifies a single location within the scan range. When normalization
    collapses the prop to a high-frequency fragment (e.g., `normalize_for_match`
    strips `Case (X)` labels so `"This is Case (D)."` → `"This is."`, which
    matches every `"This is X."` sentence in the manuscript), the hit set fills
    the entire scan window and picking the largest is fictional. A degeneracy
    guard catches this case: when hits span more than R13_MAX_SPAN source
    lines, the anchor is ambiguous and we return None instead of fabricating
    a drift signal. The caller routes None to the un-anchorable list
    (informational), not the drift WARN list (#139).

    Returns the true start line, or None when no window contains the text
    (un-anchorable — the source span exceeds R13_MAX_SPAN, the text has drifted
    beyond the scan range, or the normalized anchor is too generic to
    discriminate; surfaced distinctly elsewhere).
    """
    lo = max(1, declared_start - R13_MAX_SPAN)
    hi = declared_start + R13_MAX_SPAN
    hits = []
    for s in range(lo, hi + 1):
        window = normalize_for_match("\n".join(lines[s - 1:s - 1 + R13_MAX_SPAN]))
        if text_norm in window:
            hits.append(s)
    if not hits:
        return None
    # Degeneracy guard (#139): hits spanning more than one MAX_SPAN window means
    # the anchor matched in unrelated regions of the scan range — not the
    # textbook "one true location plus its forward shadow". Return None so the
    # caller treats this as un-anchorable (informational), not as drift.
    if hits[-1] - hits[0] > R13_MAX_SPAN:
        return None
    return hits[-1]


def check_location_anchoring(props, tex_string):
    """R13 location line-anchoring.

    For each prop whose normalized text IS present in tex_string (so R1's
    whole-file substring check passes), verify it is anchored to its declared
    `location`:

    - Range form `L<a>-L<b>`: the normalized text must fall within the
      lines[a..b] slice (exact-slice).
    - Single-line form `L<a>`: start-anchor — `L<a>` names where the text
      begins, not the only line it occupies. The text's true starting line
      must be within R13_START_TOLERANCE of the declared line a.

    This catches the #106 drift class that R1 cannot see: prop.text is present
    somewhere in .tex, but the `location` field points at the wrong lines.

    WARN-as-baseline (mirrors R9 DP4): drift findings are warnings, exit code
    stays 0. The current main.jsonl carries known location drift; escalation
    to error is a follow-up after a cleanup pass.

    A prop is reported as *un-anchorable* — a distinct informational finding,
    NOT a drift warning — when its `location` is missing / malformed / inverted,
    or, for the single-line form, when its text cannot be anchored within the
    R13_MAX_SPAN scan window (source span exceeds the window, or drift exceeds
    ±R13_MAX_SPAN). Un-anchorable props are skipped from the drift check rather
    than mis-flagged as wrong-line. Props whose text is absent from .tex (an R1
    failure) are skipped silently.

    Returns (warnings, unanchorable): two lists of (prop_id, msg) tuples.
    """
    lines = tex_string.split("\n")
    normalized_tex = normalize_for_match(tex_string)
    warnings = []
    unanchorable = []
    for p in props:
        text_norm = normalize_for_match(p.get("text", ""))
        if not text_norm:
            continue  # empty text — nothing to anchor
        if text_norm not in normalized_tex:
            continue  # absent everywhere — an R1 failure, not R13's
        loc = p.get("location")
        start, end = _parse_location_range(loc)
        if start is None or start < 1 or end < start:
            unanchorable.append((
                p["id"],
                f"location missing or malformed ({loc!r}) — "
                f"skipped from drift check",
            ))
            continue
        if _location_is_range(loc):
            slice_norm = normalize_for_match("\n".join(lines[start - 1:end]))
            if text_norm not in slice_norm:
                warnings.append((
                    p["id"],
                    f"text not within declared location range "
                    f"{loc} (present in .tex but outside L{start}-L{end})",
                ))
        else:
            true_start = _find_start_anchor(text_norm, lines, start)
            if true_start is None:
                unanchorable.append((
                    p["id"],
                    f"single-line location {loc}: text un-anchorable within "
                    f"±{R13_MAX_SPAN} lines (source span exceeds the scan "
                    f"window, or drift exceeds the scan range) — skipped "
                    f"from drift check",
                ))
            elif abs(true_start - start) > R13_START_TOLERANCE:
                warnings.append((
                    p["id"],
                    f"text starts at L{true_start}, declared L{start} "
                    f"(single-line start-anchor drift)",
                ))
    return warnings, unanchorable


def derive_view_ordinals(jsonl_path: Path) -> list[tuple[str, str]]:
    """Compute view-time display ordinals for every prop in `jsonl_path`.

    Returns a list of (display, uuid) tuples in canonical sort order. The sort
    key is `(containing_block, file_position)` ascending, where `file_position`
    is the prop's 0-based index in source-reading order within the JSONL file;
    ordinals are 1-based positions in sort order, zero-padded to 3 digits. The
    prefix is `C` when the path contains the `_stage2/` segment, otherwise `P`.

    Spec capability: propositions-schema — Requirement
    "View-time ordinal derivation MUST be deterministic".
    """
    props: list[dict] = []
    with jsonl_path.open() as fp:
        for line_no, raw in enumerate(fp, 1):
            line = raw.strip()
            if not line or line.startswith("//"):
                continue
            try:
                props.append(json.loads(line))
            except json.JSONDecodeError as e:
                raise ValueError(f"{jsonl_path}:{line_no}: parse error: {e}") from e

    # schema v1.3 — sentence_index / clause_index removed; proposition order is
    # the JSONL file line order. file_position is the 0-based read-order index.
    sorted_props = sorted(
        enumerate(props),
        key=lambda item: (item[1].get("containing_block", ""), item[0]),
    )
    prefix = "C" if "_stage2" in jsonl_path.parts else "P"
    return [
        (f"{prefix}{idx:03d}", prop["id"])
        for idx, (_file_pos, prop) in enumerate(sorted_props, start=1)
    ]


def cmd_view_ordinal(argv: list[str]) -> int:
    """`view-ordinal <path> [--uuid <uuid>]` subcommand entry point."""
    parser = argparse.ArgumentParser(
        prog="validate-propositions.py view-ordinal",
        description="Derive view-time display ordinals for a propositions JSONL file.",
    )
    parser.add_argument("path", type=Path, help="JSONL file path")
    parser.add_argument(
        "--uuid",
        default=None,
        help="If given, print the display ordinal for this UUID only",
    )
    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"✗ JSONL not found: {args.path}", file=sys.stderr)
        return 2

    try:
        mapping = derive_view_ordinals(args.path)
    except ValueError as exc:
        print(f"✗ {exc}", file=sys.stderr)
        return 2

    if args.uuid is None:
        for display, uid in mapping:
            print(f"{display} {uid}")
        return 0

    for display, uid in mapping:
        if uid == args.uuid:
            print(display)
            return 0
    print(f"✗ UUID {args.uuid} not present in {args.path}", file=sys.stderr)
    return 1


def check_id_format(data: dict | None, props: list[dict]) -> tuple[bool, list[tuple[str, str]]]:
    """R7 v1.2+ id-format check.

    Returns (skipped, errors). When the schema_version in `data` (read from
    _meta.json) is less than 1.2 or absent, the check is skipped and an empty
    error list is returned (with skipped=True). Under v1.2+ each prop.id MUST
    match canonical UUID v7 layout and MUST NOT carry any parallel identifier
    field (display_id / P_id / ordinal / serial).
    """
    schema_version = (data or {}).get("schema_version") or ""
    if not schema_version or not _version_at_least(schema_version, "1.2"):
        return True, []

    errors: list[tuple[str, str]] = []
    for prop in props:
        pid = prop.get("id", "")
        if not isinstance(pid, str) or not UUID_V7_REGEX.match(pid):
            errors.append(
                (
                    pid or "?",
                    f"id field {pid!r} is not a canonical UUID v7 "
                    "(schema v1.2+ requires lowercased 8-4-4-4-12 hex with version field `7`)",
                )
            )
        for forbidden in FORBIDDEN_PARALLEL_ID_FIELDS:
            if forbidden in prop:
                errors.append(
                    (
                        pid or "?",
                        f"forbidden parallel identifier field {forbidden!r} present "
                        "(schema v1.2+ stores only `id`; display ordinals are derived at view time)",
                    )
                )
    return False, errors


def main():
    # Subcommand dispatch: if first positional arg matches a known subcommand,
    # delegate. Preserves backward compat for the default validation invocation
    # (no subcommand → existing argparse-driven flow below).
    argv = sys.argv[1:]
    if argv and argv[0] == "view-ordinal":
        sys.exit(cmd_view_ordinal(argv[1:]))

    parser = argparse.ArgumentParser(description=__doc__)
    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--jsonl", default=None, help="propositions JSONL path (new format)"
    )
    source_group.add_argument(
        "--json",
        default=None,
        help="(legacy) single-file JSON path; mutually exclusive with --jsonl",
    )
    parser.add_argument(
        "--meta", default=None, help="metadata sidecar (_meta.json)"
    )
    parser.add_argument("--tex", default=str(DEFAULT_TEX), help="manuscript .tex path")
    parser.add_argument("--strict", action="store_true", help="warnings fail")
    args = parser.parse_args()

    # Route by which flag the caller provided. --json and --jsonl are mutually
    # exclusive at argparse level (#85), so only one can be set. Remaining
    # precedence: explicit flag > default JSONL (if exists) > default JSON
    # (legacy fallback for repos mid-migration).
    use_jsonl = False
    if args.json is not None:
        source_path = Path(args.json)
        meta_path = None
    elif args.jsonl is not None:
        source_path = Path(args.jsonl)
        meta_path = Path(args.meta) if args.meta else None
        use_jsonl = True
    elif DEFAULT_JSONL.exists():
        source_path = DEFAULT_JSONL
        meta_path = DEFAULT_META if DEFAULT_META.exists() else None
        use_jsonl = True
    else:
        source_path = DEFAULT_JSON
        meta_path = None

    tex_path = Path(args.tex)
    if not source_path.exists():
        print(f"✗ propositions source not found: {source_path}", file=sys.stderr)
        sys.exit(2)
    if not tex_path.exists():
        print(f"✗ .tex not found: {tex_path}", file=sys.stderr)
        sys.exit(2)

    try:
        if use_jsonl:
            data, props, props_by_id = load_props_jsonl(source_path, meta_path)
        else:
            data, props, props_by_id = load_props(source_path)
    except (ValueError, json.JSONDecodeError) as e:
        print(f"✗ parse error: {e}", file=sys.stderr)
        sys.exit(2)

    tex_string, _ = load_tex(tex_path)

    print(f"=== validate-propositions ===")
    fmt = "JSONL" if use_jsonl else "JSON"
    print(f"{fmt}: {source_path}")
    if use_jsonl and meta_path:
        print(f"Meta: {meta_path}")
    print(f"TeX:  {tex_path}")
    print(f"Props: {len(props)}")
    print()

    all_errors = []
    all_warnings = []

    # R1 prop-subset-check (Phase 1 partial-bijection; full bijection awaits #77)
    iso_errors = check_iso(props, tex_string)
    if iso_errors:
        all_errors.extend([("R1", *e) for e in iso_errors])
    else:
        print("[PASS] R1 prop-subset-check — all prop.text found in .tex (Phase 1; see #77 for full bijection)")

    # R1.5 surjective coverage at top-level section granularity
    surj_errors, surj_warnings = check_surjective_coverage(props, tex_string)
    if surj_errors:
        all_errors.extend([("R1.5", *e) for e in surj_errors])
    elif surj_warnings:
        all_warnings.extend([("R1.5", *w) for w in surj_warnings])
        print(f"[WARN] R1.5 surjective coverage — {len(surj_warnings)} section(s) without prop coverage")
    else:
        print("[PASS] R1.5 surjective coverage — every top-level section has ≥1 prop")

    # R2 cite resolve
    cite_errors = check_cites(props_by_id)
    if cite_errors:
        all_errors.extend([("R2", *e) for e in cite_errors])
    else:
        print("[PASS] R2 cite-resolve — all cites resolve")

    # R3 DAG + orphan
    dag_errors, dag_warnings = check_dag(props_by_id)
    if dag_errors:
        all_errors.extend([("R3", *e) for e in dag_errors])
    else:
        print("[PASS] R3 DAG — no cycles")
    if dag_warnings:
        all_warnings.extend([("R3", *w) for w in dag_warnings])

    # R4 mechanical contradictions
    contra_errors, contra_warnings = check_contradictions(props, props_by_id)
    if contra_errors:
        all_errors.extend([("R4", *e) for e in contra_errors])
    else:
        print("[PASS] R4 mechanical-contradiction — no known pattern violations")
    if contra_warnings:
        all_warnings.extend([("R4", *w) for w in contra_warnings])

    # R7 v1.2+ id-format (Spectra change migrate-prop-id-to-stable-uuid)
    r7_skipped, r7_errors = check_id_format(data, props)
    if r7_errors:
        all_errors.extend([("R7", *e) for e in r7_errors])
    elif r7_skipped:
        print("[SKIP] R7 id-format — schema_version < 1.2 (backward compat during migration)")
    else:
        print("[PASS] R7 id-format — every prop.id is canonical UUID v7, no parallel id field")

    # R8 unique-ids (Spectra change migrate-prop-id-to-stable-uuid)
    r8_errors = check_unique_ids(props)
    if r8_errors:
        all_errors.extend([("R8", *e) for e in r8_errors])
    else:
        print("[PASS] R8 unique-ids — every prop.id is unique within file")

    # R9 containing_block-env consistency (#100)
    # WARN-as-baseline per /idd-plan #100 DP4 — accommodates 14 known
    # main.jsonl drift props tracked as #114 cleanup follow-up. Exit 0
    # preserved; future PR can escalate to ERROR after #114 cleanup.
    r9_warnings, r9_env_count, r9_stats = check_r9_containing_block_env_consistency(
        props, tex_string
    )
    if r9_env_count == 0:
        print("[SKIP] R9 env-consistency — no theorem-like envs in tex (or empty)")
    elif r9_warnings:
        all_warnings.extend([("R9", *w) for w in r9_warnings])
        print(
            f"[WARN] R9 env-consistency — {len(r9_warnings)} prop(s) "
            f"outside env boundaries (see #114 known drift)"
        )
    else:
        print(
            f"[PASS] R9 env-consistency — all props within their declared "
            f"theorem-like env boundaries ({r9_env_count} envs checked)"
        )
    # #116: surface props R9 skipped instead of leaving them silently bypassed.
    if r9_env_count > 0:
        print(
            f"[summary] R9 — checked={r9_stats['checked']} "
            f"skipped_non_main_tex={r9_stats['skipped_non_main_tex']} "
            f"skipped_malformed_loc={r9_stats['skipped_malformed_loc']}"
        )

    # R10 claim_type vs asserts compatibility (#90)
    # FAIL severity (no WARN-as-baseline policy) — both main.jsonl and
    # _stage2/theorem1.jsonl baselines are clean as of #90, so a violation
    # signals a real Stage 2 LLM mistag or schema misuse to fix.
    r10_errors = check_r10_claim_type_asserts_consistency(props)
    if r10_errors:
        all_errors.extend([("R10", *e) for e in r10_errors])
        print(
            f"[FAIL] R10 claim-type-asserts — {len(r10_errors)} prop(s) "
            f"violate must_be_empty contract (connective/reference must "
            f"have empty asserts)"
        )
    else:
        print(
            "[PASS] R10 claim-type-asserts — connective/reference props "
            "all have empty asserts (scope_qualifier exempt)"
        )

    # R11 evidence_class enum membership (#119)
    # Schema-gated v1.2+ (mirrors R7). FAIL severity — symmetric to R10.
    r11_skipped, r11_errors = check_r11_evidence_class_enum(data, props)
    if r11_errors:
        all_errors.extend([("R11", *e) for e in r11_errors])
        print(
            f"[FAIL] R11 evidence-class-enum — {len(r11_errors)} prop(s) "
            f"carry a non-canonical evidence_class value"
        )
    elif r11_skipped:
        print("[SKIP] R11 evidence-class-enum — schema_version < 1.2 (backward compat)")
    else:
        print(
            "[PASS] R11 evidence-class-enum — all props use a canonical "
            "evidence_class (verified/derived/hypothesized/conventional/open)"
        )

    # R12 claim_type enum membership (#124)
    # Schema-gated v1.2+ (mirrors R7 + R11). FAIL severity — symmetric to R10 + R11.
    r12_skipped, r12_errors = check_r12_claim_type_enum(data, props)
    if r12_errors:
        all_errors.extend([("R12", *e) for e in r12_errors])
        print(
            f"[FAIL] R12 claim-type-enum — {len(r12_errors)} prop(s) "
            f"carry a non-canonical claim_type value"
        )
    elif r12_skipped:
        print("[SKIP] R12 claim-type-enum — schema_version < 1.2 (backward compat)")
    else:
        print(
            "[PASS] R12 claim-type-enum — all props use a canonical claim_type "
            "(12-element enum per SCHEMA.md)"
        )

    # R13 location line-anchoring (verify-tex-prop-correspondence)
    # WARN-as-baseline (mirrors R9 DP4): main.jsonl carries known location
    # drift; drift findings surface as warnings, exit code stays 0. A follow-up
    # cleanup pass can escalate to error. Un-anchorable props (missing/malformed
    # location, or single-line text the scan window cannot anchor) surface as a
    # distinct [summary] informational line — not warnings, not exit-affecting —
    # so they are never mis-flagged as drift.
    r13_warnings, r13_unanchorable = check_location_anchoring(props, tex_string)
    if r13_warnings:
        all_warnings.extend([("R13", *w) for w in r13_warnings])
        print(
            f"[WARN] R13 location-anchoring — {len(r13_warnings)} prop(s) "
            f"with text outside their declared location range"
        )
    else:
        print("[PASS] R13 location-anchoring — no location drift detected")
    if r13_unanchorable:
        print(
            f"[summary] R13 — {len(r13_unanchorable)} prop(s) un-anchorable "
            f"(skipped from drift check, not drift):"
        )
        for prop_id, reason in r13_unanchorable:
            print(f"    {prop_id} — {reason}")

    print()

    # Under schema v1.2+, replace prop UUIDs in finding-output with derived
    # display ordinals (Task 2.4). The UUID stays in the message body where
    # applicable (e.g. R2 "cites undefined <uuid>") so audit readers still see
    # the machine-readable reference. For v1.1 or missing schema, finding text
    # is reported as-is (legacy behavior).
    uuid_to_display: dict[str, str] = {}
    if use_jsonl and data and _version_at_least(data.get("schema_version") or "", "1.2"):
        for display, uid in derive_view_ordinals(source_path):
            uuid_to_display[uid] = display

    def render_pid(pid: str) -> str:
        display = uuid_to_display.get(pid)
        if display:
            # Show "P037 (01910b9c-...)" so both axes of identity are visible
            return f"{display} ({pid})"
        return pid

    def render_msg(msg: str) -> str:
        """For R2-style 'cites undefined <uuid>' messages, replace the bare
        'undefined' phrasing with the spec's 'missing UUID' verbiage when v1.2."""
        if uuid_to_display:
            return msg.replace("cites undefined ", "cites missing UUID ")
        return msg

    # Report
    if all_warnings:
        print(f"=== {len(all_warnings)} WARNING(s) ===")
        for rule, pid, msg in all_warnings:
            print(f"  [{rule}] {render_pid(pid)}: {render_msg(msg)}")
        print()

    if all_errors:
        print(f"=== {len(all_errors)} ERROR(s) ===")
        for rule, pid, msg in all_errors:
            print(f"  [{rule}] {render_pid(pid)}: {render_msg(msg)}")
        print()
        sys.exit(1)

    if all_warnings and args.strict:
        print("✗ --strict: warnings cause failure")
        sys.exit(1)

    print("✓ ALL VALIDATION CHECKS PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
