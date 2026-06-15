# Phase 4 warnings - DRY-RUN

## Files emptied (1)

Files where the triggers list dropped to size 0 after removals.
These hubs will be unroutable until someone adds replacement triggers.

- `knowledge/skills/domain-revenue-and-fees/revenue-moneyfarm.md`

## Unmatched drop_from entries (0)

Ledger entries where drop_from listed a hub but no file in that hub
had the concept as a literal trigger. Most likely cause: the concept
appeared in required_tables or sample_questions in that hub (NOT in
triggers), and the inventory flagged it because we scanned all three
fields. No edit needed.

| Hub | Concept |
|---|---|
