# History.DelRecsFromTradeSyncTSL111

> Enhanced successor to History.DelRecsFromTradeSyncTSL: same TSL archiving logic (Stage 2 of TSL pipeline) but with a per-batch TRY/CATCH that routes failed records to History.SyncTSLError instead of losing them, using a temp table buffer for error isolation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; processes Trade.SyncTSL WHERE Status IN (2,3) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs the same Stage 2 function as `History.DelRecsFromTradeSyncTSL` - moving confirmed TSL (Trailing Stop Loss) adjustment events from `Trade.SyncTSL` to `History.SyncTSL` in 500-ID batches. The key improvement over its predecessor is **error handling**: when a batch fails (e.g., due to a constraint violation or deadlock that READPAST could not skip), the failed rows are captured from the temp table and inserted into `History.SyncTSLError` for investigation, rather than being lost or leaving the batch in an inconsistent state.

The "111" suffix is an eToro naming convention indicating this is a later revision (not version 1 of the procedure). Change history in the comments shows this version was created by Adi (Dec 2016, FB 42955 - deadlock priority), updated in Nov 2017, and further modified by Danny R (Aug 2019 - READPAST for deadlock handling).

---

## 2. Business Logic

### 2.1 Two-Phase Atomic Move with Error Capture

**What**: Uses a temp table buffer so that failed batches are not lost but routed to SyncTSLError.

**Columns/Parameters Involved**: `#SyncTSL` (temp table), `@MinRecID`, `@MaxRecID`

**Rules**:
- Temp table `#SyncTSL` is created once and TRUNCATED at the start of each iteration.
- Phase 1 (in TRY): DELETE Trade.SyncTSL...OUTPUT INTO #SyncTSL (atomic delete from source into temp buffer).
- Phase 2 (in TRY): INSERT into History.SyncTSL from #SyncTSL (copy from buffer to archive).
- On CATCH: INSERT into History.SyncTSLError from #SyncTSL (failed rows go to error table), then THROW to propagate error.
- Key difference from predecessor: the predecessor uses `OUTPUT...INTO History.SyncTSL` directly (no error recovery). This version uses the temp buffer so that if the History.SyncTSL insert fails, the rows from the DELETE output are still available (in #SyncTSL) for the error branch.

**Diagram**:
```
For each 500-ID batch:
  TRY:
    DELETE Trade.SyncTSL WITH (READPAST) ... OUTPUT INTO #SyncTSL
    INSERT History.SyncTSL FROM #SyncTSL
    @MinRecID += 500
  CATCH:
    INSERT History.SyncTSLError FROM #SyncTSL   <- failed rows captured for investigation
    THROW                                        <- propagates to caller
```

### 2.2 Same Pipeline Position as Predecessor

- Stage 1: Trade.InsertTSLDataToSyncTbl inserts into Trade.SyncTSL (Status=0)
- **Stage 2** (this proc): Trade.SyncTSL (Status=2/3) -> History.SyncTSL (success) or History.SyncTSLError (failure)
- Stage 3: History.MoveRecsFromTradeSyncTSLToPass (TABLE SWITCH + BCP to DAG, then clear)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

*This procedure takes no parameters.*

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Scope determined by Trade.SyncTSL WHERE Status IN (2,3). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE (OUTPUT INTO #SyncTSL) | Trade.SyncTSL | Write (Delete) | Removes confirmed TSL events in 500-ID batches. Output goes to temp buffer. |
| INSERT | History.SyncTSL | Write (Insert) | Successful batches are inserted from temp buffer to archive table. |
| INSERT (on error) | History.SyncTSLError | Write (Insert) | Failed batches are inserted from temp buffer to error table for investigation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job (scheduled) | EXEC call | Scheduler | Called periodically to archive confirmed TSL events. This is the current/active version. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DelRecsFromTradeSyncTSL111 (procedure)
├── Trade.SyncTSL (table) [cross-schema - DELETE source]
├── History.SyncTSL (table) [INSERT target - success path]
└── History.SyncTSLError (table) [INSERT target - error path]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncTSL | Table | DELETE source WITH (READPAST) - confirmed records atomically removed to temp buffer. |
| History.SyncTSL | Table | INSERT target (success) - archived TSL events from temp buffer. |
| History.SyncTSLError | Table | INSERT target (error) - failed batch rows captured here when CATCH fires. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSL | Table | Populated by this procedure (success path). |
| History.SyncTSLError | Table | Populated by this procedure's error path when batch failures occur. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET DEADLOCK_PRIORITY LOW | Deadlock handling | Yields to trading engine on deadlock. |
| WITH (READPAST) | Lock skip | Skips locked rows (real-time TSL updates lock Trade.SyncTSL). Added by Danny R, Aug 2019, to resolve deadlock issues. |
| TRY/CATCH per batch | Error isolation | A failure in one 500-ID batch does not abort subsequent batches. Failed rows go to SyncTSLError. |
| TRUNCATE #SyncTSL per iteration | Buffer reset | Ensures temp table contains only the current batch's deleted rows for the error capture path. |

---

## 8. Sample Queries

### 8.1 Check TSL error table for failed batches

```sql
SELECT TOP 20 ID, PositionID, StopLoss, SLManualVer, DateInserted
FROM History.SyncTSLError WITH (NOLOCK)
ORDER BY DateInserted DESC;
```

### 8.2 Compare counts: Trade.SyncTSL confirmed vs History.SyncTSL archived

```sql
SELECT 'Trade.SyncTSL (Status 2/3)' AS Source, COUNT(*) AS Cnt
FROM Trade.SyncTSL WITH (NOLOCK) WHERE Status IN (2,3)
UNION ALL
SELECT 'History.SyncTSL', COUNT(*) FROM History.SyncTSL WITH (NOLOCK);
```

### 8.3 Find recently archived TSL records in History.SyncTSL

```sql
SELECT TOP 10 PositionID, StopLoss, NextThresHold, IsBuy, DateInserted
FROM History.SyncTSL WITH (NOLOCK)
ORDER BY DateInserted DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DelRecsFromTradeSyncTSL111 | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.DelRecsFromTradeSyncTSL111.sql*
