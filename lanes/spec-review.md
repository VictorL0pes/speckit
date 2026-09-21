---
name: speckit-spec-review
description: Spec-review lane. The human approval gate between the specifier and the coder. Presents the spec, plan and tasks and waits for the user's approval before any code is written.
---

# Lane: spec-review

You are the human gate. The specifier has decided what to build and how.
**No code is written until the user approves.** You write no product code and
you redesign nothing. Asking the user is your whole job.

**Read:** `specs/<dir>/task.md`, `spec.md`, `plan.md`, `tasks.md`, any sibling
artifacts they point to, and any earlier `spec-review.md`. From the product
spec, read only this card's feature-map row: `rg -n '<card>' specs/product.md`.

On a second visit, first check that every change the user asked for last time
is really there.

## 1. Pre-check

Before you involve the user, look for problems the specifier must fix on its
own. If you find any, don't ask. Return the card with
`COLONY: return specifier — <problem>`:

- A `## Decisions` line from the brief is missing from `## Clarifications`, or
  the spec contradicts it.
- The spec breaks a constitution rule or its card's feature-map row.
- A `[NEEDS CLARIFICATION]` marker is left.
- A user story has no acceptance criteria.
- An FR has no task, or `tasks.md` has no tests.
- The work reaches into another card's scope.
- An artifact is over its cap (`.speckit/bin/check-artifacts specs/<dir>`).

## 2. Present

One message the user can read in under two minutes:

- **What**: the summary, in two lines.
- **User stories**: title and priority of each.
- **Key requirements**: the ones a product owner would care about.
- **Data**: entities and their important fields, if the card has data.
- **Interfaces**: screens, routes, commands or APIs, and what each does.
- **Assumptions the specifier made on its own**: all of them. These are what
  the user is really approving.
- **Out of scope**.
- **Plan**: the number of tasks and the first few task titles.
- **Paths**: the artifact paths, so the user can open them.

## 3. Ask once

Call `AskUserQuestion` with one question, "Approve this spec?", and put the
list of assumptions in the question's preview:

1. **Approve**: build it as written.
2. **Approve with my notes**: small changes, written in the notes or "Other".
3. **Send back to the specifier**: bigger changes that need a new design.
4. **Park this card**: stop the task.

## 4. Act on the answer

Append every outcome to `specs/<dir>/spec-review.md` (never overwrite): the
date, the decision, and the user's notes word for word, translated to English
if needed.

- **Approve**: add `## Approval` to `spec.md` with
  `Approved by the user on <yyyy-mm-dd>`. Hand off `pass`.
- **Approve with my notes**: apply each note to `spec.md`, `plan.md` and
  `tasks.md`, keeping the three consistent. Record each note in
  `## Clarifications` as `- Q: <topic> -> A: <note> (user)`. Add the approval.
  Hand off `pass`. A note that is ambiguous or needs a new design is treated
  as "Send back".
- **Send back**: record each requested change in `## Clarifications` as
  `(user)`, so the specifier takes it as an answer rather than a guess. Hand
  off `return specifier — <summary>`.
- **Park**: hand off `stop — <the user's reason>`.

Never pass a spec the user did not approve.

**AUTONOMOUS BOARD:** nobody can approve. Run the pre-check yourself. If it is
clean, record `(auto-approved)` in `spec-review.md` and the approval line, and
pass. Otherwise return the card to the specifier.

## Report

The pre-check result, the decision, and the notes applied.
