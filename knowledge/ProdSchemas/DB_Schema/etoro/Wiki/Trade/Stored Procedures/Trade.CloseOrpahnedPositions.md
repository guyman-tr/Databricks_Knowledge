# Trade.CloseOrpahnedPositions

> Queues orphaned copy-trade positions for automated closure by inserting their details into the Trade.Syn_TradeOrphanedPositionsCloseByJob queue table with ExecuteStatus=0 (pending).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @orpanedPositionsToCloseDetails (TVP of orphaned positions) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseOrpahnedPositions (note: "Orpahned" is a typo for "Orphaned") queues orphaned positions for asynchronous closure. In the eToro CopyTrader system, positions opened as copies of a leader's trades become orphaned when the parent position is closed or the copy relationship is severed, but the child position was not properly closed. This procedure receives a batch of such positions via a Table-Valued Parameter and inserts them into a queue table for later processing by Trade.CloseOrphanedMirrorPositionsAutomaticProcess.

The procedure uses Trade.Syn_TradeOrphanedPositionsCloseByJob (a synonym pointing to a job queue table) as the staging area. Each row includes a pre-built close command (Cmd) that will be executed dynamically by the processing procedure.

---

## 2. Business Logic

### 2.1 Queue Insertion

**What**: Bulk-inserts orphaned position details into the close-by-job queue.

**Columns/Parameters Involved**: `PositionID`, `ParentPositionID`, `Cmd`, `EntryDate`, `ExecuteStatus`

**Rules**:
- EntryDate set to GETUTCDATE() (current server time)
- ExecuteStatus set to 0 (pending execution)
- The Cmd column contains a pre-built SQL command string for closing the position
- No validation is performed - the caller is responsible for identifying true orphans

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @orpanedPositionsToCloseDetails | Trade.OrpanedPositionDetailsType (TVP, READONLY) | NO | - | CODE-BACKED | Table-Valued Parameter containing orphaned position details: PositionID, ParentPositionID, and Cmd (the close command to execute). Passed from the orphan detection logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @orpanedPositionsToCloseDetails | Trade.Syn_TradeOrphanedPositionsCloseByJob | INSERT | Inserts pending close commands into the job queue (synonym) |
| - | Trade.OrpanedPositionDetailsType | Type | User-Defined Table Type used for the TVP parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Orphan detection service (external) | - | EXEC | Called by the application when orphaned positions are detected |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseOrpahnedPositions (procedure)
+-- Trade.Syn_TradeOrphanedPositionsCloseByJob (synonym)
+-- Trade.OrpanedPositionDetailsType (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Syn_TradeOrphanedPositionsCloseByJob | Synonym | INSERT - job queue for orphaned position closures |
| Trade.OrpanedPositionDetailsType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application orphan detection | External | EXEC - queues orphaned positions |
| Trade.CloseOrphanedMirrorPositionsAutomaticProcess | Procedure | Processes the queued commands (downstream) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Safety | Table-Valued Parameter cannot be modified within the procedure |
| No TRY/CATCH | Error handling | Simple INSERT - failures propagate to caller |

---

## 8. Sample Queries

### 8.1 Check pending orphaned position close commands

```sql
SELECT PositionID, ParentPositionID, EntryDate, ExecuteStatus, Cmd
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
WHERE  ExecuteStatus = 0
ORDER BY EntryDate;
```

### 8.2 View recent orphaned position processing results

```sql
SELECT ExecuteStatus, COUNT(*) AS Cnt, MAX(ExecuteDate) AS LastProcessed
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
GROUP BY ExecuteStatus;
```

### 8.3 Check failed orphaned close attempts

```sql
SELECT PositionID, ParentPositionID, Cmd, EntryDate, ExecuteDate
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
WHERE  ExecuteStatus IN (-1, -2)
ORDER BY ExecuteDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseOrpahnedPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseOrpahnedPositions.sql*
