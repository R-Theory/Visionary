Architecture Decision Records (ADRs)

Purpose
- Capture significant technical decisions with context, options, and consequences.

Conventions
- Files live in `docs/ADRS` and are numbered `0001-title.md`.
- Status values: `proposed`, `accepted`, `superseded`, `deprecated`.

Create a new ADR
- Use the helper: `bin/new-adr "Short decision title"`
- Or via just: `just adr -- "Short decision title"` (after the just task is added)

Template
---
adr: NNNN
title: My Decision
status: proposed
date: YYYY-MM-DDThh:mm:ssZ
---

# My Decision

## Context
## Decision
## Consequences
## Alternatives Considered
## References
