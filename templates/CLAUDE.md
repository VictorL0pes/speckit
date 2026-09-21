# <Project> — project constitution

<!-- One paragraph: what the product is and who uses it. -->

The product spec is in [`specs/product.md`](specs/product.md): decisions, scope,
feature map and glossary. The rules below are hard constraints for every change.
Where a rule and a personal preference differ, the rule wins.

## Stack

<!-- Language and framework versions, UI kit, auth, database, test runner,
linters. Note anything that must work on two engines (e.g. MySQL in dev,
SQLite in tests). -->

## Commands

- `<cmd>`: run the app locally.
- `<cmd>`: **the quality gate** (lint, types, tests). **It must pass before any
  change is done.**
- `<cmd>`: auto-fix formatting.
- `<cmd>`: run a focused test.

## Spec-driven workflow

- Work is done in cards, on a colony board or by hand, and each card gets its
  own branch (`<kind>/<name>`) and worktree.
- Lanes, in order: specifier → **spec-review** (the user approves) → coder →
  cleaner → architect → hardener → qa. Each lane is a `speckit-*` skill.
- Each card's documents live in `specs/<branch-with-dashes>/`.
- **No product code is written before the user has approved that card's spec.**
- The code must match the approved spec. If it can't, the card goes back to the
  specifier. Never drift silently.
- A card's spec stays inside that card's scope. The feature map in
  `specs/product.md` shows which card owns what.
- Lane rules (what each lane reads, artifact caps, hand-off) live in the
  `speckit-*` skills, not here.

## Language

<!-- What users see (UI, messages, emails, documents): language, currency,
date format. Everything else (code, identifiers, commits, specs): English. -->

## Architecture rules

<!-- Numbered, short, checkable. Where business logic lives, where validation
lives, read models, enums and labels, routes, frontend layout, units of
measure, dependencies (every new package justified in the card's plan.md). -->

1. <rule>

## Security and data

<!-- Tenancy: who can see what, and how queries are scoped. Authorization.
Sensitive data: how it is stored, and that it is never logged. Where secrets
live. Tests never call external services. -->

- Every feature has tests proving that one account can't list, view, create
  under, update or delete another account's data.

## Tests

- Every model has a factory, and every unit of business logic is tested.
- Feature tests cover the happy path, validation and access from another
  account.
- Never delete or weaken an existing test to make the suite pass.

## Git

- Use conventional commit messages (`feat:`, `fix:`, `chore:`, `test:`,
  `docs:`, `refactor:`).
- Never commit `.env` files, credentials or local storage.
