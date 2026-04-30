# History.PositionSplitError

> Error log capturing failed stock split adjustments for individual positions, recording which (position, split) pairs could not be processed and why.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (PositionID, SplitID, InsertDate) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 2 (1 clustered + 1 nonclustered) |

---

## 1. Business Meaning

`History.PositionSplitError` is the companion error log to `History.PositionSplit`. When a stock split adjustment job processes closed positions in `History.SplitClosePositions` or open positions in `Trade.SplitOpenPositions`, individual position adjustments can occasionally fail. Rather than aborting the entire split run, errors for specific positions are captured here so the rest of the positions can continue processing.

The table records the PositionID and SplitID of the failed adjustment, the timestamp it was logged, and the full error message. Operations teams can query this table after a split run to identify any positions that need manual remediation. A position in this table represents a gap - it exists in `History.Position` but was NOT adjusted for the corresponding split, meaning its rates and units may be incorrect post-split.

The table is currently empty (0 rows), indicating that all historical split operations have completed without errors in the current environment. In production, failures are rare but the table exists to handle exceptions gracefully.

---

## 2. Business Logic

### 2.1 Companion to PositionSplit - Exception Tracking

**What**: Captures which (position, split) pairs failed adjustment so they can be investigated and manually corrected.

**Columns/Parameters Involved**: `PositionID`, `SplitID`, `InsertDate`, `ErrorMessage`

**Rules**:
- A row in this table means the corresponding position was NOT successfully adjusted for the split
- A row in History.PositionSplit for the same (PositionID, SplitID) means the position WAS successfully adjusted
- These two tables should not have overlapping (PositionID, SplitID) pairs in normal operation
- Positions appearing here require manual review to determine if the split adjustment needs to be applied retroactively
- The clustered index (PositionID, SplitID, InsertDate) allows multiple error attempts per (position, split) to be logged with different timestamps

**Diagram**:
```
Split adjustment job
    |
    +-> For each position batch:
        |
        +-> SUCCESS: OUTPUT into History.PositionSplit (idempotency marker)
        |
        +-> ERROR:   INSERT into History.PositionSplitError (this table)
                     with PositionID, SplitID, GETDATE(), ERROR_MESSAGE()
```

---

## 3. Data Overview

Table is empty in current environment (0 rows). This indicates all historical split operations completed without position-level failures.

| PositionID | SplitID | InsertDate | ErrorMessage | Meaning |
|---|---|---|---|---|
| (empty table) | - | - | - | No split adjustment failures have been recorded |

*If rows existed, they would indicate positions requiring manual review and remediation.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | ID of the closed or open trading position whose split adjustment failed. Part of the clustered composite key. References History.Position (closed) or Trade.PositionTbl (open). |
| 2 | SplitID | int | NO | - | VERIFIED | ID of the stock split event that failed to process for this position. References History.SplitRatio.ID. Indexed independently (IX on SplitID) for finding all errors in a given split run. |
| 3 | InsertDate | datetime | NO | - | NAME-INFERRED | Timestamp when the error was logged. Not UTC-defaulted in DDL (no DEFAULT constraint), so caller sets this value explicitly. Part of the clustered key, allowing multiple error entries per (PositionID, SplitID) if a position fails on multiple retry attempts. |
| 4 | ErrorMessage | varchar(8000) | YES | - | NAME-INFERRED | Full error message text captured when the split adjustment failed. Likely populated from ERROR_MESSAGE() or a custom error description in the calling procedure. NULL if no message was provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position / Trade.PositionTbl | Implicit | The position whose split adjustment failed |
| SplitID | History.SplitRatio | Implicit | The stock split event definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AlertSplitPositionEndedWithError | SELECT | READER | Checks for errors after a split run and raises alerts |
| History.SplitClosePositions (likely) | INSERT | WRITER | Logs errors when individual position adjustments fail |
| Trade.SplitOpenPositions (likely) | INSERT | WRITER | Logs errors for failed open position adjustments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionSplitError (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AlertSplitPositionEndedWithError | Stored Procedure | READER - checks for errors after split job completion |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | PositionID ASC, SplitID ASC, InsertDate ASC | - | - | Active |
| IX | NONCLUSTERED | SplitID ASC | - | - | Active |

*Both indexes: DATA_COMPRESSION=PAGE, on [HISTORY] filegroup.*

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All errors for a specific split run

```sql
SELECT PositionID, InsertDate, ErrorMessage
FROM History.PositionSplitError WITH (NOLOCK)
WHERE SplitID = @SplitID
ORDER BY InsertDate ASC
```

### 8.2 All split errors for a specific position

```sql
SELECT SplitID, InsertDate, ErrorMessage
FROM History.PositionSplitError WITH (NOLOCK)
WHERE PositionID = @PositionID
ORDER BY InsertDate ASC
```

### 8.3 Error count per split - identify problematic split runs

```sql
SELECT
    SplitID,
    COUNT(*) AS ErrorCount,
    MIN(InsertDate) AS FirstError,
    MAX(InsertDate) AS LastError
FROM History.PositionSplitError WITH (NOLOCK)
GROUP BY SplitID
ORDER BY ErrorCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.4/10 (Elements: 7.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.SplitClosePositions) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionSplitError | Type: Table | Source: etoro/etoro/History/Tables/History.PositionSplitError.sql*
