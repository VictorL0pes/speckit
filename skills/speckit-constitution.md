---
name: speckit-constitution
description: Project kickoff for spec-driven work. Interview the user, then write the constitution (CLAUDE.md) and the product spec (specs/product.md) with its feature map of cards in dependency order.
---

# Project kickoff: constitution and product spec

Every card on the board is judged against two documents. You write them.

- **`CLAUDE.md`**, the constitution: the project's hard rules. Stack, commands,
  the one quality gate, architecture, security, tests, language, git. Every lane
  obeys it.
- **`specs/product.md`**, the product spec: what the product is, who uses it,
  the product decisions, and the **feature map**, which lists the cards in
  dependency order. Only the specifier reads it. Every later lane works from
  its card's `spec.md`.

Templates: `.speckit/templates/CLAUDE.md` and `.speckit/templates/product.md`.
Both files are in English, whatever language the user speaks.

## 1. Find the facts yourself

Before asking anything, read what the repo already answers: the manifests
(`composer.json`, `package.json`, `pyproject.toml`, `go.mod`…), the test and lint
configs, CI workflows, the existing `CLAUDE.md` or `AGENTS.md`, and the README.
Work out the stack, the commands and the current conventions. Never ask the user
something the repo answers.

If `CLAUDE.md` exists, you are extending it. Keep every rule it has, fill the
missing sections, and show the user what you changed.

## 2. Interview in rounds

The decisions are the user's. Ask every question you can ask now in one round,
numbered, each with your recommended answer, then stop and wait:

```
❓ **Q1** - **<title>**: <question, with the choices if there are any>

➡️ <your recommended answer>
```

Each round of answers opens new questions. Ask those in the next round. A
question that depends on another question in the same round waits for a later
round. Stop when nothing is left silently assumed, and confirm the shared
understanding before you write anything.

Worth a round, in this order:

1. **Product**: what it is, for whom, and the decisions that shape it: who
   logs in, who owns the data, what it charges for, what is out of scope for
   the whole product.
2. **Feature map**: the cards, what each one delivers, and what each one waits
   for. A card should fit a `spec.md` of 6 KB. Split anything bigger.
3. **Hard rules**: tenancy and data access, sensitive data, user-facing
   language, money, dates and units, and rules for where logic lives.
4. **Workflow**: the quality gate command, test expectations, commit style.

Not worth a round: anything with an obvious default, or anything the repo
answers.

## 3. Write

- `specs/product.md` from the template. Product decisions go under
  `## Product decisions` as `- Q: <question> -> A: <answer>`. The feature map
  table lists every card: `#`, card name (kebab-case, which becomes the
  branch's last segment), what it waits for, and what it delivers.
- `CLAUDE.md` from the template. Rules are short, imperative and checkable.
  Each rule a lane could break should be one a reviewer can point to. Keep the
  `## Spec-driven workflow` section as it is.

Commit both files: `docs: add the project constitution and product spec`.

## Report

The two paths, the number of cards in the feature map, and the first card that
can start. Then suggest `speckit-add-task` for it.
