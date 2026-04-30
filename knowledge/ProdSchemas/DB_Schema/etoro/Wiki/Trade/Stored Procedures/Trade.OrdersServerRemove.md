# Trade.OrdersServerRemove

> Server-side removal of a failed or rejected pending order - archives it to History.OrdersFail with a reason, deletes it from Trade.Orders, and queues the async change log record.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (order to remove) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When the trading server determines a pending open order cannot be fulfilled (e.g., validation failure, price slip beyond tolerance, insufficient margin), it calls this procedure to remove the order from the queue and archive it to the failures table. This is the complement to `Trade.OrdersClientRemove` (user-requested cancel) and `Trade.OrdersClose` (triggered/executed close).

The key distinction is the destination archive: failed server-side removals go to `History.OrdersFail` (the failure archive) with the @FailReason, while client-initiated cancels go to `History.Orders` (the general archive). This separation allows for separate analysis of failed vs. completed orders.

Per the comment in the code: if the order is not found, the procedure silently returns without error ("requested by Dudu") - the absence of an order is treated as an already-handled state, not an error.

Data flow: Validates ownership, archives to History.OrdersFail, deletes from Trade.Orders, queues async change log.

---

## 2. Business Logic

### 2.1 Silent Not-Found Handling

**What**: Missing orders are silently ignored rather than raising an error.

**Columns/Parameters Involved**: `Trade.Orders.OrderID`

**Rules**:
- IF NOT EXISTS: RETURN (no error) - by design per code comment "requested by Dudu"
- Prevents errors when the same removal is attempted multiple times (idempotency)
- Different from OrdersClose and OrdersClientRemove which RAISERROR when order not found

### 2.2 CID Ownership Validation

**What**: Validates the order belongs to the specified CID.

**Columns/Parameters Involved**: `@CID`, `Trade.Orders.CID`

**Rules**:
- If order exists but CID doesn't match: RAISERROR(60001), RETURN 60001
- This is an unconditional check (unlike OrdersClientRemove which only checks when @RequestingService is specified)

### 2.3 Archive to OrdersFail (Not Orders)

**What**: Failed server-removes go to the failure archive, not the normal history.

**Columns/Parameters Involved**: `History.OrdersFail.FailReason`, `@FailReason`

**Rules**:
- INSERT INTO History.OrdersFail (not History.Orders)
- FailReason = @FailReason (caller provides the reason string)
- FailOccurred = GETDATE()
- OpenOccurredTime = OccurredTime (from Trade.Orders)
- If INSERT fails: ROLLBACK, RAISERROR(60002), RETURN 60002
- DELETE after successful INSERT (within same transaction)
- COMMIT after DELETE (important: commit is AFTER delete per Danny R change 14/08/2019)

### 2.4 Post-Commit Async Logging

**What**: After commit, queues the async change log record.

**Columns/Parameters Involved**: `Trade.InsertAsyncRecord`, `OperationTypeID=2`

**Rules**:
- Called after COMMIT (outside transaction)
- OperationTypeID = 2 (close/remove)
- ProcedureName = 'Trade.OrdersChangeLogAdd'
- If InsertAsyncRecord fails: RAISERROR(60003) but does NOT rollback (data already committed)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The pending order to remove. If not found: silently returns without error. If CID mismatch: RAISERROR(60001). |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the order owner. Validated against Trade.Orders.CID - mismatches raise error 60001. Used for async record insertion. |
| 3 | @FailReason | VARCHAR(MAX) | YES | NULL | CODE-BACKED | The reason the order is being server-removed (e.g., validation failure message, rejection reason). Stored in History.OrdersFail.FailReason. NULL if no specific reason. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.Orders | READ + DELETE | Source of order data; deleted after archiving to fail table |
| @OrderID | History.OrdersFail | INSERT (WRITE) | Fail archive with @FailReason - distinguishes from normal History.Orders |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues OrdersChangeLogAdd (OperationTypeID=2) after commit |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersServerRemove (procedure)
+-- Trade.Orders (table) [READ + DELETE - order data]
+-- History.OrdersFail (table) [WRITE - fail archive with FailReason]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async change log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Existence check, CID validation, archive source, DELETE target |
| History.OrdersFail | Table | INSERT for failed/rejected order archive with FailReason |
| Trade.InsertAsyncRecord | Stored Procedure | Queues async OrdersChangeLogAdd after COMMIT |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Error 60001 | Business error | CID mismatch - unauthorized removal attempt |
| Error 60002 | Business error | Cannot insert to History.OrdersFail - data integrity issue |
| Error 60003 | Business error | Cannot delete order or insert async record - post-insert failure |
| COMMIT before async | Design | Commit happens AFTER delete but BEFORE async record - order deletion is durable even if async fails |
| Silent not-found | Design decision | Per code comment: by design for idempotency |

---

## 8. Sample Queries

### 8.1 Server-remove a rejected order
```sql
EXEC Trade.OrdersServerRemove
    @OrderID    = 123456789,
    @CID        = 111222,
    @FailReason = 'Price slip exceeded tolerance: requested 1.2500, best available 1.2540';
```

### 8.2 Check the fail archive for a specific order
```sql
SELECT
    hof.OrderID,
    hof.CID,
    hof.FailReason,
    hof.FailOccurred,
    hof.InstrumentID,
    hof.Amount
FROM History.OrdersFail hof WITH (NOLOCK)
WHERE hof.OrderID = 123456789;
```

### 8.3 Find recent server-removed orders for a customer
```sql
SELECT TOP 10
    OrderID,
    CID,
    FailReason,
    FailOccurred,
    InstrumentID,
    Amount
FROM History.OrdersFail WITH (NOLOCK)
WHERE CID = 111222
ORDER BY FailOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (InsertAsyncRecord) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersServerRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersServerRemove.sql*
