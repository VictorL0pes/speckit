---
name: speckit-refactor
description: Cleaner lane. Look for accidental complexity in the card's diff that a better data structure or module boundary would remove. Fix it if small, otherwise recommend.
---

# Lane: cleaner

The code works. Your question is whether it carries accidental complexity that
a better data structure or organizing model would remove. Be skeptical of
abstraction: boring code that is clear, local and unlikely to grow is usually
the right answer.

**Read:** `specs/<dir>/tasks.md` and the diff. **Scope the review to the files
in the diff.** Complexity that predates this card is not yours.

## 1. Look for these shapes

- A state machine instead of scattered booleans, phases or lifecycle checks.
- A typed object instead of loose parameters, or instead of a shape assumed in
  six places.
- A map, registry, lookup table or discriminated union instead of branching
  spread across files.
- A reducer or command/event model instead of ad hoc mutation.
- A small module that gathers repeated behaviour, ownership or invariants.
- A queue, cache, index or normalized collection where the access pattern asks
  for one.

An abstraction that adds indirection without removing branches, duplicated
rules, invalid states or lifecycle risk is a loss. That is this lane's most
common failure.

## 2. Judge it

1. What complexity actually appeared: repeated conditionals, mirrored state,
   unclear ownership, invalid intermediate states, fragile ordering,
   duplicated transformations.
2. Whether a data structure would encode the domain more directly.
3. The smallest cleanup that improves it without changing behaviour.
4. The risk: files touched, behaviour affected, test impact, and whether it
   should simply wait.

## 3. Act, or don't

A clear, low-risk cleanup inside the card's scope: make it, run the quality
gate, and commit it separately (`refactor(<card>): …`) so the diff stays
readable.

Anything larger, speculative, or that would drag the card sideways: don't
build it. Write the proposed shape, what it would remove and why it is worth
doing later.

Either way, record the verdict in `specs/<dir>/refactor.md`: what you did,
what you recommend, and what you looked at and left alone.

Never leave the gate red. A refactor that changes behaviour is a bug. If a test
has to change, you did something other than a refactor.

## Report

The verdict (`implement`, `recommend` or `skip`), the structure or `none`, what
complexity it removes, and the gate commands you ran with their results.
