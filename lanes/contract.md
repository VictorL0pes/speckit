FRESH SESSION: you start with no memory of the lanes before you. What they
decided is on disk: the card's artifacts, the code, and the branch history.
Read it there. Never ask anyone to repeat it.

BRANCH: this card owns its branch (and, on a board, its worktree). Both already
exist. Never create or switch branches.

BASE: the prompt's `Base:` line names the branch this card merges into. Without
one, it is the repository's default branch. "The diff" always means
`git diff $(git merge-base <base> HEAD)` plus anything uncommitted.

ARTIFACTS: the card's documents live in `specs/<dir>/`, where `<dir>` is the
branch name with every `/` replaced by `-` (`feat/clients` becomes
`specs/feat-clients/`). The templates are in `.speckit/templates/`.

CONSTITUTION: `CLAUDE.md` (or `AGENTS.md`) holds the project's hard rules and
its commands, including the quality gate. It outranks your own preferences.
`specs/product.md` is the product spec. Its decisions and feature map are the
specifier's to read. Later lanes work from the card's own `spec.md`.

CONTEXT BUDGET: every lane pays again for everything it reads, on this turn and
every turn after it.
- Read only the artifacts your lane lists, plus the diff. If something you
  need isn't there, return the card to the lane that owns it rather than
  reading another lane's inputs.
- Never dump files wholesale. Use `rg -n <pattern>`, `sed -n '<a>,<b>p'` or
  `head`. Read a file end to end only when you are about to edit it.
- Never read lockfiles, images, binaries or session transcripts. Keep
  dependency and build directories (`vendor/`, `node_modules/`, `dist/`,
  `build/`, `storage/`) out of every search.
- Batch independent commands into one message.
- On a green gate the tail of the output is enough. On a red one, read the
  failure in full.
- Artifact caps: `spec.md` 6 KB, `plan.md` 8 KB, `tasks.md` 4 KB, and 4 KB
  for each lane report (`refactor.md`, `architecture.md`, `review.md`,
  `verify.md`). Run `.speckit/bin/check-artifacts specs/<dir>` before you hand
  off. Over a cap, cut prose, never decisions: don't restate the brief, the
  constitution or the diff.

QUESTIONS: only the specifier and spec-review lanes talk to the user. Every
other lane decides an open point itself and records the assumption in its
artifact, or returns the card to the lane that owns the decision. Never end a
turn with a question, in a tool call or in prose: it parks the card and holds
the lane.

AUTONOMOUS BOARD: if the prompt carries that line, nobody will answer, so no
lane asks. Take the recommended option (the brief's `## Decisions` and
`## Still open` first) and record it as `(assumed)`.

LANGUAGE: everything written to the repo is in English: artifacts, code,
comments, commit messages. Translate whatever language the brief or the user
used. Text the product's users see follows the constitution.

STYLE: terse and concrete. Exact paths, commands and tables. No filler.

COMMITS: follow the constitution's commit rules and commit your own work. On a
board, the board commits `specs/<dir>/` after your turn. Run by hand, commit it
yourself as `docs(<card>): <lane> artifacts`.

HAND-OFF: end your last message with exactly one of these lines, alone:

    COLONY: pass
    COLONY: return <lane> — <one line: what is wrong>
    COLONY: stop — <one line: why this card should not continue>

On a Floe colony board this line moves the card. Run by hand, it tells the
human which skill runs next:

| Lane        | Skill                  | Writes                           |
| ----------- | ---------------------- | -------------------------------- |
| specifier   | `speckit-specify`      | `spec.md`, `plan.md`, `tasks.md` |
| spec-review | `speckit-spec-review`  | `spec-review.md`, approval       |
| coder       | `speckit-implement`    | code, ticks in `tasks.md`        |
| cleaner     | `speckit-refactor`     | `refactor.md`                    |
| architect   | `speckit-architecture` | `architecture.md`                |
| hardener    | `speckit-review`       | `review.md`                      |
| qa          | `speckit-verify`       | `verify.md`                      |
