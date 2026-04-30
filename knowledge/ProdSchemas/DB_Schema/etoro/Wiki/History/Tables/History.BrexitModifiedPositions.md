# History.BrexitModifiedPositions

> Processing queue for positions whose take-profit rate was bulk-modified by instrument; rows are produced by Trade.UpdatePositionsTakeProfitByInstrumentID and consumed (dequeued) by History.BrexitGetModifiedRecords.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BrexitModifiedPositions is a processing queue that records positions whose take-profit (TP) rates were bulk-modified by an instrument-level update operation. Despite its Brexit-era name (it was likely created during Brexit-driven regulatory TP adjustments), it is used for general instrument-level take-profit batch updates, most recently for the Free Stocks feature (FB 53719, 2019).

The table enables an auditable, decoupled workflow: when Trade.UpdatePositionsTakeProfitByInstrumentID modifies take-profits across multiple positions for an instrument, it writes each modified position into this queue. A downstream consumer (History.BrexitGetModifiedRecords) dequeues records in order, returning them to the caller and atomically deleting them - a classic SQL "queue pop" pattern.

Data flows in from Trade.UpdatePositionsTakeProfitByInstrumentID (called during instrument-level TP recalculation events such as corporate actions, Free Stocks discounting, or regulatory adjustments) and is consumed by History.BrexitGetModifiedRecords. The table is normally empty between processing runs; rows persist only while waiting to be dequeued.

---

## 2. Business Logic

### 2.1 Queue Producer-Consumer Pattern

**What**: The table acts as a transient processing queue, not a permanent history store.

**Columns/Parameters Involved**: `ID`, all columns

**Rules**:
- PRODUCER: Trade.UpdatePositionsTakeProfitByInstrumentID inserts one row per position modified during an instrument TP update run
- CONSUMER: History.BrexitGetModifiedRecords dequeues TOP N records using a CTE DELETE...OUTPUT pattern (atomic dequeue - read and delete in one operation)
- Rows are ordered by ID (FIFO) for dequeue
- The table is expected to be empty between processing runs; 0 rows in production confirms the queue is fully consumed
- Each row captures the new TP rate applied, the direction (buy/sell), and whether a discount was applied (IsDiscounted for Free Stocks)

**Diagram**:
```
Trade.UpdatePositionsTakeProfitByInstrumentID(@InstrumentID, @RateDiffPercentage)
  For each position needing TP update:
    -> EXEC Trade.PositionEditTakeProfit (update TP in real-time)
    -> INSERT History.SystemUpdatePositionTakeProfit (permanent audit log)
    -> INSERT History.BrexitModifiedPositions (queue entry for downstream)

History.BrexitGetModifiedRecords(@NumOfRecords)
  -> WITH CTE AS (SELECT TOP N ... ORDER BY ID)
     DELETE CTE OUTPUT DELETED.*   (atomic dequeue - returns and removes)
```

### 2.2 IsDiscounted - Free Stocks TP Adjustment

**What**: Flags positions that received a discounted take-profit rate under the Free Stocks feature.

**Columns/Parameters Involved**: `IsDiscounted`, `NewTakeProfit`

**Rules**:
- IsDiscounted=1: position was subject to the Free Stocks discount logic when TP was recalculated
- IsDiscounted=0: standard TP recalculation (default)
- The Free Stocks feature (FB 53719, 2019) introduced TP adjustments for positions in instruments where customers own actual shares

---

## 3. Data Overview

The table is empty (0 rows). The queue is fully consumed - no positions are pending downstream processing.

For context, the types of records this table would contain:

| ID | InstrumentID | TreeID | CID | NewTakeProfit | IsBuy | IsDiscounted | Meaning |
|----|---|---|---|---|---|---|---|
| (example) | 3601 | 12345678 | 98765 | 85.50 | 1 | 0 | Long position on instrument 3601 had TP updated to 85.50 in a bulk adjustment run |
| (example) | 3601 | 23456789 | 87654 | 85.50 | 1 | 1 | Same instrument, Free Stocks position - TP updated with discount logic applied |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Determines dequeue order (FIFO via ORDER BY ID in History.BrexitGetModifiedRecords). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument whose take-profit rates were bulk-updated in this run. Sourced from @InstrumentID parameter in Trade.UpdatePositionsTakeProfitByInstrumentID. Implicit FK to Trade.Instrument. |
| 3 | TreeID | int | NO | - | CODE-BACKED | The position tree (copy-trade tree or independent position) whose take-profit was modified. In copy-trade, one TreeID covers multiple copied positions. Implicit FK to Trade.PositionTreeInfo. Passed from cursor over Trade.OldAndNewTakeProfitPerInstrumentID. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID of the position owner. Sourced directly from the position record during the update cursor. Implicit FK to Customer.Customer. |
| 5 | NewTakeProfit | dbo.dtPrice | NO | - | CODE-BACKED | The new take-profit rate applied to the position, after the bulk recalculation. Uses dbo.dtPrice user-defined type (decimal precision for price values). Corresponds to @MaxTakeProfitRate computed by Trade.OldAndNewTakeProfitPerInstrumentID. |
| 6 | IsBuy | int | NO | - | CODE-BACKED | Position direction: 1 = Buy (long position), 0 = Sell (short position). Stored as INT rather than BIT. Sourced from Trade.Position via the cursor. |
| 7 | IsDiscounted | bit | NO | 0 | CODE-BACKED | Free Stocks discount flag: 1 = this position was subject to the Free Stocks discount logic when its take-profit was recalculated (FB 53719). 0 = standard TP recalculation (default). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument being processed in the bulk TP update |
| TreeID | Trade.PositionTreeInfo | Implicit | The position tree whose TP was modified |
| CID | Customer.Customer | Implicit | Owner of the modified position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | InstrumentID, TreeID, CID | Writer | Inserts queue entries during bulk TP recalculation runs |
| History.BrexitGetModifiedRecords | ID | Reader/Deleter | Atomic dequeue - reads TOP N rows and deletes them in one operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BrexitModifiedPositions (table)
```

Tables are always leaf nodes - no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | Stored Procedure | Writer - inserts one row per modified position during TP bulk update |
| History.BrexitGetModifiedRecords | Stored Procedure | Dequeuer - reads and deletes TOP N rows (OUTPUT DELETED.*) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBrexitModifiedPositions | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBrexitModifiedPositions | PRIMARY KEY | ID - surrogate key, determines FIFO dequeue order |
| DF_BrexitModifiedPositions_IsDiscounted | DEFAULT | IsDiscounted = 0 (standard TP recalculation by default) |

---

## 8. Sample Queries

### 8.1 Peek at queue contents without dequeuing
```sql
SELECT ID, InstrumentID, TreeID, CID, NewTakeProfit, IsBuy, IsDiscounted
FROM [History].[BrexitModifiedPositions] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count pending queue entries by instrument
```sql
SELECT InstrumentID, COUNT(*) AS PendingCount
FROM [History].[BrexitModifiedPositions] WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY PendingCount DESC
```

### 8.3 Dequeue next N records (as done by History.BrexitGetModifiedRecords)
```sql
-- This is the pattern used by History.BrexitGetModifiedRecords
-- WARNING: destructive - deletes rows. Use only when processing is intended.
-- DECLARE @NumOfRecords INT = 10
-- WITH MyCTE AS (
--   SELECT TOP (@NumOfRecords) * FROM History.BrexitModifiedPositions ORDER BY ID
-- )
-- DELETE MyCTE OUTPUT DELETED.*

-- Safe read-only equivalent:
SELECT TOP 10 * FROM [History].[BrexitModifiedPositions] WITH (NOLOCK) ORDER BY ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BrexitModifiedPositions | Type: Table | Source: etoro/etoro/History/Tables/History.BrexitModifiedPositions.sql*
