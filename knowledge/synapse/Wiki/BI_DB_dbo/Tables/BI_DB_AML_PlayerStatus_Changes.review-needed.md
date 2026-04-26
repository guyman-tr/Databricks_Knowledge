# Review: BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes

*Sidecar for wiki review. Does NOT contain wiki content — see BI_DB_AML_PlayerStatus_Changes.md.*
*Generated: 2026-04-21 | Batch 14 #4*

## Ghost Column — Confirmed by Live Data

| Column | Status | Finding |
|--------|--------|---------|
| PlayerStatusSubReasonName | **Always NULL** | Confirmed via live query: 0 rows have a non-NULL value. DDL defines the column; SP's INSERT omits it. This column is a dead artifact — DDL was never cleaned up after SP was written without it. |

**Reviewer action**: Confirm there are no consumers depending on this column. If confirmed unused, consider dropping it from DDL (requires DDL change + deployment).

## Business Logic Questions

1. **Is_FTD naming confusion**: Column is named `Is_FTD` but is computed as `CASE WHEN fsc.IsDepositor=1 THEN 1 ELSE 0 END` — a depositor flag, not a first-time-deposit event indicator. Should this be renamed to `IsDepositor` for clarity? Any existing reports relying on this field should be verified against the correct interpretation.

2. **72% N/A previous status**: 19.6M of 27.2M rows have `Previous_PlayerStatus = 'N/A'`. These are first-time status assignments, not genuine status transitions. Is this intentional design (include all first assignments for completeness), or should the SP be updated to only capture genuine changes (WHERE Previous_ID > 0)?

3. **TRUNCATE risk at 27M rows**: The SP truncates the entire table before rebuilding. If the SP fails after TRUNCATE but before INSERT completes, the table is empty until the next successful run. Is there a downstream alert or health check for table emptiness?

4. **PII at ETL time vs. change time**: Customer PII (name, email, phone) reflects the current state at daily rebuild, not at the time of the status change. Compliance use cases (e.g., "what name was this customer using when they were blocked in 2018?") cannot be answered from this table. Is this a known limitation, or do downstream consumers mistakenly assume historical PII?

5. **VerificationLevelID >= 2 filter**: Only customers at Level 2+ are included. Was there a period when Level 1 customers had status changes that are now excluded? Any compliance audit covering pre-2015 history should verify coverage.

6. **HEAP index at 27M rows**: No clustered index on a 27M-row ROUND_ROBIN table. Queries filtering by CID, Change_Date, or PlayerStatusReason will do full scans. Is there a plan to add an index? (e.g., CLUSTERED INDEX on Change_Date or CID)

## UC Target Uncertainty

Table not found in generic pipeline mapping. Assumed `_Not_Migrated`. Reviewer should confirm:
- Is there a Databricks/UC equivalent for AML status change history?
- If migrated, update wiki UC Target field and generate ALTER script.

## No Issues Found

- Element count: 32/32 — matches DDL ✓
- LAG() change detection logic traced to SP code ✓
- Three-step temp table pipeline (#pop → #days → #client → #final) traced ✓
- TRUNCATE+INSERT load pattern documented ✓
- Ghost column (PlayerStatusSubReasonName) confirmed via live query (0 non-NULL rows) ✓
- Row count (27.2M) and distinct CIDs (19.6M) confirmed via live query ✓
- PlayerStatus trailing spaces noted for both Current and Previous values ✓
