#!/usr/bin/env bash
# Shared helpers for the provider-neutral workspace module.
#
# The module deliberately has no project, provider, network, or task-system
# defaults. A small manifest supplies the project-specific paths.

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
  C_RESET=$'\e[0m'
  C_DIM=$'\e[2m'
  C_BOLD=$'\e[1m'
  C_RED=$'\e[31m'
  C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'
  C_BLUE=$'\e[34m'
else
  C_RESET= C_DIM= C_BOLD= C_RED= C_GREEN= C_YELLOW= C_BLUE=
fi

step() { printf '%s→%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
info() { printf '%s  %s%s\n' "$C_DIM" "$*" "$C_RESET"; }
hdr()  { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }

DRIFT_COUNT=0
drift() { err "$@"; DRIFT_COUNT=$((DRIFT_COUNT + 1)); }

die() {
  err "$*"
  exit 1
}

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s\n' "$value"
}

strip_toml_value() {
  local value
  value="$(trim "$1")"
  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s\n' "$value"
}

load_manifest() {
  MANIFEST_FILE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  [[ -f "$MANIFEST_FILE" ]] || die "manifest not found: $MANIFEST_FILE"
  MANIFEST_DIR="$(cd "$(dirname "$MANIFEST_FILE")" && pwd)"
  export MANIFEST_FILE MANIFEST_DIR
}

# Read one top-level key from the intentionally small manifest format.
# Supported values are quoted strings, booleans, and single-line arrays.
manifest_get() {
  local key="$1"
  awk -v wanted="$key" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      eq = index($0, "=")
      if (eq == 0) next
      k = trim(substr($0, 1, eq - 1))
      if (k != wanted) next
      v = trim(substr($0, eq + 1))
      sub(/[[:space:]]+#.*$/, "", v)
      v = trim(v)
      if (v ~ /^".*"$/) v = substr(v, 2, length(v) - 2)
      print v
      exit
    }
  ' "$MANIFEST_FILE"
}

# Print each element of a single-line array key, one per line.
manifest_array() {
  local key="$1"
  awk -v wanted="$key" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      eq = index($0, "=")
      if (eq == 0) next
      k = trim(substr($0, 1, eq - 1))
      if (k != wanted) next
      v = trim(substr($0, eq + 1))
      sub(/[[:space:]]+#.*$/, "", v)
      v = trim(v)
      if (v !~ /^\[.*\]$/) exit
      v = substr(v, 2, length(v) - 2)
      n = split(v, values, ",")
      for (i = 1; i <= n; i++) {
        item = trim(values[i])
        if (item ~ /^".*"$/) item = substr(item, 2, length(item) - 2)
        if (item != "") print item
      }
      exit
    }
  ' "$MANIFEST_FILE"
}

expand_path() {
  local value="$1"
  value="${value/#\~/$HOME}"
  value="${value//\$HOME/$HOME}"
  # Git Bash accepts drive-qualified paths, but dirname can stop at a
  # non-progressing drive token. Normalise them before path walking.
  if [[ "$value" =~ ^([A-Za-z]):[/\\](.*)$ ]]; then
    local drive="${BASH_REMATCH[1]}" rest="${BASH_REMATCH[2]}"
    if command -v cygpath >/dev/null 2>&1; then
      value="$(cygpath -u "$value")"
    else
      value="/${drive,,}/$rest"
    fi
  fi
  printf '%s\n' "$value"
}

is_absolute_path() {
  local value="$1"
  [[ "$value" == /* || "$value" =~ ^[A-Za-z]:[/\\] ]]
}

# Resolve a path relative to a supplied base directory. Existing parents are
# canonicalised; missing leaves are retained so doctor stays read-only.
resolve_path() {
  local value base expanded
  value="$(expand_path "$1")"
  base="$2"
  if is_absolute_path "$value"; then
    expanded="$value"
  else
    expanded="$base/$value"
  fi

  if [[ -d "$expanded" ]]; then
    (cd "$expanded" && pwd)
    return
  fi

  if [[ -e "$expanded" ]]; then
    local existing_parent existing_name
    existing_parent="$(cd "$(dirname "$expanded")" && pwd)"
    existing_name="$(basename "$expanded")"
    if [[ "$existing_parent" == "/" || "$existing_parent" =~ ^[A-Za-z]:/$ ]]; then
      printf '%s%s\n' "$existing_parent" "${existing_name#/}"
    else
      printf '%s/%s\n' "$existing_parent" "$existing_name"
    fi
    return
  fi

  # Normalise paths whose leaf (or several parent directories) do not exist
  # yet. This keeps doctor read-only while still allowing bootstrap to create
  # an external workspace on the first run.
  local unresolved="$expanded" suffix="" name
  while [[ ! -e "$unresolved" && "$unresolved" != "/" && "$unresolved" != "" ]]; do
    name="$(basename "$unresolved")"
    suffix="/$name$suffix"
    unresolved="$(dirname "$unresolved")"
  done
  [[ -d "$unresolved" ]] || die "cannot resolve path; no existing parent for: $expanded"
  local resolved_base
  resolved_base="$(cd "$unresolved" && pwd)"
  if [[ "$resolved_base" == "/" || "$resolved_base" =~ ^[A-Za-z]:/$ ]]; then
    printf '%s%s\n' "$resolved_base" "${suffix#/}"
  else
    printf '%s%s\n' "$resolved_base" "$suffix"
  fi
}

path_is_within() {
  local child parent
  child="$(resolve_path "$1" "/")"
  parent="$(resolve_path "$2" "/")"
  [[ "$child" == "$parent" || "$child" == "$parent/"* ]]
}

assert_outside_project() {
  local path="$1" project="$2" label="$3"
  if path_is_within "$path" "$project"; then
    die "$label resolves inside the target repository: $path"
  fi
}

copy_file() {
  local source="$1" destination="$2" dry_run="${3:-0}"
  [[ -f "$source" ]] || die "source file not found: $source"
  [[ ! -L "$destination" ]] || die "refusing to overwrite symlink destination: $destination"
  if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
    ok "$(basename "$destination") already synced"
    return
  fi
  if [[ "$dry_run" == "1" ]]; then
    step "would copy $source → $destination"
    return
  fi
  mkdir -p "$(dirname "$destination")"
  cp -- "$source" "$destination"
  ok "synced $destination"
}
