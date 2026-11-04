# Maintaining these steering notes

Keep these notes true. When a change makes something here wrong, update it in
the same piece of work, without being asked and without asking permission.
A stale steering note is worse than none, because it is trusted.

## What belongs here

General, durable facts about the repository: purpose, the publications, file
structure, how to build, how printing works, conventions. Describe the state
the repository is actually in, not plans or history.

## What does not

Task notes, changelogs, migration plans, or anything already obvious from the
file tree. Deep internals of the two chant packages belong to those packages,
not here — see below.

## Triggers

Update the relevant file when any of these change:

| Change | File |
|---|---|
| a document added, removed or renamed | `product.md`, `structure.md` |
| directories moved, files relocated | `structure.md` |
| build command, fonts, dependencies, container | `build.md` |
| printing model, tags, `reprint.py`, `scramble.py` | `printing.md` |
| naming or layout conventions | `structure.md` |

## Scope

Steering is loaded from `.kiro/steering/` **relative to the directory Kiro is
started in**, and is not picked up from subdirectories. So:

- this directory is what loads when working in the repository root
- `gregosheet/.kiro/steering/` loads only when that submodule is opened as the
  workspace — it is a separate repository with its own history
- `gregosheet-psalm/.kiro/steering/` likewise, when working in that directory

Package internals therefore live with the package. Keep only a short summary
here and let the package's own steering carry the detail, so the two never
drift into contradicting each other. The former root `STEERING.md` was a stale
copy of gregosheet's and was removed for exactly that reason.

Files here are committed to git deliberately: they are project configuration
and are meant to be shared.
