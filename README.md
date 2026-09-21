# speckit

Spec-driven development for [Claude Code](https://claude.com/claude-code).

You describe a change. A chain of focused agent sessions turns it into a spec,
gets **your approval**, builds it, simplifies it, checks it against the rest of
the system, reviews it with a second model, and proves it works. Every step
leaves its reasoning on disk, so nothing depends on one long conversation.

```
 you ─► brief ─► specifier ─► spec-review ─► coder ─► cleaner ─► architect ─► hardener ─► qa ─► merge
                  spec          you approve    code     simpler     fits the     adversarial   proves the
                  plan          (the gate)     tests    structure   system,      review with   acceptance
                  tasks                                             gates green  a 2nd model   criteria
```

## Why

Coding agents fail in predictable ways, and each lane exists to stop one of them:

- **They build before anyone agreed on what.** No product code is written until
  you have approved the spec. After that, the spec is a contract: if the code
  can't meet it, the card goes back to the specifier instead of drifting.
- **They grade their own homework.** Each lane is a fresh session that didn't
  write what it is judging, and the hardener must get a second opinion from a
  different model.
- **They drown in context.** Each lane reads only its own inputs plus the diff,
  and every document has a size cap. A kilobyte in a spec is read by every lane
  after it.
- **"Tests pass" is not "it works".** qa maps each acceptance criterion to the
  test that proves it, then runs the feature for real.
- **They wander out of scope.** Every card maps to one row of the product's
  feature map, and work that belongs to another card stays out.

## Quick start

Requirements: Claude Code, `git` and `bash`. `rg` (ripgrep) is recommended. The
[Codex CLI](https://github.com/openai/codex) gives the hardener its second
opinion.

```sh
git clone https://github.com/VictorL0pes/speckit ~/speckit
~/speckit/install.sh --hooks ~/projects/myapp
cd ~/projects/myapp && claude
```

**1. Set up the project, once.** Run `/speckit-constitution`. It reads the repo,
interviews you, and writes two documents:

- `CLAUDE.md`, the **constitution**: stack, commands, the one quality-gate
  command, and the hard rules every lane obeys.
- `specs/product.md`, the **product spec**: what the product is, who uses it,
  the product decisions, and the **feature map**, which lists every card in
  dependency order.

**2. Add a card.** Run `/speckit-add-task`. It interviews you in rounds until
every decision is settled. Then it creates the branch `<kind>/<name>` (for
example `feat/clients`) and writes the card's brief to
`specs/feat-clients/task.md`.

**3. Run the lanes.** On the card's branch, run each lane in a **fresh session**
(`/clear`, or a new `claude`):

```
/speckit-specify
/speckit-spec-review      ← asks you to approve the spec
/speckit-implement
/speckit-refactor
/speckit-architecture
/speckit-review
/speckit-verify
```

**4. Ask what's next.** Each lane records its verdict, so you never have to
remember where a card stands:

```console
$ .speckit/bin/next
specs/feat-clients: run /speckit-implement (coder) in a fresh session
  last: 2026-09-22 hardener: return coder — anamnesis update skips the tenant check
```

**5. Merge** when `next` says qa passed.

## The lanes

| Lane        | Command                 | Reads                         | Writes                                |
| ----------- | ----------------------- | ----------------------------- | ------------------------------------- |
| specifier   | `/speckit-specify`      | `task.md`, `specs/product.md` | `spec.md`, `plan.md`, `tasks.md`      |
| spec-review | `/speckit-spec-review`  | `task.md`, spec, plan, tasks  | `spec-review.md`, the approval        |
| coder       | `/speckit-implement`    | spec, plan, tasks             | tests and code, ticks in `tasks.md`   |
| cleaner     | `/speckit-refactor`     | tasks, the diff               | small refactor commits, `refactor.md` |
| architect   | `/speckit-architecture` | spec, the diff                | `architecture.md`, mechanical fixes   |
| hardener    | `/speckit-review`       | spec, the diff                | `review.md`, small fixes              |
| qa          | `/speckit-verify`       | spec, tasks, the diff         | `verify.md`, missing tests            |

Every lane also reads the constitution, the code it needs, and `handoffs.md`.

- **specifier** writes what and why (`spec.md`: user stories with
  Given/When/Then, numbered requirements, measurable success criteria), how
  (`plan.md`: design checked against the constitution, every new dependency
  justified), and in what order (`tasks.md`: tests before the code they cover).
  It may ask you up to three questions, each with a recommended answer.
- **spec-review** checks the spec against the brief and the constitution first,
  and sends it back without bothering you if something is missing. Otherwise it
  shows you a two-minute summary, including every assumption the specifier made
  on its own, and asks one question: approve, approve with notes, send back, or
  park.
- **coder** builds `tasks.md` in order, ticks each task, and keeps the quality
  gate green. It refuses to start on a spec you haven't approved.
- **cleaner** looks for accidental complexity in the diff that a better data
  structure would remove. It makes small refactors and only recommends larger
  ones.
- **architect** checks that the change sits in the right layer, respects the
  project's boundaries and conventions, and passes every gate. It fixes
  formatting-type problems itself and sends everything else back to the coder.
- **hardener** reviews like a senior engineer (correctness, failure modes,
  security, data leaks between accounts), argues with a second model, fixes
  what is small, and sends back what needs a design decision.
- **qa** runs everything, maps each acceptance criterion to its evidence, uses
  the feature for real, and passes the card or sends it back.

## Hand-offs and second visits

Every lane ends with a verdict, both as the last line of its message and as a
line appended to the card's `specs/<dir>/handoffs.md`:

```
- 2026-09-21 specifier: pass
- 2026-09-21 spec-review: pass
- 2026-09-22 hardener: return coder — anamnesis update skips the tenant check
```

- `pass`: run the next lane.
- `return <lane> — <reason>`: run that lane again. It opens `handoffs.md`, sees
  the card came back, reads the report of the lane that sent it (here
  `review.md`), and fixes that first instead of starting over. The coder also
  adds a test that would have caught each finding.
- `stop — <reason>`: the card is parked.

`.speckit/bin/next` reads the last line and tells you which command to run. On a
card's branch it shows that card. Anywhere else it lists every card.

## A card's files

Everything about a card lives in `specs/<branch-with-dashes>/` and is committed
with the code:

| File              | Written by  | Cap  |
| ----------------- | ----------- | ---- |
| `task.md`         | add-task    |      |
| `spec.md`         | specifier   | 6 KB |
| `plan.md`         | specifier   | 8 KB |
| `tasks.md`        | specifier   | 4 KB |
| `spec-review.md`  | spec-review |      |
| `refactor.md`     | cleaner     | 4 KB |
| `architecture.md` | architect   | 4 KB |
| `review.md`       | hardener    | 4 KB |
| `verify.md`       | qa          | 4 KB |
| `handoffs.md`     | every lane  |      |

`.speckit/bin/check-artifacts` fails when a file is over its cap. Lanes run it
before they hand off, and when they're over, they cut prose, never decisions.

## Prompt lines

Add these to a lane's prompt when you need them:

- `Base: <branch>`: the card merges into `<branch>` instead of the default
  branch. Diffs are taken against it.
- `AUTONOMOUS BOARD`: nobody will answer questions. Lanes take the recommended
  option and record it as `(assumed)`, and spec-review approves a spec that
  passes its own checks.

## Voice: caveman ultra

Every skill talks in the `ultra` level of
[caveman](https://github.com/JuliusBrussee/caveman): no articles, filler,
hedging or narration around tool calls, and each fact stated once. That covers
every chat message and the report at the end of each turn, so each lane spends
fewer output tokens.

Only the talk is compressed. Everything written to disk (the card's files, code,
comments, commits) stays plain English prose, because later lanes and you read
it. Code, paths, commands, numbers and error strings are never altered. Lanes
speak plainly for security warnings, irreversible actions and ordered steps, and
whenever you ask them to clarify.

The voice is a block of about 1.4 KB, not the full caveman skill. Install with
`--no-caveman` to leave it out.

## Install options

```sh
install.sh [--hooks] [--no-caveman] <project-dir>
```

Every install adds:

- `.claude/skills/speckit-*/SKILL.md`: the nine skills. The seven lanes are
  manual-only, so Claude never starts one on its own.
- `.speckit/`: the templates, `bin/next`, `bin/check-artifacts` and `VERSION`.
- `CLAUDE.md` and `specs/product.md` from the templates, **only if they don't
  exist yet**. The installer never overwrites them.

Flags:

- `--hooks`: installs `.githooks/commit-msg` (conventional commits, no AI
  attribution lines) and `.githooks/pre-commit` (never commit `.env` files),
  and points `core.hooksPath` at them unless another hook manager already owns
  it.
- `--no-caveman`: plain voice instead of caveman ultra.

Commit what the installer added. To update a project to a newer speckit, pull
this repo and run `install.sh` again: kit files are refreshed, your documents
are left alone.

## Tips

- **One fresh session per lane.** Running every lane in one conversation defeats
  the point: reviewers remember writing the code, and every lane pays for all
  the reading done before it.
- **Several cards at once:** give each card its own worktree
  (`git worktree add ../myapp-clients feat/clients`) and its own session.
- **Respect the feature map.** `speckit-add-task` won't start a card until the
  cards it waits for have merged.
- **The approval is yours.** Read the assumptions spec-review lists. They are
  what you are really approving.

## Customizing

| To change                   | Edit                                                                       |
| --------------------------- | -------------------------------------------------------------------------- |
| What a lane does            | `lanes/<lane>.md`, then re-run `install.sh`                                |
| Rules every lane shares     | `lanes/contract.md`                                                        |
| The voice                   | `style/caveman-ultra.md`                                                   |
| Document structure          | `templates/`                                                               |
| Size caps                   | `cap_for` in `bin/check-artifacts`, and the numbers in `lanes/contract.md` |
| Commit types                | `types` in `hooks/commit-msg`, in step with the constitution's Git section |
| Extra paths never committed | `blocked_paths` in `hooks/pre-commit` (e.g. `'^storage/'`)                 |

## Development

```sh
tests/run.sh
```

The tests cover the hooks, `check-artifacts`, `next` and `install.sh` (against
temporary repositories), and keep each installed lane under 11 KB. CI also runs
ShellCheck.

## Credits

- The spec → plan → tasks split, `[NEEDS CLARIFICATION]` and the constitution
  come from GitHub's [Spec Kit](https://github.com/github/spec-kit).
- The caveman ultra voice is adapted from Julius Brussee's
  [caveman](https://github.com/JuliusBrussee/caveman) skill (MIT, see
  `licenses/caveman-MIT.txt`).
- The interview rounds are adapted from Matt Pocock's
  [`grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md)
  skill.
