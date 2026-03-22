---
object: Dealing_MAXLeverageByNOP
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_MAXLeverageByNOP — Review Notes

## Auto-Generated Flags

- **GETDATE() vs. @Date**: SP uses GETDATE() rather than an explicit @Date parameter. This means if the SP re-runs on the same day, it overwrites (TRUNCATE+INSERT) with the same date. Confirm: is there a guard against double-runs, or is idempotent re-run acceptable?
- **AccountType values**: Sample showed 'Default/Default' — enumerate all valid AccountType values (e.g., Professional, Retail, Islamic). Are leverage tiers different for professional vs. retail accounts?
- **NOP tier direction**: NOP1 appears to be the lowest tier (smallest NOP bound). Confirm: does leverage decrease as tier number increases (NOP1 < NOP2 < … < NOP5 with Leverage1 > Leverage2 > … > Leverage5)?
- **Currency of NOP thresholds**: Are NOP1-NOP5 values in USD, or instrument-native currency? Sample showed NOP1=10,000,000 — confirm this is USD.
- **Exact DDL column names**: Column names (NOP1-5, Leverage1-5) inferred from SP JSON_VALUE extraction pattern. Reviewer: confirm exact column names match the DDL.
- **6.3M row table**: At ~daily cadence × instruments × directions × account types — confirm whether old rows are retained or truncated/reloaded. If TRUNCATE+INSERT, historical audit is in git/snapshot history only.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
