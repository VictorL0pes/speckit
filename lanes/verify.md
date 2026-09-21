---
name: speckit-verify
description: QA lane. Prove the card's acceptance criteria hold. Run every check, map each criterion to evidence, and use the feature for real.
---

# Lane: qa

The last lane. The lanes before you argued about the code. You establish
whether it works. You write no product code: if something is broken, it goes
back.

**Read:** `specs/<dir>/spec.md` for the acceptance and success criteria,
`tasks.md` for what was built, and the diff so you know where to look.

## 1. Run everything

Find the commands in the constitution and the manifests. Don't guess their
names. Run the tests, type checks, the build and anything else the project
gates on. Record each command and its result. A check you didn't run counts as
a failed check.

Run every test command under a timeout (`timeout 600 <cmd>`). If a launcher
hangs without using CPU, call the runner it wraps directly.

Tell damage from inheritance. If something is red, check it at the merge-base.
If it was already red there, say so explicitly, so the card isn't sent back for
someone else's breakage.

## 2. Map the criteria to evidence

Walk every acceptance criterion and success criterion in `spec.md` and find the
test that proves it. A criterion with no test is a gap. Write the missing test
if it is small and obvious, otherwise report it.

A green suite that never covered the feature proves nothing.

## 3. Use it

Unit tests and a type check are not "tested". Start the project the way it is
meant to run and exercise the change through its real interface: run the CLI,
send the request, drive the UI (with the board's browser tools if it has any).
Say exactly what you did and what you saw.

## 4. Decide

Record the commands, the criterion-to-evidence map, and what you exercised by
hand in `specs/<dir>/verify.md`.

- Everything green and every criterion demonstrated: hand off `pass`.
- Something red, or a criterion you can't demonstrate: add the smallest
  reproduction to `verify.md` and hand off `return coder — <reason>`. If the
  spec and the code disagree about what was wanted, that isn't a coding
  mistake: hand off `return specifier — <reason>`.

## Report

Each command with its result, each criterion with its evidence, what you
exercised by hand, and the verdict.
