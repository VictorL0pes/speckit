#!/usr/bin/env bash
# Installs speckit into a project. Safe to re-run: kit files are refreshed,
# the project's own CLAUDE.md and specs/product.md are never overwritten.

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: install.sh [--floe] [--claude] [--hooks] [--no-caveman] <project-dir>

  --floe     Lane skills into .floe/skills/, and the seven-lane board into
             Floe's config for this project (projects/<dir-name>/colony.toml).
  --claude   Lane skills into .claude/skills/, for running lanes by hand.
  --hooks    Git hooks (conventional commits, no AI attribution, no .env)
             into .githooks/, and core.hooksPath pointed at them.
  --no-caveman
             Leave out the caveman ultra voice. By default every skill talks
             ultra-compressed in chat; what it writes to disk stays plain.

Without --floe or --claude, both are installed.
Always installed: .speckit/ (templates, check-artifacts, VERSION), plus
CLAUDE.md and specs/product.md from the templates when they don't exist yet.

Environment: FLOE_CONFIG_DIR (default ~/.config/floe).
USAGE
    exit "${1:-0}"
}

kit=$(cd "$(dirname "$0")" && pwd)
floe=0 claude=0 hooks=0 caveman=1 target=''

while [ "$#" -gt 0 ]; do
    case "$1" in
        --floe) floe=1 ;;
        --claude) claude=1 ;;
        --hooks) hooks=1 ;;
        --no-caveman) caveman=0 ;;
        -h | --help) usage 0 ;;
        -*) echo "install.sh: unknown option $1" >&2; usage 1 ;;
        *) [ -z "$target" ] || usage 1; target=$1 ;;
    esac
    shift
done

[ -n "$target" ] || usage 1
[ -d "$target" ] || { echo "install.sh: $target is not a directory" >&2; exit 1; }
target=$(cd "$target" && pwd)
[ "$floe" -eq 1 ] || [ "$claude" -eq 1 ] || { floe=1; claude=1; }

say() { printf '  %s\n' "$*"; }

# A skill is its own frontmatter, then the shared parts given (empty ones are
# skipped), then a rule, then its body.
render() {
    local file=$1 part end parts=()
    shift
    for part in "$@"; do [ -n "$part" ] && parts+=("$part"); done
    if [ "${#parts[@]}" -eq 0 ]; then
        cat "$file"
        return
    fi
    end=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$file")
    head -n "$end" "$file"
    for part in "${parts[@]}"; do
        echo
        cat "$part"
    done
    printf '\n---\n'
    tail -n +"$((end + 1))" "$file"
}

# Claude Code runs a lane only when asked, never on its own initiative.
manual_only() {
    awk 'NR > 1 && /^---$/ && !done { print "disable-model-invocation: true"; done = 1 } { print }'
}

# Calls <callback> <name> <lane|skill> once per skill, with the skill on stdin.
each_skill() {
    local callback=$1 file name
    for file in "$kit"/lanes/*.md; do
        [ "$(basename "$file")" = contract.md ] && continue
        name=$(sed -n 's/^name: *//p' "$file" | head -n 1)
        render "$file" "$kit/lanes/contract.md" "$voice" | "$callback" "$name" lane
    done
    for file in "$kit"/skills/*.md; do
        name=$(sed -n 's/^name: *//p' "$file" | head -n 1)
        render "$file" "$voice" | "$callback" "$name" skill
    done
}

voice=''
[ "$caveman" -eq 0 ] || voice="$kit/style/caveman-ultra.md"

echo "speckit $(cat "$kit/VERSION") → $target"

# 1. Kit files: always refreshed.
mkdir -p "$target/.speckit/templates/card" "$target/.speckit/bin"
cp "$kit"/templates/card/*.md "$target/.speckit/templates/card/"
cp "$kit/templates/CLAUDE.md" "$kit/templates/product.md" "$target/.speckit/templates/"
cp "$kit/bin/check-artifacts" "$target/.speckit/bin/check-artifacts"
chmod +x "$target/.speckit/bin/check-artifacts"
cp "$kit/VERSION" "$target/.speckit/VERSION"
say ".speckit/ (templates, bin/check-artifacts)"
if [ -n "$voice" ]; then
    mkdir -p "$target/.speckit/licenses"
    cp "$kit/licenses/caveman-MIT.txt" "$target/.speckit/licenses/"
    say "voice: caveman ultra (in chat only; --no-caveman to leave it out)"
else
    rm -f "$target/.speckit/licenses/caveman-MIT.txt"
    say "voice: plain"
fi

# 2. Project documents: created once, never overwritten.
if [ -e "$target/CLAUDE.md" ]; then
    say "CLAUDE.md exists, left alone (merge .speckit/templates/CLAUDE.md by hand, or run speckit-constitution)"
else
    cp "$kit/templates/CLAUDE.md" "$target/CLAUDE.md"
    say "CLAUDE.md (template: fill it in with speckit-constitution)"
fi
mkdir -p "$target/specs"
if [ -e "$target/specs/product.md" ]; then
    say "specs/product.md exists, left alone"
else
    cp "$kit/templates/product.md" "$target/specs/product.md"
    say "specs/product.md (template: fill it in with speckit-constitution)"
fi

# 3. Skills.
write_floe_skill() { cat > "$target/.floe/skills/$1.md"; }
write_claude_skill() {
    mkdir -p "$target/.claude/skills/$1"
    if [ "$2" = lane ]; then manual_only; else cat; fi > "$target/.claude/skills/$1/SKILL.md"
}

if [ "$floe" -eq 1 ]; then
    mkdir -p "$target/.floe/skills"
    each_skill write_floe_skill
    say ".floe/skills/speckit-*.md"

    board_dir="${FLOE_CONFIG_DIR:-$HOME/.config/floe}/projects/$(basename "$target")"
    board="$board_dir/colony.toml"
    mkdir -p "$board_dir"
    if [ -e "$board" ] && ! cmp -s "$kit/floe/colony.toml" "$board"; then
        cp "$board" "$board.bak"
        say "board: previous $board saved as colony.toml.bak"
    fi
    cp "$kit/floe/colony.toml" "$board"
    say "board: $board"
fi

if [ "$claude" -eq 1 ]; then
    each_skill write_claude_skill
    say ".claude/skills/speckit-*/SKILL.md"
fi

# 4. Git hooks.
if [ "$hooks" -eq 1 ]; then
    mkdir -p "$target/.githooks"
    cp "$kit/hooks/commit-msg" "$kit/hooks/pre-commit" "$target/.githooks/"
    chmod +x "$target/.githooks/commit-msg" "$target/.githooks/pre-commit"
    say ".githooks/ (commit-msg, pre-commit)"
    if git -C "$target" rev-parse --git-dir > /dev/null 2>&1; then
        current=$(git -C "$target" config --get core.hooksPath || true)
        if [ -z "$current" ] || [ "$current" = .githooks ]; then
            git -C "$target" config core.hooksPath .githooks
            say "core.hooksPath = .githooks"
        else
            say "core.hooksPath is already '$current': call .githooks/* from your hook manager"
        fi
    else
        say "not a git repository yet: run 'git config core.hooksPath .githooks' after 'git init'"
    fi
fi

echo "Done. Next: run speckit-constitution in $target, then speckit-add-task for the first card."
