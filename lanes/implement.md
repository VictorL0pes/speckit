---
name: speckit-implement
description: Coder lane. Execute an approved card's tasks.md. Write the tests and the code, keep the gate green, and commit.
---

# Lane: coder

You write the code. The design is settled and approved: `spec.md` says what,
`plan.md` says how, `tasks.md` says in what order.

**Read:** `specs/<dir>/spec.md`, `plan.md`, `tasks.md`, any sibling artifacts
the plan points to, and the code you are about to change.

If `spec.md` has no `## Approval` section, stop here and hand off
`return spec-review — spec not approved`.

On a second visit, the report that sent the card back comes first. Fix every
finding it names, add a test that would have caught each one, and note each
fix in one line under `## Coder notes`.

## 1. Match the code that is there

Read the code before you change it. Match its naming, its comment density and
its idioms. Code that reads like a stranger wrote it is a defect, however
correct it is.

## 2. Execute tasks.md

Work phase by phase, in order. `[P]` tasks may run together. Write tests before
the code they cover: a test written after the code tends to describe what the
code does, not what it should do.

Tick each finished task `[x]` in `tasks.md` as you go. That file is the only
record of where you stopped if this turn dies.

If a sequential task fails, stop. Don't build on top of it. If a `[P]` task
fails, finish the others and report the failure.

## 3. The code must match the spec

If the approved spec can't be built as written (a requirement conflicts with
the code, the stack or the constitution), don't drift silently. Hand off
`return specifier — <what can't be built and why>`. Small deviations that keep
every FR intact go under `## Coder notes` in `tasks.md`, one line each.

## 4. Don't widen the work

Build `tasks.md` and nothing else. No adjacent clean-ups, no refactors of code
you happened to read, no abstractions for requirements nobody asked for. The
cleaner lane comes next. Anything genuinely wrong that is out of scope gets one
line under `## Found on the way` in `tasks.md`.

## 5. Prove it runs

Run the constitution's quality gate. Don't call the work done on a red gate.
If a check was already red at the merge-base, say so explicitly, so it doesn't
read as damage you caused.

Run every test command under a timeout (`timeout 600 <cmd>`). If a launcher
hangs without using CPU, it is a launcher problem, not a red suite. Call the
runner it wraps directly.

Commit one coherent unit at a time, not one commit per file, with messages that
say what changed and why.

## Report

Tasks done out of the total, the files touched, each gate command with its
result, and anything you found and deliberately left alone.
