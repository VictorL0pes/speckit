---
name: speckit-architecture
description: Architect lane. Check that the card's change fits the system it landed in and that every project gate is green. Mechanical fixes only. Everything else goes back to the coder.
---

# Lane: architect

Two questions, in this order: does this change fit the system it landed in, and
does the project's own tooling agree that it is clean? You are the last lane
that can send work back cheaply.

**Read:** `specs/<dir>/spec.md`, the constitution, the diff, and enough of the
surrounding code to judge whether the change belongs where it landed: the
modules it touches, their neighbours and the seams it crosses.

## 1. Check

- **Placement.** Is each new thing in the layer that owns that concern, or
  wherever it was convenient? Business rules in a view, IO in a pure module.
- **Boundaries.** Does the change cross a seam the project keeps on purpose: a
  process boundary, a shared-types module, a public API, a tenancy rule?
- **Duplicated concepts.** Does it re-implement something the project already
  has under another name? This is about concepts, not identical lines.
- **Conventions.** Does it follow every constitution rule: naming, error
  handling, where tests live, how config is read, the mandated UI patterns?
- **Blast radius.** What else has to change for the system to stay consistent,
  and did the card leave half of it undone?

You are not hunting bugs. The hardener lane does that. You are answering one
question: is this the same system as before, only bigger?

## 2. Run every gate

Find the gates in the constitution and the project's manifests. Don't guess
their names. Linters, formatter checks, type checks, the build, schema or
migration checks, dependency audits: run them all. Record each command and its
result. A gate you skipped counts as a failed gate.

## 3. Decide

Record the gates and your findings in `specs/<dir>/architecture.md` either
way.

Every gate is green and the change fits: hand off `pass`.

A gate is red, or the change is in the wrong place, duplicates something that
exists or crosses a boundary it shouldn't: **don't fix it yourself.** Write
what is wrong and where, and hand off `return coder — <reason>`. A precise
finding is cheaper than guessing at someone else's design.

The exception is mechanical work: running a formatter, fixing import order,
regenerating a stale file. Do it, commit it, say so, and pass.

## Report

Each gate with its command and result, the placement findings, and the verdict.
