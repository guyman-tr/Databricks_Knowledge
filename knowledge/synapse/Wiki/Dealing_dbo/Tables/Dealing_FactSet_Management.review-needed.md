# Review Notes: Dealing_FactSet_Management

## Auto-generated flags

| # | Flag | Detail |
|---|------|--------|
| 1 | STALE since 2024-06-04 | Confirm whether FactSet integration was officially decommissioned — this control table's IsActive/date fields are frozen as of June 2024 |
| 2 | DELETE rule risk | SP deletes rows where DailyFirstSentDate IS NULL AND IsActive=1 — if SP_FactSet_Management and SP_FactSet_Daily don't run on the same day, newly inserted PI rows could be deleted on the next Management run |
| 3 | HistorySendFlag management | This flag appears to be manually set for triggering history sends — confirm who manages this and whether any automation governs it |
| 4 | CopyType source | CopyType from Dim_Range — confirm the range logic maps correctly to 'PI' vs 'CP' values |
