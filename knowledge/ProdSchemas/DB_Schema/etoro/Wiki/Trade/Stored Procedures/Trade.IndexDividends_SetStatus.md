# Trade.IndexDividends_SetStatus

> Batch-updates Status and snapshot timestamps on Trade.IndexDividends for a set of DividendIDs supplied as a table-valued parameter. Used by the dividend processing application to advance dividend records through the processing lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @Status, snapshot timestamps, @dividendIdsTbl (Trade.IdIntList TVP); Updates: Trade.IndexDividends |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IndexDividends_SetStatus advances dividend records through their processing lifecycle by updating the Status and three snapshot timestamps on a batch of dividend IDs. The dividend processing application calls this at each processing stage to record when snapshots were taken.

**Status values** (from Trade.IndexDividends lifecycle):
- 0 = Pending (initial state)
- 1 = In Progress (payment date passed, snapshots being taken)
- 2 = Completed (dividend paid)
- 4 = Correction Pending

The three snapshot timestamp columns track the execution timeline:
- `PositionsSnapshotStarted`: When the position snapshot job began
- `PositionsSnapshotMarketClose`: Market close time used as the snapshot reference
- `PositionsSnapshotCompleted`: When the position snapshot was finished

---

## 2. Business Logic

### 2.1 Batch Status Update

**What**: Updates Status and snapshot timestamps for all DividendIDs in the input batch.

**Rules**:
- `UPDATE Trade.IndexDividends SET Status=@Status, PositionsSnapshotStarted=@PositionsSnapshotStarted, PositionsSnapshotCompleted=@PositionsSnapshotCompleted, PositionsSnapshotMarketClose=@PositionsSnapshotMarketClose FROM Trade.IndexDividends td INNER JOIN @dividendIdsTbl d ON td.DividendID = d.Id`
- Single UPDATE for all matching IDs. No WHERE on Status - can transition to any value.
- No error handling, no transaction, no return code (implicit success).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Status | INT | NO | - | CODE-BACKED | New status to set. 0=Pending, 1=InProgress, 2=Completed, 4=Correction Pending. See Trade.IndexDividends for full lifecycle. |
| 2 | @PositionsSnapshotMarketClose | DATETIME | NO | - | CODE-BACKED | Market close time used as the reference point for the position snapshot. Stored in Trade.IndexDividends.PositionsSnapshotMarketClose. |
| 3 | @PositionsSnapshotCompleted | DATETIME | NO | - | CODE-BACKED | When the position snapshot job finished. Stored in Trade.IndexDividends.PositionsSnapshotCompleted. |
| 4 | @PositionsSnapshotStarted | DATETIME | NO | - | CODE-BACKED | When the position snapshot job started. Stored in Trade.IndexDividends.PositionsSnapshotStarted. |
| 5 | @dividendIdsTbl | Trade.IdIntList (TVP) | NO | READONLY | CODE-BACKED | Batch of DividendIDs to update. Trade.IdIntList is a table type with column Id (INT). Joined to Trade.IndexDividends ON DividendID=Id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @dividendIdsTbl, @Status | Trade.IndexDividends | UPDATE | Advances lifecycle status and stamps snapshot timestamps |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp | GRANT EXECUTE | Application | Dividend processing application calls to advance lifecycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IndexDividends_SetStatus (procedure)
+-- Trade.IdIntList (user-defined table type) [TVP parameter]
+-- Trade.IndexDividends (table) [UPDATE Status + snapshot timestamps]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IdIntList | User-defined table type | TVP parameter type definition |
| Trade.IndexDividends | Table | UPDATE Status and snapshot timestamps by DividendID batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | Application | Calls at each processing stage to advance dividend status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No error handling. No validation that DividendIDs exist or that the Status transition is valid. The system versioning trigger on Trade.IndexDividends (TRG_T_IndexDividends) will capture all updates to History.IndexDividends.

---

## 8. Sample Queries

### 8.1 Mark dividends as completed

```sql
DECLARE @ids Trade.IdIntList;
INSERT INTO @ids VALUES (1001), (1002), (1003);

EXEC Trade.IndexDividends_SetStatus
    @Status = 2,
    @PositionsSnapshotMarketClose = '2026-03-17 16:30:00',
    @PositionsSnapshotStarted = '2026-03-17 16:35:00',
    @PositionsSnapshotCompleted = '2026-03-17 16:40:00',
    @dividendIdsTbl = @ids;
```

### 8.2 Check updated dividends

```sql
SELECT DividendID, Status, PositionsSnapshotStarted, PositionsSnapshotCompleted,
       PositionsSnapshotMarketClose, InstrumentID, ExDate, PaymentDate
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE DividendID IN (1001, 1002, 1003);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: callers found, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.IndexDividends_SetStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IndexDividends_SetStatus.sql*
