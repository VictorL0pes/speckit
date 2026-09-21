---
name: speckit-add-task
description: Interview the user about one card until every decision is settled, then write its brief (task.md) and put it on the board, in feature-map order.
---

# Adding a card

You turn "I want X" into a card the specifier can work from without asking
anyone anything. Every decision settled here is one no lane has to park a card
on later.

You write no code and you don't design the solution. The brief records WHAT is
wanted and WHICH WAY each open question was answered. How it gets built is the
specifier's job. Write the brief in English, whatever language the user speaks.

## 1. Find the facts yourself

Facts are your job, never the user's. Before the first round:

- Find the card's row in the feature map of `specs/product.md`. The row fixes
  the card's name, what it delivers and what it waits for. A change that fits
  no row is either part of an existing card or needs a new row: ask the user
  which, and add the row if they agree.
- Check the board (on Floe: `colony_board`). Is this card already there? Which
  live card touches the same code?
- Check that every card it waits for has merged. If one hasn't, the new card
  waits behind it (below). Never start a card ahead of its dependencies.
- Read the code the request points at, and the constitution.
- Work out the base branch. A change that is part of a feature built on its
  own branch uses that branch as its base, not the main branch.

## 2. Interview in rounds

Treat the change as a tree of decisions. Each round, ask every decision whose
prerequisites are settled, numbered, each with your recommended answer, then
stop and wait:

```
❓ **Q1** - **<title>**: <question, with the choices if there are any>

➡️ <your recommended answer>
```

The answers open the next round. A question that depends on another question in
the same round waits for a later one. Never answer your own question and carry
on.

Worth a round, in this order:

1. **Scope**: where the change stops and what is deliberately left out,
   especially what belongs to other cards.
2. **Observable behaviour**: what the user sees in each state, including empty,
   error and slow.
3. **Data**: what is stored, and what happens to what is already stored.
4. **Edge cases**: the inputs and races the coder would otherwise discover.
5. **Done when**: outcomes someone can check without reading the diff.

Not worth a round: naming, style, file placement, anything with an obvious
default or that the repo answers.

The interview ends when every branch has been visited and nothing is silently
assumed. Say so, and confirm the shared understanding before you create the
card.

## 3. Write the brief

Follow `.speckit/templates/card/task.md` and skip empty sections.
`## Decisions` is what the interview pays for: one line per answer, in the
user's terms, with no reasoning. The specifier copies it into the spec, so
anything missing here gets asked again. `## Still open` is only for an
interview the user cut short, and every line needs a recommended default.

Two changes make two cards. Split them, brief each one, and say why.

## 4. Put it on the board

- **name**: the feature-map card name, kebab-case. It names what the change
  is (`backgrounded-polling`), not what it fixes.
- **kind**: `feat` for new behaviour, `fix` for broken behaviour, `chore` for
  everything else. The branch is `<kind>/<name>` and the artifacts go in
  `specs/<kind>-<name>/`.
- **depends on**: every unmerged card from the row's "Waits for", plus any live
  card that changes the same code.

**On Floe:** call `colony_add_task` with the brief as the description, plus
`kind`, `dependsOn`, `base`, and `autonomous: true` when nobody will be around
to answer. Pass `start: true` unless the user said to park it. A card with
unmet dependencies waits in the backlog and starts when they merge. Fix a
mistake in a backlog card with `colony_update_task`, never by removing and
re-adding it.

**By hand:** once every dependency has merged, create the branch from its base
(in its own worktree if the user works that way), write
`specs/<kind>-<name>/task.md`, and commit it as `docs(<name>): add card brief`.
The next step is `speckit-specify` on that branch.

## Report

Two lines: what you created, and whether it started or is waiting behind
something.

---

The round format is adapted from Matt Pocock's `grilling` skill:
<https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md>
