# Ownership semantics finalization (PR7)

Date: 2026-05-11

## What was finalized

- Friendly-boss ownership is now treated as ally semantics end-to-end and should no longer be intentionally represented as enemy ownership.
- Ownership relation decisions should route through `ProvinceSystem` relation helpers rather than ad hoc type-only checks.
- Ownership writes should pass through normalization helpers to keep type/faction combinations canonical.

## Regression matrix expectations

The following cases are considered mandatory regression coverage targets for future edits:

1. Non-player ally conquest
2. Player friendly-boss-assist annex
3. Defensive collapse
4. Boss spawn ownership writes
5. Migration idempotence and version-gating
6. Phase routing by relation helpers
7. UI owner text semantics consistency

## Cleanup posture

- Legacy/transitional behavior that intentionally encoded friendly-boss provinces as enemy-owned is considered retired.
- Any future compatibility shim should be explicitly time-boxed and documented with removal criteria.
