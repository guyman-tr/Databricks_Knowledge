# Trade.BSLSetNewExecutionID

> Generates the next BSL (Balance Stop Loss) execution run ID from a database sequence, used to correlate all messages and snapshots from a single BSL check cycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionID (INT OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates a unique execution ID for each BSL (Balance Stop Loss) check cycle. The BSL system periodically evaluates all customers' equity against thresholds. Each evaluation run needs a unique identifier to correlate the messages in `Trade.ManageBSL`, currency price snapshots in `RW_BSLCurrencyPriceSnapShots`, and position snapshots in `RW_BSLPositionsInfo`.

Without a unique execution ID, it would be impossible to distinguish which messages belong to which BSL run, making debugging and auditing extremely difficult. The sequence guarantees uniqueness and monotonicity across concurrent BSL invocations.

The procedure simply fetches the next value from `Trade.seq_BSLExecutionID` sequence and returns it via the OUTPUT parameter.

---

## 2. Business Logic

### 2.1 Sequence-Based ID Generation

**What**: Uses NEXT VALUE FOR to generate a gap-free, monotonically increasing execution ID.

**Rules**:
- Single statement: `SET @ExecutionID = NEXT VALUE FOR Trade.seq_BSLExecutionID`
- Sequences are transaction-independent - the value is never rolled back, ensuring uniqueness
- The caller uses this ID when inserting BSL messages and snapshots

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | INT OUTPUT | NO | - | CODE-BACKED | Returns the next BSL execution run ID from Trade.seq_BSLExecutionID. Used to correlate all ManageBSL messages and BSL snapshots from a single check cycle. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NEXT VALUE FOR | Trade.seq_BSLExecutionID | Sequence | Generates the next unique execution ID |

### 5.2 Referenced By (other objects point to this)

Called by BSL check orchestration before inserting messages into ManageBSL.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.BSLSetNewExecutionID (procedure)
+-- Trade.seq_BSLExecutionID (sequence)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.seq_BSLExecutionID | Sequence | NEXT VALUE FOR - generates unique execution ID |

### 6.2 Objects That Depend On This

No SQL-level dependents found. Called by BSL check services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Get a new BSL execution ID

```sql
DECLARE @ExecID INT;
EXEC Trade.BSLSetNewExecutionID @ExecutionID = @ExecID OUTPUT;
SELECT @ExecID AS NewExecutionID;
```

### 8.2 Check current sequence value

```sql
SELECT current_value FROM sys.sequences WHERE name = 'seq_BSLExecutionID';
```

### 8.3 Find recent BSL runs by ExecutionID

```sql
SELECT  ExecutionID, COUNT(*) AS MessageCount, MIN(TimeMessageInsertedToQueue) AS RunStart
FROM    Trade.ManageBSL WITH (NOLOCK)
WHERE   ExecutionID IS NOT NULL
GROUP BY ExecutionID
ORDER BY ExecutionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BSLSetNewExecutionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.BSLSetNewExecutionID.sql*
