# eMoney_dbo.eMoneyProcessStatusLog

> Append-only ETL process audit log for the eToro Money Synapse pipeline. Recorded Start/Complete/Fail events for each SP execution in the eTM pipeline orchestration (SP_eMoney_Execute_Group_One). 16,726 rows covering 2022-11-23 to 2023-10-30. FROZEN since 2023-10-30 when all SP calls in the orchestrator were commented out. Historical log remains queryable for audit purposes.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (ETL Process Audit Log) |
| **Production Source** | ETL infrastructure — populated via SP_eMoneyProcessStatusLog INSERT calls |
| **Refresh** | Append-only INSERT per SP lifecycle event; FROZEN since 2023-10-30 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 16,726 (sampled 2026-04-21; date range 2022-11-23 to 2023-10-30) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Gold layer |

---

## 1. Business Meaning

`eMoneyProcessStatusLog` is the operational audit log for the eToro Money (eTM) Synapse ETL pipeline. It records lifecycle events (Start, Complete, Fail) for every stored procedure executed within the eTM pipeline orchestration, driven by `SP_eMoney_Execute_Group_One`.

Each SP execution generates at least one log entry:
- **Start** entry when the SP begins
- **Complete** entry on success
- **Fail** entry on error (with the error message in `ErrorDescription`)

The log covered 17 distinct SP names across approximately 851 daily pipeline runs (2022-11-23 to 2023-10-30). The most active SP was `SP_eMoney_Dim_Country_Rollout` (1,702 entries), reflecting roughly 851 Start+Complete pairs. Out of 16,726 total rows, 32 are Fail entries recording pipeline errors.

**Why it is frozen**: On 2023-10-30, Katy F commented out all SP execution calls within `SP_eMoney_Execute_Group_One` (git history / SP comment header). From that date onward, each eTM SP runs independently (likely via separate Synapse or ADF pipelines) and no longer calls `SP_eMoneyProcessStatusLog`. The CATCH block (which would log Fail events) remains un-commented — new Fail entries would appear if `SP_eMoney_Execute_Group_One` itself were called and failed.

**Operational significance**: The log is valuable for historical debugging, understanding how frequently each SP was run, and identifying past failure patterns.

---

## 2. Business Logic

### 2.1 SP Lifecycle Pattern

**What**: Each SP call generates a Start-then-Complete or Start-then-Fail pair of log entries.

**Columns Involved**: `ProcessName`, `ProcessStatus`, `ProcessStatusTime`

**Rules**:
- Before each SP: `EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Start', NULL`
- On success: `EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Complete', NULL`
- On failure (CATCH block): `EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Fail', @ErrorDescription`
- 8,377 Start entries, 8,317 Complete entries → ~60 calls that started but did not complete (mostly from Fail scenarios)
- 32 Fail entries recorded; observed errors include "Invalid object name '#Final'" and "Invalid column name 'IsValidETM'" (schema evolution issues)

### 2.2 Frozen Status (2023-10-30)

**What**: The log stopped receiving new entries on 2023-10-30 when the orchestration pattern changed.

**Columns Involved**: `ProcessStatusDate` (max = 2023-10-30)

**Rules**:
- All 15 SP execution calls in `SP_eMoney_Execute_Group_One` were commented out by Katy F
- Individual SPs (e.g., SP_eMoney_Dim_Account) continue to run but via a different orchestration mechanism that does not call this log
- The CATCH block in `SP_eMoney_Execute_Group_One` (lines 153-154) is still active — Fail entries for the orchestrator SP itself would be written if triggered

### 2.3 NULL ProcessName Rows

**What**: 9 rows have NULL ProcessName — these are orchestrator-level log entries.

**Rules**:
- These entries come from the top-level `@JobName` variable calls in `SP_eMoney_Execute_Group_One`
- The initial Start call for the job itself uses `@JobName = 'SP_eMoney_Execute_Group_One'` but was also commented out
- The 9 NULL rows likely represent edge cases from early pipeline runs before the SP naming convention was finalized

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. The table is read-only at this point (frozen). Queries should use `WHERE ProcessStatusDate` predicates to leverage date-range filtering. No indexes exist — full scans on 16,726 rows are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Was the pipeline running on a specific date? | `SELECT * FROM eMoneyProcessStatusLog WHERE ProcessStatusDate = '2023-10-15'` |
| How many times did each SP run? | `SELECT ProcessName, COUNT(*)/2 AS RunCount FROM ... WHERE ProcessStatus IN ('Start','Complete') GROUP BY ProcessName` |
| What errors occurred? | `SELECT * FROM ... WHERE ProcessStatus = 'Fail' ORDER BY ProcessStatusTime DESC` |
| What was the last successful run? | `SELECT MAX(ProcessStatusDate) FROM ... WHERE ProcessStatus = 'Complete'` |
| SP execution timeline for a date | `SELECT * FROM ... WHERE ProcessStatusDate = '2023-10-30' ORDER BY ProcessStatusTime` |

### 3.3 Common JOINs

This table is not typically joined to other tables. It is a standalone audit log.

### 3.4 Gotchas

- **FROZEN**: Last entry was 2023-10-30. Do not expect recent data.
- **No TRUNCATE**: Unlike most eTM tables, this log uses append-only INSERT — historical data is preserved.
- **Start/Complete pairs**: Count of Start (8,377) > Count of Complete (8,317) because Fail events replace the Complete entry; 32 Fails accounted for.
- **NULL ProcessName**: 9 rows have NULL ProcessName — orchestrator-level edge cases.
- **ErrorDescription truncation**: Error messages are truncated to 4,000 chars by `SUBSTRING(@ErrorDescription, 1, 4000)`.
- **SP_eMoney_Execute_Group_One CATCH still active**: If this orchestrator SP were called today and failed, new Fail entries would be written.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Description written from ETL SP code analysis |
| Tier 3 | Description inferred from column name and context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProcessName | nvarchar(500) | YES | Name of the ETL stored procedure being executed. Passed as the `@ProcessName` parameter to SP_eMoneyProcessStatusLog. 17 distinct values observed: SP_eMoney_Dim_Country_Rollout (1,702 entries), SP_eMoney_Account_Mappings (1,700), SP_eMoney_Dim_Account (1,698), SP_eMoney_Execute_Group_One (1,683), SP_eMoney_Snapshot_Settled_Balance (1,681), SP_eMoney_Panel_FirstDates (1,668), SP_eMoney_Reports_Daily (1,652), SP_eMoney_DimFact_Transaction (1,586), SP_eMoney_Panel_Retention (1,426), and others. NULL for 9 orchestrator-level edge-case entries. (Tier 2 — SP_eMoneyProcessStatusLog) |
| 2 | ProcessStatus | nvarchar(50) | YES | Execution lifecycle status of the SP. 3 values: Start (8,377 entries — logged before SP begins), Complete (8,317 entries — logged on successful completion), Fail (32 entries — logged on error with error message in ErrorDescription). (Tier 2 — SP_eMoneyProcessStatusLog) |
| 3 | ProcessStatusTime | datetime | YES | `GETDATE()` at INSERT time — the exact timestamp of the status event. Enables SP-level duration calculation by differencing Start and Complete/Fail timestamps for the same ProcessName. (Tier 2 — SP_eMoneyProcessStatusLog) |
| 4 | ProcessStatusDate | date | YES | `CAST(GETDATE() AS DATE)` — the date portion of ProcessStatusTime. Enables date-level filtering without timestamp precision. Range: 2022-11-23 to 2023-10-30. (Tier 2 — SP_eMoneyProcessStatusLog) |
| 5 | ErrorDescription | nvarchar(4000) | YES | Error message for Fail entries, passed as `@ErrorDescription` parameter and truncated to 4,000 characters via `SUBSTRING(@ErrorDescription, 1, 4000)`. NULL for Start and Complete entries (NULL is passed explicitly). Observed error examples: "Invalid object name '#Final'" (SP_eMoney_Reports_Daily, 2023-05-09), "Invalid column name 'IsValidETM'" (SP_eMoney_Reports_Daily, 2022-12-22 — pre-IsValidETM column addition). (Tier 2 — SP_eMoneyProcessStatusLog) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column | Production Source | Source Column | Transform |
|-----------|-------------------|--------------|-----------|
| ProcessName | SP parameter | @ProcessName | Passthrough |
| ProcessStatus | SP parameter | @ProcessStatus | Passthrough |
| ProcessStatusTime | System | GETDATE() | System timestamp at INSERT |
| ProcessStatusDate | System | GETDATE() | CAST(GETDATE() AS DATE) |
| ErrorDescription | SP parameter | @ErrorDescription | SUBSTRING(…, 1, 4000) — truncation |

### 5.2 ETL Pipeline

```
SP_eMoney_Execute_Group_One (orchestrator, all SPs commented out since 2023-10-30)
  |-- BEFORE each SP: EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Start', NULL
  |-- AFTER each SP:  EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Complete', NULL
  |-- ON ERROR:       EXEC SP_eMoneyProcessStatusLog @ProcessName, 'Fail', @ErrorDescription
  |-- (CATCH block remains ACTIVE; Start/Complete pairs all commented out)
  v
eMoney_dbo.eMoneyProcessStatusLog
  (INSERT only — append log; FROZEN as of 2023-10-30; 16,726 rows)
  No UC export target.
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no FK relationships — it records free-text SP names, not keys.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.SP_eMoney_Execute_Group_One | — | Primary caller (writes Start/Complete/Fail entries); all SP calls commented out since 2023-10-30 except CATCH block |
| eMoney_dbo.SP_eMoneyProcessStatusLog | — | Writer stored procedure (INSERT-only) |

---

## 7. Sample Queries

### 7.1 Pipeline failure history

```sql
SELECT ProcessName, ProcessStatusTime, ErrorDescription
FROM eMoney_dbo.eMoneyProcessStatusLog
WHERE ProcessStatus = 'Fail'
ORDER BY ProcessStatusTime DESC;
```

### 7.2 Approximate daily SP run durations (2023-10)

```sql
SELECT
    s.ProcessName,
    s.ProcessStatusDate,
    DATEDIFF(SECOND, s.ProcessStatusTime, c.ProcessStatusTime) AS DurationSeconds
FROM eMoney_dbo.eMoneyProcessStatusLog s
JOIN eMoney_dbo.eMoneyProcessStatusLog c
    ON s.ProcessName = c.ProcessName
   AND s.ProcessStatusDate = c.ProcessStatusDate
   AND s.ProcessStatus = 'Start'
   AND c.ProcessStatus IN ('Complete', 'Fail')
WHERE s.ProcessStatusDate = '2023-10-30'
ORDER BY s.ProcessStatusTime;
```

### 7.3 SP execution counts by SP name

```sql
SELECT
    ProcessName,
    SUM(CASE WHEN ProcessStatus = 'Start' THEN 1 ELSE 0 END) AS StartCount,
    SUM(CASE WHEN ProcessStatus = 'Complete' THEN 1 ELSE 0 END) AS CompleteCount,
    SUM(CASE WHEN ProcessStatus = 'Fail' THEN 1 ELSE 0 END) AS FailCount
FROM eMoney_dbo.eMoneyProcessStatusLog
GROUP BY ProcessName
ORDER BY StartCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: P1-P10A/14 (P10 Atlassian skipped)*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5*
*Object: eMoney_dbo.eMoneyProcessStatusLog | Type: Table | Production Source: ETL infrastructure — SP_eMoneyProcessStatusLog INSERT calls from SP_eMoney_Execute_Group_One*
