# History.SyncTSLError

> Dead-letter error capture table for the TSL synchronization pipeline - rows are written here when History.DelRecsFromTradeSyncTSL111 fails to move a TSL event batch from Trade.SyncTSL to History.SyncTSL, preserving the failed records for investigation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | None - no PK constraint defined |
| **Partition** | No - stored on [DICTIONARY] filegroup |
| **Indexes** | 0 (no indexes) |

---

## 1. Business Meaning

History.SyncTSLError is the error/dead-letter destination in the Trailing Stop Loss (TSL) synchronization pipeline. It captures TSL event batches that could not be moved from Trade.SyncTSL to History.SyncTSL due to an exception in History.DelRecsFromTradeSyncTSL111.

The table functions as a safety net: rather than silently discarding failed TSL events, the CATCH block in the pipeline procedure dumps the in-flight batch here before re-throwing the error. This allows operations and engineering teams to identify exactly which TSL events were lost in a failed pipeline cycle, enabling manual recovery or replay.

In normal operations this table should be empty or rarely populated - any rows indicate a pipeline failure that requires investigation. The table is not deployed in the current (clone) environment, consistent with it being a rarely-used error container.

For full context on the TSL pipeline, see History.SyncTSL (the normal destination) and History.SyncTSLSwitch (the switch twin).

---

## 2. Business Logic

### 2.1 TSL Pipeline Error Capture

**What**: History.DelRecsFromTradeSyncTSL111 moves TSL events from Trade.SyncTSL to History.SyncTSL in batches of 500. If an error occurs during the History.SyncTSL INSERT, the CATCH block captures the failed batch here and re-throws the error.

**Columns/Parameters Involved**: `ID`, `PositionID`, `StopLoss`, `SLManualVer`, `NextThresHold`, `IsBuy`, `DateInserted`

**Rules**:
- Rows are inserted here ONLY in the CATCH block of History.DelRecsFromTradeSyncTSL111 - exclusively on failure
- The inserted rows come from #SyncTSL temp table (the batch that was being processed when the error occurred)
- After inserting the error rows the procedure re-throws the exception (THROW), so the caller is aware of the failure
- No PK or unique constraint - duplicate rows could theoretically be inserted if multiple failures occur for the same batch
- StopLoss and NextThresHold are stored as native numeric(16,8) (not the dbo.dtPrice UDT), matching the #SyncTSL temp table definition in the procedure

**Diagram**:
```
History.DelRecsFromTradeSyncTSL111
  |
  |-- (normal path) --> History.SyncTSL (staging buffer)
  |
  |-- (error path, CATCH block) --> History.SyncTSLError (dead-letter)
                                       |
                                       +-- contains: same batch data from #SyncTSL
                                       +-- error re-thrown to caller
```

---

## 3. Data Overview

Table is not deployed in the current environment ("Invalid object name" - consistent with rarely-used error table). In production, rows appear only during TSL pipeline failures. A populated table signals an active or recent pipeline incident requiring investigation and potential record replay into History.SyncTSL.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | BIGINT | NO | - | CODE-BACKED | TSL event sequence ID from Trade.SequenceSyncTSL. Matches the ID values that were being moved from Trade.SyncTSL when the error occurred. No uniqueness constraint - the same ID could be re-inserted if recovery is attempted multiple times. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | BIGINT trading position identifier whose TSL adjustment event failed during pipeline transfer. BIGINT (unlike the retired History.SyncTSL_INT which used INT) confirming this table belongs to the post-Nov 2021 BIGINT migration era. |
| 3 | StopLoss | NUMERIC(16,8) | NO | - | CODE-BACKED | The adjusted trailing stop-loss price captured at the time of pipeline failure. Stored as native numeric(16,8) (matching the #SyncTSL temp table in the procedure), rather than the dbo.dtPrice UDT used in History.SyncTSL. The precision is identical (16,8). |
| 4 | SLManualVer | SMALLINT | NO | - | CODE-BACKED | Manual stop-loss version counter at the time of failure. Allows identifying which specific TSL adjustment generation was being processed when the error occurred. |
| 5 | NextThresHold | NUMERIC(16,8) | NO | - | CODE-BACKED | The next TSL trigger threshold price at the time of pipeline failure, in instrument rate units (precision 16,8). Together with StopLoss and IsBuy, fully captures the TSL state snapshot needed for recovery replay. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Position direction: 1 = Buy/Long, 0 = Sell/Short. Required to correctly replay or reconcile the failed TSL event with the trading engine. |
| 7 | DateInserted | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the TSL event was originally recorded in Trade.SyncTSL. Preserved from the source record - represents the original event time, not the failure time. Useful for determining how long a failed event had been in the pipeline before the error occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | References the trading position whose TSL event failed. Inherited from the pipeline source row. |
| ID | Trade.SyncTSL | Implicit | ID originates from Trade.SequenceSyncTSL and was already present in Trade.SyncTSL; this table captures the same ID at failure time. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.DelRecsFromTradeSyncTSL111 | - | Writer (INSERT in CATCH) | Sole writer. Inserts failed TSL batches from #SyncTSL temp table when the History.SyncTSL INSERT fails. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SyncTSLError (table)
  (leaf - no code-level dependencies in CREATE TABLE DDL)
```

### 6.1 Objects This Depends On

No dependencies. CREATE TABLE has no FK constraints, no UDTs, no computed columns.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.DelRecsFromTradeSyncTSL111 | Stored Procedure | WRITER (CATCH block) - inserts failed TSL batches |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The table has no PK, no clustered index, and no nonclustered indexes. This is consistent with an error/dead-letter table that is expected to be rarely populated and queried only during incident investigation.

### 7.2 Constraints

None. No PK, CHECK, DEFAULT, or UNIQUE constraints are defined. Rows can be freely inserted during error recovery.

---

## 8. Sample Queries

### 8.1 Check for active pipeline failures
```sql
SELECT COUNT(*) AS ErrorCount
FROM History.SyncTSLError WITH (NOLOCK);
-- Any count > 0 indicates a TSL pipeline failure requiring investigation
```

### 8.2 Review failed TSL events to understand the failure scope
```sql
SELECT
    e.ID,
    e.PositionID,
    e.StopLoss,
    e.SLManualVer,
    e.NextThresHold,
    e.IsBuy,
    e.DateInserted
FROM History.SyncTSLError e WITH (NOLOCK)
ORDER BY e.DateInserted DESC;
```

### 8.3 Check whether failed records were subsequently recovered in History.SyncTSL
```sql
SELECT
    e.ID AS ErrorID,
    e.PositionID,
    CASE WHEN s.ID IS NOT NULL THEN 'Recovered' ELSE 'Still missing' END AS RecoveryStatus
FROM History.SyncTSLError e WITH (NOLOCK)
LEFT JOIN History.SyncTSL s WITH (NOLOCK)
    ON e.ID = s.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.DelRecsFromTradeSyncTSL111) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SyncTSLError | Type: Table | Source: etoro/etoro/History/Tables/History.SyncTSLError.sql*
