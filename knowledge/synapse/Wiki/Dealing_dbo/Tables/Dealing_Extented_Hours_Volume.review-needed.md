---
object: Dealing_dbo.Dealing_Extented_Hours_Volume
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_Extented_Hours_Volume

## Auto-Generated Flags

- [ ] **Stale since Aug 2025**: OpsDB-tracked (Priority 0) but suspended ~7 months. Same stop date as `Dealing_Extented_Hours_NewCID`. Confirm if both SPs were intentionally paused together.
- [ ] **`OverNight_Session` not backfilled**: Category added March 2025 — pre-March positions are classified into only 3 categories. Historical queries spanning the March 2025 boundary must handle this. Should historical data be backfilled?
- [ ] **Session time boundaries**: Documented as UTC times (10:30, 13:30, 20:00). Confirm UTC vs. local exchange time — pre-session for US equities starts at 4 AM ET (09:00 UTC), not 10:30 UTC.
- [ ] **HASH distribution on PositionID**: Only HASH-distributed table in Dealing_dbo. Confirm this is intentional (optimization for PositionID joins) and not an inadvertent configuration.
- [ ] **`Volume` decimal(38,2)**: Very wide decimal type. Confirm if values ever exceed standard float/decimal(18,2) range or if this is over-engineered.
- [ ] **Typo in object name**: "Extented" — same as companion table. Confirm if renaming is planned.

## Reviewer Corrections

<!-- Add corrections here. -->
