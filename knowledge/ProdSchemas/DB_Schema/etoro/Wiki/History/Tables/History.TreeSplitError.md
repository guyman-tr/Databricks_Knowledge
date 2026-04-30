# History.TreeSplitError

> Error log for stock split processing failures - captures copy-trading tree IDs and error details when Trade.SplitOpenPositions fails to apply a stock split to a specific position tree.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (TreeID ASC, SplitID ASC, InsertDate ASC) |
| **Partition** | No - stored on [HISTORY] filegroup with PAGE compression |
| **Indexes** | 2 active (CLUSTERED on TreeID+SplitID+InsertDate, NC on SplitID) |

---

## 1. Business Meaning

History.TreeSplitError is the error log for the stock split processing pipeline. When a publicly traded company undergoes a stock split (e.g., Apple 4-for-1 split), eToro must adjust all open positions in that instrument by the split ratio - modifying prices, amounts, stop-losses, and take-profits. Trade.SplitOpenPositions processes this adjustment copy-trading tree by tree.

If the split adjustment for a specific tree fails, the error is recorded here with the TreeID, the SplitID, the timestamp, and the error message. This allows operations teams to identify which copy-trading trees were not properly split (and therefore have incorrect position sizes/prices), and to re-process or manually correct them.

The table is currently empty in this environment (0 rows), consistent with it being populated only during stock split events - which are relatively infrequent (a few times per year for major instruments).

---

## 2. Business Logic

### 2.1 Tree-Level Split Error Recording

**What**: Trade.SplitOpenPositions processes positions tree-by-tree. If a tree fails, its error is recorded here and processing continues with the next tree (per-tree error isolation).

**Columns/Parameters Involved**: `TreeID`, `SplitID`, `InsertDate`, `ErrorMessage`

**Rules**:
- One row per failed tree per split operation (SplitID + TreeID combination)
- SplitID references History.SplitRatio - the record of the actual split event (price ratio, amount ratio, instrument, date)
- TreeID is the copy-trading root position - all positions under this tree ID inherit the split adjustment
- InsertDate is captured at error time (UTC implied, DATETIME precision)
- ErrorMessage stores up to 8000 characters of SQL error text for diagnosis
- A split retry would insert a new row if it fails again (no unique constraint prevents duplicate TreeID+SplitID)

**Diagram**:
```
Stock split event:
  History.SplitRatio (SplitID=42, InstrumentID=7, AmountRatio=4, PriceRatio=0.25)
        |
        v
  Trade.SplitOpenPositions (@SplitID=42)
        |-- Tree 100001 --> OK (adjusted successfully)
        |-- Tree 100002 --> FAIL --> History.TreeSplitError
        |                           TreeID=100002, SplitID=42
        |                           ErrorMessage="Conversion overflow..."
        |-- Tree 100003 --> OK
        |-- Tree 100004 --> FAIL --> History.TreeSplitError
                                    TreeID=100004, SplitID=42
```

---

## 3. Data Overview

Table is currently empty (0 rows) in this environment. In production, rows appear only when a stock split processing job fails for specific trees. A healthy split operation produces zero rows here.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | BIGINT | NO | - | CODE-BACKED | Copy-trading tree root PositionID that failed to be adjusted during the split. All positions under this TreeID were not split. BIGINT post-Nov 2021 migration. Leading column of clustered index for efficient lookup by tree. |
| 2 | SplitID | INT | NO | - | CODE-BACKED | Identifier of the stock split event (from History.SplitRatio). Identifies which split operation this error occurred in. NC index on SplitID allows querying all errors for a given split event. |
| 3 | InsertDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the error was recorded. Useful for correlating error times with system events or identifying if errors cluster at a specific time during the split job. |
| 4 | ErrorMessage | VARCHAR(8000) | YES | NULL | CODE-BACKED | SQL Server error message text (from ERROR_MESSAGE() or similar). Up to 8000 characters. Provides the technical reason for the split failure (e.g., arithmetic overflow, deadlock, constraint violation). NULL if the error was captured without a message. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SplitID | History.SplitRatio | Implicit FK | References the stock split event definition (instrument, price/amount ratios, dates). |
| TreeID | Trade.PositionTbl | Implicit | References the copy-trading root position whose split adjustment failed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitOpenPositions | TreeID, SplitID | Writer (implicit - error capture) | Writes here when per-tree split adjustment fails. |
| Monitor.MonitorSplit_DataDog | - | Reader | Monitoring procedure that checks this table to detect and alert on split errors. |
| Trade.AlertSplitTreeEndedWithErrorDemo | - | Reader | Alert procedure for split errors in the demo environment. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TreeSplitError (table)
  (leaf - no code-level DDL dependencies)
```

### 6.1 Objects This Depends On

No hard DDL dependencies. No PK, FK constraints, or UDTs in the CREATE TABLE DDL.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitOpenPositions | Stored Procedure | WRITER - captures per-tree split failures |
| Monitor.MonitorSplit_DataDog | Stored Procedure | READER - monitors split error count for DataDog alerting |
| Trade.AlertSplitTreeEndedWithErrorDemo | Stored Procedure | READER - alerts on demo environment split errors |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | TreeID ASC, SplitID ASC, InsertDate ASC | - | - | Active (PAGE compression) |
| IX | NONCLUSTERED | SplitID ASC | - | - | Active (PAGE compression) |

Note: Clustered on (TreeID, SplitID, InsertDate) for lookup by tree; NC on SplitID alone for querying all errors within a split event.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for errors in a specific split operation
```sql
SELECT
    e.TreeID,
    e.SplitID,
    e.InsertDate,
    e.ErrorMessage
FROM History.TreeSplitError e WITH (NOLOCK)
WHERE e.SplitID = 42
ORDER BY e.InsertDate;
```

### 8.2 Find all trees that failed for any split (production health check)
```sql
SELECT
    e.SplitID,
    COUNT(*) AS FailedTrees,
    MIN(e.InsertDate) AS FirstError,
    MAX(e.InsertDate) AS LastError
FROM History.TreeSplitError e WITH (NOLOCK)
GROUP BY e.SplitID
ORDER BY e.SplitID DESC;
```

### 8.3 Get error details for a specific tree across all splits
```sql
SELECT
    e.TreeID,
    e.SplitID,
    e.InsertDate,
    e.ErrorMessage
FROM History.TreeSplitError e WITH (NOLOCK)
WHERE e.TreeID = 100002
ORDER BY e.InsertDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 found (Trade.SplitOpenPositions, Monitor.MonitorSplit_DataDog, Trade.AlertSplitTreeEndedWithErrorDemo) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TreeSplitError | Type: Table | Source: etoro/etoro/History/Tables/History.TreeSplitError.sql*
