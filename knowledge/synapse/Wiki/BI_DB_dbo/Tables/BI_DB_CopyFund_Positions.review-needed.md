# BI_DB_dbo.BI_DB_CopyFund_Positions — Review Needed

Generated: 2026-04-23 | Batch: 74

## Open Items

### HIGH — UC Migration Decision
**UC Target is `_Not_Migrated`** — not in Generic Pipeline. At ~325.9M rows and serving as the position-level backing store for Copy Fund analytics, this is a critical table for migration planning.
- Action: Assess with Data Platform team. Given COLUMNSTORE + HASH(PositionID), the UC equivalent would need careful partitioning design.

### HIGH — Duplicate PositionIDs: Root Cause Unknown
SP comment (2025-09-08): "there is some bizarre rare occurrence with duplicated positions." Post-load dedupe code was added as a workaround.
- Action: Investigate root cause in DWH_dbo.Dim_Position or the SP_CopyFund_Positions load logic. The dedupe keeps `MAX(CloseDateID)` which may not always be the correct value.
- Risk: If a closed position's CloseDateID gets overwritten by the wrong value during dedupe, closed positions could appear open.

### MEDIUM — `UpdateDate` Is Nullable
DDL defines `UpdateDate` as `datetime NULL`, but all ETL writes set it to `GETDATE()`. NULL values could indicate a load failure or partial run.
- Action: Confirm no rows have NULL UpdateDate. Consider making NOT NULL in UC schema.

### MEDIUM — `CloseDateID = 19000101` Transient State
Inherited from DWH_dbo.Dim_Position: `CloseDateID = 19000101` is a rare ETL transient state (not a closed position, not a sentinel for open). Queries filtering for open positions (`CloseDateID = 0`) correctly exclude these but analysis of "recently closed" positions may inadvertently include them.
- Action: Add `AND CloseDateID NOT IN (0, 19000101)` in closed-position filters.

### MEDIUM — IsPartialCloseChild Stored as int, Not bit
Column type is `int` (values: 0 or 1). Using `bit` would save space and be semantically clearer.
- Action: Fix to `bit` when creating UC schema.

### MEDIUM — ParentUserName Is varchar(500)
Username values are typically < 30 chars. Over-provisioned at 500. For a 325.9M row COLUMNSTORE table, this affects compression efficiency.
- Action: Use varchar(50) in UC schema.

### LOW — Load Does Not Recapture Previously-Closed Positions
The delete/insert scope is `OpenDateID=@dateID OR (CloseDateID=@dateID AND IsPartialCloseChild=1)`. Positions that closed before @date (CloseDateID < @dateID) are not reprocessed. If Dim_Position retroactively updates a prior close date, this table will be stale.
- Action: Confirm with Data Platform whether retroactive Dim_Position corrections are possible and whether a repair mechanism is needed.

### INFO — Author Context
Guy Manova authored this table on 2025-03-07 as infrastructure improvement for Copy Fund analytics, eliminating a runtime JOIN from Positions to MirrorIDs. Three subsequent SP revisions (2025-05-05, 2025-07-06, 2025-09-08) fixed partial close children handling, rerun safety, and duplicate positions.
