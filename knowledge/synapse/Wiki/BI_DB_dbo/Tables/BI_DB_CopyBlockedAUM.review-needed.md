# BI_DB_dbo.BI_DB_CopyBlockedAUM — Review Needed

Generated: 2026-04-23 | Batch: 74

## Open Items

### HIGH — UC Migration Decision
**UC Target is `_Not_Migrated`** — this table is not in the Generic Pipeline mapping and has no Unity Catalog target. With 691 rows of blocked-PI risk data refreshed daily, a migration decision is needed.
- Confirm: Is this table an input to any UC-layer analytics or reports?
- Action: Raise with Data Platform team to determine if migration is required.

### MEDIUM — `DaysUnderRisk6` Type Design
Column is `nvarchar(5)` storing mixed-type values: numeric strings `'0'`–`'30'`, the sentinel `'31+'`, and `NULL`. Any consumer that casts to INT without handling `'31+'` and `NULL` will fail.
- Action: Confirm this is intentional design (legacy pattern) and document in consuming queries.
- Potential improvement: Split into `DaysUnderRisk6_Numeric INT` and `IsOver31Days BIT`.

### MEDIUM — `DaysSinceMaxRiskScore8 = -1` Sentinel
Returns `-1` when the PI has never reached risk score 8. This is an unnatural value in an INT column — could be confused with a data error.
- Action: Confirm sentinel convention is consistent with other risk tables (e.g., `DWH_CIDsDailyRisk`).

### LOW — Equity Source: `V_Liabilities` View
`Equity = ActualNWA + Liabilities` is sourced from `DWH_dbo.V_Liabilities`. This view definition should be confirmed to ensure the formula has not been updated since SP authorship (2021-11-22).
- Action: Read `DWH_dbo.V_Liabilities` DDL and verify `ActualNWA + Liabilities` formula.

### LOW — No Confluence Documentation Found
No DATA space pages identified for this table or the blocked-PI monitoring process.
- Action: Check with Tom Boksenbojm or Dan's team for any operational runbooks covering blocked-PI AUM monitoring.

### INFO — History Table Relationship
`BI_DB_CopyBlockedAUMHistory` is written by the same SP and contains risk-score history for **currently blocked PIs only** (filtered via JOIN to `#blockedusers` temp table). This means unblocked PIs' history is silently dropped from the history table when they are unblocked.
- Action: Confirm this is intentional behavior and not a data loss risk.
