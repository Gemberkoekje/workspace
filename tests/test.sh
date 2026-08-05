#!/usr/bin/env bash
# End-to-end fixture test for the actual module scripts.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/workspace-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_same() {
  cmp -s "$1" "$2" || fail "files differ: $1 and $2"
}

bash -n "$REPO_DIR/module/common.sh"
bash -n "$REPO_DIR/module/init.sh"
bash -n "$REPO_DIR/module/bootstrap.sh"
bash -n "$REPO_DIR/module/doctor.sh"

PROFILE="$TMP_ROOT/profile"
TARGET="$TMP_ROOT/project"
EXTERNAL="$TMP_ROOT/external"
mkdir -p "$PROFILE/skills/demo" "$TARGET"
printf '%s\n' '# Fixture instructions' > "$PROFILE/AGENT.md"
printf '%s\n' '---' 'name: demo' 'description: Fixture skill.' '---' '# Demo' > "$PROFILE/skills/demo/SKILL.md"
printf '%s\n' 'keep this target file' > "$TARGET/keep.txt"

MANIFEST="$PROFILE/workspace.toml"
printf '%s\n' \
  'project_name = "Fixture"' \
  "workspace_root = \"$EXTERNAL\"" \
  "target_path = \"$TARGET\"" \
  'instruction_source = "AGENT.md"' \
  'instruction_destinations = ["AGENT.md", "AGENTS.md", "CLAUDE.md"]' \
  'skills_source = "skills"' \
  'skill_destinations = [".agents/skills", ".claude/skills"]' \
  > "$MANIFEST"

bash "$REPO_DIR/module/bootstrap.sh" --config "$MANIFEST"

[[ "$(<"$TARGET/keep.txt")" == "keep this target file" ]] || fail "target file changed"

for file in AGENT.md AGENTS.md CLAUDE.md; do
  assert_file "$EXTERNAL/$file"
  assert_same "$PROFILE/AGENT.md" "$EXTERNAL/$file"
done
for provider in .agents/skills .claude/skills; do
  assert_same "$PROFILE/skills/demo/SKILL.md" "$EXTERNAL/$provider/demo/SKILL.md"
done

# Existing provider content is preserved by the merge-based sync.
mkdir -p "$EXTERNAL/.agents/skills/unrelated"
printf '%s\n' 'unrelated provider skill' > "$EXTERNAL/.agents/skills/unrelated/SKILL.md"
bash "$REPO_DIR/module/bootstrap.sh" --config "$MANIFEST" >/dev/null
assert_file "$EXTERNAL/.agents/skills/unrelated/SKILL.md"

bash "$REPO_DIR/module/doctor.sh" --config "$MANIFEST" >/dev/null

# Doctor detects drift and bootstrap repairs it.
printf '%s\n' 'changed by fixture' > "$EXTERNAL/AGENTS.md"
if bash "$REPO_DIR/module/doctor.sh" --config "$MANIFEST" >/dev/null 2>&1; then
  fail "doctor accepted a changed projection"
fi
bash "$REPO_DIR/module/bootstrap.sh" --config "$MANIFEST" >/dev/null
assert_same "$PROFILE/AGENT.md" "$EXTERNAL/AGENTS.md"

# A destination inside the target is rejected before any target write.
BAD_MANIFEST="$PROFILE/bad.toml"
printf '%s\n' \
  'project_name = "Fixture"' \
  "workspace_root = \"$EXTERNAL\"" \
  "target_path = \"$TARGET\"" \
  'instruction_source = "AGENT.md"' \
  "instruction_destinations = [\"$TARGET/blocked.md\"]" \
  'skills_source = "skills"' \
  'skill_destinations = [".agents/skills"]' \
  > "$BAD_MANIFEST"
if bash "$REPO_DIR/module/bootstrap.sh" --config "$BAD_MANIFEST" >/dev/null 2>&1; then
  fail "bootstrap allowed a destination inside the target"
fi
[[ ! -e "$TARGET/blocked.md" ]] || fail "target was modified by rejected bootstrap"

# Init scaffolds a new external workspace without touching its target.
INIT_TARGET="$TMP_ROOT/init-project"
INIT_WORKSPACE="$TMP_ROOT/init-workspace"
mkdir -p "$INIT_TARGET"
printf '%s\n' 'keep this init target file' > "$INIT_TARGET/keep.txt"
bash "$REPO_DIR/module/init.sh" \
  --output "$INIT_WORKSPACE" \
  --project-name "Init Fixture" \
  --target "../init-project"
assert_file "$INIT_WORKSPACE/AGENT.md"
assert_file "$INIT_WORKSPACE/workspace.toml"
assert_file "$INIT_WORKSPACE/skills/workspace-usage/SKILL.md"
grep -F 'target_path = "../init-project"' "$INIT_WORKSPACE/workspace.toml" >/dev/null
grep -F 'Conventional Commits' "$INIT_WORKSPACE/AGENT.md" >/dev/null
bash "$REPO_DIR/module/bootstrap.sh" --config "$INIT_WORKSPACE/workspace.toml" >/dev/null
bash "$REPO_DIR/module/doctor.sh" --config "$INIT_WORKSPACE/workspace.toml" >/dev/null
[[ "$(<"$INIT_TARGET/keep.txt")" == "keep this init target file" ]] || fail "init modified target"

printf 'PASS: external bootstrap/doctor fixture\n'
