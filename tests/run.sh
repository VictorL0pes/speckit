#!/usr/bin/env bash
# speckit's own tests: the hooks, check-artifacts and install.sh.

set -uo pipefail

kit=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass=0 fail=0
ok() { pass=$((pass + 1)); }
ko() { fail=$((fail + 1)); echo "FAIL: $*"; }
check() { local name=$1; shift; if "$@" > /dev/null 2>&1; then ok; else ko "$name"; fi; }
refute() { local name=$1; shift; if "$@" > /dev/null 2>&1; then ko "$name"; else ok; fi; }

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

# --- commit-msg -------------------------------------------------------------

msg() { printf '%b' "$1" > "$tmp/msg"; "$kit/hooks/commit-msg" "$tmp/msg"; }

check "accepts feat:" msg 'feat: add clients\n'
check "accepts a scope" msg 'fix(clients): keep the query string\n'
check "accepts a breaking change" msg 'refactor!: drop the v1 routes\n'
check "accepts a merge" msg "Merge branch 'main' into feat/clients\n"
check "accepts fixup!" msg 'fixup! feat: add clients\n'
check "accepts a human co-author" msg 'feat: x\n\nCo-Authored-By: Ana <ana@example.com>\n'
check "ignores comment lines" msg '# Please enter the commit message\ndocs: explain lanes\n'
check "leaves an empty message to git" msg '\n# only comments\n'
refute "rejects a free-form subject" msg 'update stuff\n'
refute "rejects a missing space" msg 'feat:add clients\n'
refute "rejects an unknown type" msg 'wip: half done\n'
refute "rejects a Claude co-author" msg 'feat: x\n\nCo-Authored-By: Claude Opus <noreply@anthropic.com>\n'
refute "rejects Generated with Claude Code" msg 'feat: x\n\nGenerated with [Claude Code](https://claude.com/claude-code)\n'

# --- pre-commit -------------------------------------------------------------

repo="$tmp/hookrepo"
git init -q "$repo"
staged() {
    git -C "$repo" reset -q > /dev/null 2>&1
    for f in "$@"; do mkdir -p "$repo/$(dirname "$f")"; echo x > "$repo/$f"; git -C "$repo" add -f "$f"; done
    (cd "$repo" && "$kit/hooks/pre-commit")
}
refute "blocks .env" staged .env
refute "blocks a nested .env.local" staged config/.env.local
check "allows .env.example" staged .env.example
check "allows ordinary files" staged src/app.ts README.md

# --- check-artifacts --------------------------------------------------------

card="$tmp/specs/feat-x"
mkdir -p "$card"
head -c 6000 /dev/zero | tr '\0' a > "$card/spec.md"
head -c 5000 /dev/zero | tr '\0' a > "$card/task.md"
check "passes under the caps" "$kit/bin/check-artifacts" "$card"
head -c 6200 /dev/zero | tr '\0' a > "$card/spec.md"
refute "fails over the spec cap" "$kit/bin/check-artifacts" "$card"
check "defaults to every card in specs/" bash -c "cd '$tmp' && ! '$kit/bin/check-artifacts'"
refute "fails on a missing directory" "$kit/bin/check-artifacts" "$tmp/nope"

# --- next -------------------------------------------------------------------

cards="$tmp/cards"
git init -q "$cards"
card() { mkdir -p "$cards/specs/$1"; touch "$cards/specs/$1/task.md"; [ -z "${2:-}" ] || printf '%b' "$2" > "$cards/specs/$1/handoffs.md"; }
next_says() { local out; out=$(cd "$cards" && "$kit/bin/next" "${@:2}") || return 1; grep -qF -- "$1" <<< "$out"; }

card feat-new
card feat-specd '# Hand-offs — specd\n\n- 2026-09-21 specifier: pass\n'
card feat-back '- 2026-09-21 specifier: pass\n- 2026-09-22 hardener: return coder — update skips the tenant check\n'
card feat-done '- 2026-09-21 coder: pass\n- 2026-09-23 qa: pass\n'
card feat-parked '- 2026-09-21 spec-review: stop — the user parked it\n'
card feat-odd '- 2026-09-21 hardener: return nobody — ?\n'
card feat-legacy
touch "$cards/specs/feat-legacy/spec.md"
mkdir -p "$cards/specs/notes"

check "next: a new card goes to the specifier" next_says 'specs/feat-new: run /speckit-specify' specs/feat-new
check "next: a pass goes to the next lane" next_says 'specs/feat-specd: run /speckit-spec-review' specs/feat-specd
check "next: a return goes back to that lane" next_says 'specs/feat-back: run /speckit-implement' specs/feat-back
check "next: a return shows the reason" next_says 'update skips the tenant check' specs/feat-back
check "next: qa pass means merge" next_says 'qa passed. Merge the branch' specs/feat-done
check "next: stop means parked" next_says 'specs/feat-parked: parked' specs/feat-parked
check "next: flags an unknown lane" next_says "unknown lane 'nobody'" specs/feat-odd
check "next: flags a card with no hand-offs past the spec" next_says 'no hand-off recorded' specs/feat-legacy
check "next: lists every card off a card branch" next_says 'specs/feat-done:'
refute "next: skips directories without task.md" next_says 'specs/notes'
git -C "$cards" checkout -q -b feat/back
check "next: on a card branch, shows that card" next_says 'specs/feat-back:'
refute "next: on a card branch, shows only that card" next_says 'specs/feat-new'
refute "next: fails on a missing directory" bash -c "cd '$cards' && '$kit/bin/next' specs/nope"
check "next: says so when there are no cards" bash -c "cd '$tmp' && mkdir -p empty && cd empty && '$kit/bin/next' | grep -q 'No cards'"

# --- install.sh -------------------------------------------------------------

proj="$tmp/myapp"
export FLOE_CONFIG_DIR="$tmp/floe"
git init -q "$proj"
echo "# my rules" > "$proj/CLAUDE.md"

check "installs" "$kit/install.sh" --floe --claude --hooks "$proj"

check "keeps an existing CLAUDE.md" grep -qx '# my rules' "$proj/CLAUDE.md"
check "creates the product spec" test -f "$proj/specs/product.md"
check "installs the card templates" test -f "$proj/.speckit/templates/card/spec.md"
check "installs check-artifacts" test -x "$proj/.speckit/bin/check-artifacts"
check "installs next" test -x "$proj/.speckit/bin/next"

lanes='specify spec-review implement refactor architecture review verify'
for lane in $lanes; do
    f="$proj/.floe/skills/speckit-$lane.md"
    check "floe skill speckit-$lane" test -f "$f"
    check "speckit-$lane starts with frontmatter" test "$(head -n 1 "$f")" = ---
    check "speckit-$lane carries the contract" grep -q '^FRESH SESSION:' "$f"
    check "speckit-$lane carries its body" grep -q '^# Lane:' "$f"
    check "speckit-$lane carries the contract once" test "$(grep -c '^FRESH SESSION:' "$f")" = 1
    check "speckit-$lane records its hand-off" grep -q 'specs/<dir>/handoffs.md' "$f"
    check "speckit-$lane knows about second visits" grep -q '^SECOND VISIT:' "$f"
    check "speckit-$lane talks caveman ultra" grep -q '^VOICE: caveman ultra' "$f"
    check "speckit-$lane keeps the voice before its body" test "$(grep -n '^VOICE:' "$f" | cut -d: -f1)" -lt "$(grep -n '^# Lane:' "$f" | cut -d: -f1)"
    check "claude skill speckit-$lane is manual" grep -q '^disable-model-invocation: true' "$proj/.claude/skills/speckit-$lane/SKILL.md"
done
for skill in constitution add-task; do
    check "floe skill speckit-$skill" test -f "$proj/.floe/skills/speckit-$skill.md"
    refute "speckit-$skill has no lane contract" grep -q '^FRESH SESSION:' "$proj/.floe/skills/speckit-$skill.md"
    check "claude skill speckit-$skill" test -f "$proj/.claude/skills/speckit-$skill/SKILL.md"
    check "speckit-$skill talks caveman ultra" grep -q '^VOICE: caveman ultra' "$proj/.floe/skills/speckit-$skill.md"
done
check "ships the caveman license" grep -q 'Julius Brussee' "$proj/.speckit/licenses/caveman-MIT.txt"

board="$FLOE_CONFIG_DIR/projects/myapp/colony.toml"
check "writes the Floe board" test -f "$board"
check "the board has seven stages" test "$(grep -c '^\[\[stage\]\]' "$board")" = 7
while IFS= read -r skill; do
    check "board skill $skill is installed" test -f "$proj/.floe/skills/$skill.md"
done < <(sed -n 's/^skill *= *"\(.*\)"/\1/p' "$board")

check "installs the hooks" test -x "$proj/.githooks/commit-msg"
check "points core.hooksPath at them" test "$(git -C "$proj" config core.hooksPath)" = .githooks

check "re-runs cleanly" "$kit/install.sh" --floe --claude --hooks "$proj"
refute "no board backup when unchanged" test -e "$board.bak"
echo "cap = 2" > "$board"
check "re-runs over a changed board" "$kit/install.sh" --floe "$proj"
check "backs up a changed board" grep -qx 'cap = 2' "$board.bak"

git -C "$proj" config core.hooksPath .husky
check "installs next to another hook manager" "$kit/install.sh" --hooks "$proj"
check "leaves another hooksPath alone" test "$(git -C "$proj" config core.hooksPath)" = .husky

dflt="$tmp/dflt"
mkdir -p "$dflt"
check "installs with no flags" "$kit/install.sh" "$dflt"
check "defaults to Claude Code" test -f "$dflt/.claude/skills/speckit-specify/SKILL.md"
refute "leaves Floe out by default" test -e "$dflt/.floe"
refute "writes no Floe board by default" test -e "$FLOE_CONFIG_DIR/projects/dflt"

only="$tmp/onlyclaude"
mkdir -p "$only"
check "installs --claude only" "$kit/install.sh" --claude "$only"
refute "--claude skips Floe" test -e "$only/.floe"
check "--claude creates CLAUDE.md from the template" grep -q 'project constitution' "$only/CLAUDE.md"

plain="$tmp/plain"
mkdir -p "$plain"
check "installs --no-caveman" "$kit/install.sh" --no-caveman --floe "$plain"
refute "--no-caveman leaves the voice out of lanes" grep -rq '^VOICE:' "$plain/.floe/skills"
check "--no-caveman still carries the contract" grep -q '^FRESH SESSION:' "$plain/.floe/skills/speckit-verify.md"
check "--no-caveman installs skills as written" cmp -s "$kit/skills/speckit-add-task.md" "$plain/.floe/skills/speckit-add-task.md"
refute "--no-caveman ships no caveman license" test -e "$plain/.speckit/licenses/caveman-MIT.txt"

refute "rejects a missing target" "$kit/install.sh"
refute "rejects an unknown option" "$kit/install.sh" --nope "$only"

# --- lane sizes -------------------------------------------------------------

for lane in $lanes; do
    size=$(wc -c < "$proj/.floe/skills/speckit-$lane.md")
    check "speckit-$lane stays under 11 KB ($size bytes)" test "$size" -le 11264
done

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
