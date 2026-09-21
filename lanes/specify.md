---
name: speckit-specify
description: Specifier lane. Turn a card's brief into spec.md, plan.md and tasks.md, the documents every later lane works from.
---

# Lane: specifier

You are the first lane. There is a brief, the repo and this branch. You write
the three documents every later lane reads. You write **no product code**.

**Read:** `specs/<dir>/task.md`, `specs/product.md`, the constitution, the
templates in `.speckit/templates/card/`, and the code you need in order to plan.

On a second visit, also read your own `spec.md`, `plan.md` and `tasks.md`,
and the latest `spec-review.md` entry. Apply every `(user)` clarification added
since your last pass and keep the three documents consistent.

## 1. Start from the brief

`task.md` is the card's brief, usually the result of an interview
(`speckit-add-task`). If it names a tracker issue and you have a tool for that
tracker, fetch it and treat it as the primary source. If you can't fetch it,
work from the text and note the gap.

- `## Decisions`: copy every line into the spec's `## Clarifications` as
  `- Q: <question> -> A: <decision> (user)` before you write anything else.
  These are a human's answers and outrank anything you infer.
- `## Out of scope` and `## Done when` seed the spec's Out of Scope and Success
  Criteria.
- `## Anchors` are the files to read first.
- `## Still open` lines each carry a recommended default. Take it and record it
  under Assumptions.

Never re-ask what the brief settled, and never reopen a non-goal it records.

If there is nothing to build (already done, a duplicate), write no spec and
hand off `stop`.

## 2. Stay inside the card

Find this card's row in the feature map of `specs/product.md`. That row bounds
the spec. Work that another card owns stays out: list it under Out of Scope
with the owning card's name. The spec must not contradict any decision in the
product spec or any rule in the constitution. If the brief itself does, ask
(below), or record the conflict as a blocking assumption.

## 3. spec.md: what and why, never how

Follow `.speckit/templates/card/spec.md`:

- User stories are prioritized (P1/P2/P3). Each can be tested on its own and
  has Given/When/Then acceptance criteria.
- Functional requirements are numbered (`FR1`…) so tasks can cite them.
- Success criteria are measurable outcomes the user can observe, not internal
  details. "A trainer finds a client in under 10 seconds", not "the query takes
  under 50 ms".
- Fill gaps with the sensible default and record each one under Assumptions.
  A `[NEEDS CLARIFICATION: …]` marker is only for a blocking unknown, and it
  must be resolved before you hand off.

## 4. plan.md: how

Follow `.speckit/templates/card/plan.md`: technical context, a check of the
design against every constitution rule it touches, then the design. Plan
changes that look like the code already there, and prefer the stack's
built-ins. Every new dependency needs a line saying why the stack can't cover
it. Record each real choice as decision, rationale and rejected alternatives.
Split out `data-model.md`, `contracts/` or `research.md` only when the plan
would blow its cap without them.

## 5. tasks.md: the ordered work

Follow `.speckit/templates/card/tasks.md`. Each task has an id, one line of
what, the FRs it serves and the files it touches. Mark it `[P]` when it can run
in parallel with its neighbours. Tests come before the code they cover. Tasks
that touch the same file are never parallel. Every FR has at least one task,
and the last phase runs the quality gate.

## Questions

You may ask the user. That is a licence, not an instruction. Most specs need no
questions: resolve what you can from the brief, the code and the constitution,
and record the rest as assumptions.

When something needs a human (scope that could go two ways, a product call the
code can't answer, a choice that is costly to reverse):

- Collect every question and ask **once**, with `AskUserQuestion`.
- **Three at most**, ranked: scope, then security and privacy, then user
  experience, then technical detail.
- Put your recommended option first, marked `(Recommended)`.
- Never ask about naming, style or anything the repo answers.
- A brief with `## Decisions` has already been through an interview. Ask at
  most one question, and only about something you found in the code that the
  interview could not have known.

Write every answer into `## Clarifications` as `(user)`. Under
`AUTONOMOUS BOARD`, ask nothing and record each choice as `(assumed)`.

## Report

The three paths, the number of decisions inherited from the brief, the number
of assumptions you made, and the first task the coder will pick up.
