# Trade.PositionEditStopLoss_Validation

> Validates that a position's current amount in the database matches the caller's expected amount before allowing a stop loss edit, using an exclusive row lock to prevent concurrent modification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (partition key: @PositionID%50) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditStopLoss_Validation is called by Trade.PositionEditStopLoss immediately before modifying the stop loss level. Its sole purpose is an optimistic-concurrency check: the caller passes in the position amount it believes is current (@CurrentAmount), and this SP reads the live amount from Trade.PositionTbl under an exclusive row lock (XLOCK + ROWLOCK) to verify they match. If they do not match, error 60126 is raised, aborting the SL edit.

This guard prevents a race condition where a partial close occurs between the time the SL edit was initiated by the client and the time it reaches the database. A partial close changes the position amount; if the SL edit proceeded without this check, it could set a stop loss based on a stale amount that no longer reflects the position's actual size.

The XLOCK ensures that no other process can modify the PositionTbl row between the read and the subsequent UPDATE in Trade.PositionEditStopLoss.

---

## 2. Business Logic

### 2.1 Amount Consistency Check (Exclusive Lock)

**What**: Reads the current Amount from Trade.PositionTbl under XLOCK+ROWLOCK and compares it to the caller's expected amount.

**Columns/Parameters Involved**: Trade.PositionTbl.Amount, @CurrentAmount, @PositionID

**Rules**:
- SELECT Amount WITH(ROWLOCK,XLOCK) WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50
- Partition elimination: PartitionCol=@PositionID%50
- Comparison: IF @CurrentDBAmount <> ISNULL(@CurrentAmount, 0) -> RAISERROR(60126, 16, 1)
- ISNULL(@CurrentAmount, 0): if caller passes NULL as @CurrentAmount, it is treated as 0; a non-zero @CurrentDBAmount will then raise the error
- Error 60126: "Position amount mismatch" (optimistic concurrency failure for SL edit)
- If amounts match: returns without error, lock held until caller's transaction commits/rolls back

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to validate. Partition key: @PositionID%50. Used with XLOCK+ROWLOCK to acquire exclusive row lock. |
| 2 | @CurrentAmount | MONEY | NO | - | CODE-BACKED | The position amount expected by the caller (read from Trade.Position before initiating the edit). Compared to live Amount in Trade.PositionTbl. Mismatch raises error 60126. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT Amount (XLOCK,ROWLOCK) | Trade.PositionTbl | DML read (locking) | Reads and locks the position's Amount for concurrency validation |

### 5.2 Referenced By (other objects point to this)

| Caller | How Used |
|--------|----------|
| Trade.PositionEditStopLoss | Called before executing SL update to verify amount hasn't changed since client read |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditStopLoss_Validation (procedure)
+-- Trade.PositionTbl (table) - XLOCK+ROWLOCK read of Amount
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT Amount WITH(ROWLOCK,XLOCK) WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionEditStopLoss | Stored Procedure | Calls this SP as pre-validation before executing the SL UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Error 60126 = amount mismatch (position amount changed since client snapshot, likely due to partial close)
- XLOCK+ROWLOCK: exclusive lock prevents concurrent PositionTbl writes between validation and the subsequent SL UPDATE in Trade.PositionEditStopLoss
- ISNULL(@CurrentAmount, 0) means a NULL input is compared as 0 - callers should pass the actual amount

---

## 8. Sample Queries

### 8.1 Called internally by Trade.PositionEditStopLoss

```sql
-- SP is designed to be called as part of Trade.PositionEditStopLoss, not standalone.
-- Example of what the caller passes:
EXEC Trade.PositionEditStopLoss_Validation
    @PositionID    = 123456789,
    @CurrentAmount = 100.00; -- amount read from Trade.Position before initiating the edit
-- Returns without error if amount matches; raises 60126 if mismatch detected
```

### 8.2 Check for recent 60126 errors

```sql
SELECT PositionID, CID, FailReason, RequestOccurred
FROM History.PositionFailWrite WITH (NOLOCK)
WHERE FailReason LIKE '%60126%'
ORDER BY RequestOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (Trade.PositionEditStopLoss) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditStopLoss_Validation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditStopLoss_Validation.sql*
