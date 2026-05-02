#!/bin/bash
# doc-update-config.sh — shared config loader for doc-tools hooks
#
# Three-tier injection (precedence high → low):
#   1. <repo>/.claude/doc-tools.json    — per-project override
#   2. ~/.cache/doc-tools/config.json   — per-machine override
#   3. built-in defaults                — defined in this file
#
# Plus kill-switch:
#   ~/.cache/doc-tools/disabled         — touch this file → hook short-circuits to exit 0
#
# Usage (sourced by hook scripts):
#   source "$CLAUDE_PLUGIN_ROOT/scripts/doc-update-config.sh"
#   load_doc_tools_config "$CLAUDE_PROJECT_DIR"
#   # Now exposed:
#   #   $CFG_ENABLED                — "true" or "false"
#   #   $CFG_MIN_CHANGED_FILES      — integer
#   #   $CFG_CODE_EXTENSIONS_REGEX  — pre-built grep regex like "\\.(R|sh|py|...)$"
#   #   $CFG_DOC_FILES_REGEX        — pre-built grep regex like "(CHANGELOG\\.md|README\\.md|...)"
#   #   $CFG_SKIP_PATHS             — newline-delimited glob patterns
#
# Disabled flag check:
#   is_doc_tools_disabled && exit 0  # short-circuit pattern

set -u

# ---------------------------------------------------------------------------
# Defaults — keep in sync with references/doc-update-design.md
# ---------------------------------------------------------------------------

DEFAULT_ENABLED="true"
DEFAULT_MIN_CHANGED_FILES=3
DEFAULT_CODE_EXTENSIONS=(R sh sql py ts tsx js jsx css swift go rs kt java c cpp h)
DEFAULT_DOC_FILES=(CHANGELOG.md README.md CLAUDE.md changelog/)
DEFAULT_SKIP_PATHS=()

# ---------------------------------------------------------------------------
# Public functions
# ---------------------------------------------------------------------------

is_doc_tools_disabled() {
  [ -f "$HOME/.cache/doc-tools/disabled" ]
}

load_doc_tools_config() {
  local project_dir="${1:-}"

  # Initialize with defaults
  CFG_ENABLED="$DEFAULT_ENABLED"
  CFG_MIN_CHANGED_FILES="$DEFAULT_MIN_CHANGED_FILES"
  local code_exts=("${DEFAULT_CODE_EXTENSIONS[@]}")
  local doc_files=("${DEFAULT_DOC_FILES[@]}")
  CFG_SKIP_PATHS=""

  # Layer 2: per-machine config
  local machine_config="$HOME/.cache/doc-tools/config.json"
  if [ -f "$machine_config" ]; then
    _merge_config "$machine_config" code_exts doc_files
  fi

  # Layer 1: per-project config (highest priority)
  if [ -n "$project_dir" ] && [ -f "$project_dir/.claude/doc-tools.json" ]; then
    _merge_config "$project_dir/.claude/doc-tools.json" code_exts doc_files
  fi

  # Build regex strings consumers will grep against
  CFG_CODE_EXTENSIONS_REGEX="\\.($(IFS='|'; echo "${code_exts[*]}"))$"
  CFG_DOC_FILES_REGEX="$(_doc_regex "${doc_files[@]}")"
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Merge a JSON config file's values over current variables. Uses jq.
# Args: $1 = json file path; $2 = code_exts array name; $3 = doc_files array name.
_merge_config() {
  local cfg_file="$1"
  local -n _code_exts_ref="$2"
  local -n _doc_files_ref="$3"

  if ! command -v jq &>/dev/null; then
    return 0  # silently skip if jq missing (defaults persist)
  fi

  # enabled (use has() — `// empty` swallows the literal value `false`)
  local v
  v=$(jq -r 'if has("enabled") then .enabled else empty end' "$cfg_file" 2>/dev/null)
  [ -n "$v" ] && CFG_ENABLED="$v"

  # min_changed_files
  v=$(jq -r 'if has("min_changed_files") then .min_changed_files else empty end' "$cfg_file" 2>/dev/null)
  [ -n "$v" ] && CFG_MIN_CHANGED_FILES="$v"

  # code_extensions (replace, not merge — caller intent is full override)
  v=$(jq -r 'if .code_extensions then .code_extensions | join(" ") else empty end' "$cfg_file" 2>/dev/null)
  if [ -n "$v" ]; then
    _code_exts_ref=()
    # shellcheck disable=SC2206
    _code_exts_ref=($v)
  fi

  # doc_files (replace)
  v=$(jq -r 'if .doc_files then .doc_files | join(" ") else empty end' "$cfg_file" 2>/dev/null)
  if [ -n "$v" ]; then
    _doc_files_ref=()
    # shellcheck disable=SC2206
    _doc_files_ref=($v)
  fi

  # skip_paths (newline-delimited; appended across layers)
  v=$(jq -r 'if .skip_paths then .skip_paths[] else empty end' "$cfg_file" 2>/dev/null)
  if [ -n "$v" ]; then
    if [ -z "$CFG_SKIP_PATHS" ]; then
      CFG_SKIP_PATHS="$v"
    else
      CFG_SKIP_PATHS="$CFG_SKIP_PATHS"$'\n'"$v"
    fi
  fi
}

# Build a grep regex that matches any doc file or directory pattern
_doc_regex() {
  local parts=()
  for f in "$@"; do
    # Escape dots; trailing slash → directory match
    local escaped="${f//./\\.}"
    parts+=("$escaped")
  done
  local IFS='|'
  echo "(${parts[*]})"
}

# Check if current path matches any skip_paths glob
is_skipped_path() {
  local pwd_abs="${1:-$PWD}"
  [ -z "$CFG_SKIP_PATHS" ] && return 1

  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    # Expand ~ to $HOME
    pattern="${pattern/#\~/$HOME}"
    # shellcheck disable=SC2053
    if [[ "$pwd_abs" == $pattern ]]; then
      return 0
    fi
  done <<< "$CFG_SKIP_PATHS"
  return 1
}
