# speckit

Spec-driven development for AI coding agents. Work goes onto a board as
**cards**. Each card passes through seven lanes, and each lane runs as a fresh
agent session with one job:

```
specifier → spec-review → coder → cleaner → architect → hardener → qa
   spec      the user      code    simpler    fits the    adversarial  proves the
   plan      approves              structure  system,     review with  acceptance
   tasks     (the gate)                       gates green a 2nd model  criteria
```

**No product code is written before the user has approved the card's spec.**
The specifier writes it, the spec-review lane shows it to you, and the coder
only starts after your approval.

speckit packages the workflow built for TrainDesk on the Floe colony board so
any project can use it. It runs
on a Floe board, where the lanes move cards on their own, or by hand in Claude
Code, where you invoke the next lane yourself.

## What's in the box

| Path                             | What it is                                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------------------- |
| `lanes/contract.md`              | The rules every lane shares: fresh session, context budget, questions, hand-off             |
| `lanes/*.md`                     | The seven lanes. The installer puts the contract into each one                              |
| `skills/speckit-constitution.md` | Project kickoff: interviews you, writes `CLAUDE.md` and `specs/product.md`                  |
| `skills/speckit-add-task.md`     | Interviews you about one card and writes its brief (`task.md`)                              |
| `templates/`                     | Constitution, product spec and card artifact templates                                      |
| `floe/colony.toml`               | The seven-lane board for Floe, with a model per lane                                        |
| `bin/check-artifacts`            | Fails when a card artifact is over its size cap                                             |
| `hooks/`                         | `commit-msg` (conventional commits, no AI attribution) and `pre-commit` (never commit .env) |
| `install.sh`                     | Installs all of the above into a project                                                    |

## Install

```sh
git clone https://github.com/VictorL0pes/speckit ~/projects/speckit
~/projects/speckit/install.sh --hooks ~/projects/myapp
```

| Flag       | Installs                                                                                                                               |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `--floe`   | Skills into `.floe/skills/`, and the board into `~/.config/floe/projects/<dir-name>/colony.toml` (a different board is kept as `.bak`) |
| `--claude` | Skills into `.claude/skills/<name>/SKILL.md`. The lanes are marked manual-only, so Claude never starts one on its own                  |
| `--hooks`  | `.githooks/` and `core.hooksPath` (left alone if another hook manager owns it)                                                         |

Without `--floe` or `--claude` you get both. Every install also adds
`.speckit/` (templates, `check-artifacts`, `VERSION`) and creates `CLAUDE.md`
and `specs/product.md` from the templates if they don't exist yet. The
installer never overwrites those two files. Re-run it to update a project to a
newer kit. Commit what it installed in the project.

## Workflow

1. **Kickoff: `speckit-constitution`.** It interviews you and writes the
   constitution (`CLAUDE.md`: stack, commands, the one quality gate, hard
   rules) and the product spec (`specs/product.md`: product decisions and the
   **feature map**, which lists every card in dependency order).
2. **A card: `speckit-add-task`.** It interviews you in rounds until every
   decision is settled, then writes the brief: Request, Decisions, Scope, Out of
   scope, Done when, Anchors. On Floe it creates the card. By hand it creates
   the `<kind>/<name>` branch. Cards only start once the cards they wait for
   have merged.
3. **The lanes.** On Floe the board runs them. By hand, run each skill on the
   card's branch, in a fresh session, in this order:

   | Lane        | Skill                  | Reads                         | Writes                                  |
   | ----------- | ---------------------- | ----------------------------- | --------------------------------------- |
   | specifier   | `speckit-specify`      | `task.md`, `specs/product.md` | `spec.md`, `plan.md`, `tasks.md`        |
   | spec-review | `speckit-spec-review`  | `task.md`, spec, plan, tasks  | `spec-review.md`, the approval          |
   | coder       | `speckit-implement`    | spec, plan, tasks             | code, tests, ticks in `tasks.md`        |
   | cleaner     | `speckit-refactor`     | tasks, the diff               | small refactor commits, `refactor.md`   |
   | architect   | `speckit-architecture` | spec, the diff                | `architecture.md`, mechanical fixes     |
   | hardener    | `speckit-review`       | spec, the diff                | `review.md`, small fixes                |
   | qa          | `speckit-verify`       | spec, tasks, the diff         | `verify.md`, missing tests              |

   Every lane ends with one line: `COLONY: pass`,
   `COLONY: return <lane> — <why>` or `COLONY: stop — <why>`. On Floe that line
   moves the card. By hand, it tells you what to run next.

4. **Merge** once qa passes.

A card's documents live in `specs/<branch-with-dashes>/`, so `feat/clients`
becomes `specs/feat-clients/`.

## The rules the lanes carry

- **The spec is a contract.** The code must match the approved spec. If it
  can't, the card goes back to the specifier. A spec stays inside its card's
  feature-map row.
- **Only two lanes talk to you.** The specifier may ask up to three questions,
  batched, each with a recommendation. The spec-review lane asks one question:
  "Approve this spec?". Every other lane decides and records the assumption, or
  returns the card to the lane that owns the decision.
- **Context budget.** Each lane reads only its own inputs (the table above) plus
  the diff, never dumps whole files, and never reads lockfiles or binaries.
  Artifacts have caps: `spec.md` 6 KB, `plan.md` 8 KB, `tasks.md` 4 KB, each
  lane report 4 KB. `check-artifacts` enforces them. A kilobyte in an artifact
  is read by every lane after it.
- **A second opinion.** The hardener must get a review from a different model
  (Codex by default) and record where it overruled it.
- **Evidence over green.** qa maps each acceptance criterion to a test and uses
  the feature for real. A green suite that never covered the feature proves
  nothing.
- **English in the repo.** Artifacts, code and commits are in English. What
  users see follows the constitution.
- **`AUTONOMOUS BOARD`.** A card created with that flag runs with nobody
  answering: every lane takes the recommended option and records it as
  `(assumed)`, and spec-review auto-approves a spec that passes its pre-check.

## Customizing

- **Lanes:** edit `lanes/*.md` or `lanes/contract.md`, then re-run
  `install.sh` in each project.
- **Models per lane:** edit `floe/colony.toml`.
- **Commit types:** edit `types` in `hooks/commit-msg`, and keep it in step with
  the constitution's Git section.
- **Extra blocked paths:** set `blocked_paths` in `hooks/pre-commit` (e.g.
  `'^storage/'`).
- **Caps:** edit `cap_for` in `bin/check-artifacts` and the numbers in
  `lanes/contract.md`.

## Development

```sh
tests/run.sh
```

It tests the hooks, `check-artifacts` and `install.sh` (into temporary
repositories) and keeps each installed lane under 10 KB. CI also runs
ShellCheck.

## Credits

- The lane structure and the `COLONY:` hand-off follow the built-in colony
  skills of Floe.
- The spec → plan → tasks split, `[NEEDS CLARIFICATION]` and the constitution
  come from GitHub's [Spec Kit](https://github.com/github/spec-kit).
- The interview rounds are adapted from Matt Pocock's
  [`grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md)
  skill.
