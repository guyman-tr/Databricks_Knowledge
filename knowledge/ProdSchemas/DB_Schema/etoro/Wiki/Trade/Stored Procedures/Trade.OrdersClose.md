# Trade.OrdersClose

> System-side closure of a pending open order - archives it to History.Orders with a specified action type, removes it from Trade.Orders, and queues the async change log record.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (order to close) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.OrdersClose` is the system/server-side path for closing a pending open order - called by the execution engine when a pending order is triggered (via `Trade.OrderForOpenCreateWrapper`) or when the server determines the order needs to be closed (e.g., margin call, admin action). Unlike `Trade.OrdersClientRemove` (customer-initiated cancel), this procedure is invoked by internal system components.

The @ActionTypeID parameter records WHY the order was closed - distinguishing between triggering (order executed successfully, pending now superseded), admin closure, margin call, etc. The @ErrOut OUTPUT parameter enables the caller to capture the full error context without losing the exception stack.

Data flow: The caller provides @OrderID and @ActionTypeID. Existence is verified first. Within a transaction, the order is copied to History.Orders (with the specified ActionTypeID) and deleted from Trade.Orders. CopyTrader orders in Demo DB get DetachFromParentOrder. An async change log record is queued. On failure, the order goes to History.OrdersFail1001 (note: different table from OrdersClientRemove).

---

## 2. Business Logic

### 2.1 Archive-and-Delete with Action Type

**What**: Closes the pending order with a specific business reason, archiving it to history.

**Columns/Parameters Involved**: `@ActionTypeID`, `History.Orders.ActionTypeID`, `History.Orders.CloseOcurred`

**Rules**:
- Pre-check: IF NOT EXISTS in Trade.Orders -> RAISERROR(60031) and RETURN 60031 (order not found - checked outside transaction for efficiency)
- Archive: INSERT INTO History.Orders from Trade.Orders SELECT, CloseOcurred = GETDATE(), ActionTypeID = @ActionTypeID
- Delete: DELETE FROM Trade.Orders WHERE OrderID = @OrderID
- All within BEGIN TRANSACTION / COMMIT
- Returns 0 on success

### 2.2 Demo DB CopyTrader Detachment

**What**: For Demo DB copy+ orders, removes the parent-child link.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID=22`, `@ParentOrderID`, `Trade.DetachFromParentOrder`

**Rules**:
- Same logic as OrdersClientRemove but condition check is inside the transaction
- Only for Demo DB (FeatureID=22 Value=0) AND ParentOrderID > 0
- Calls Trade.DetachFromParentOrder @OrderID, @ParentOrderID, 0

### 2.3 Error Output Parameter

**What**: Captures detailed error context for the caller when failure occurs.

**Columns/Parameters Involved**: `@ErrOut OUTPUT`, `@ErrNum`

**Rules**:
- @ErrOut is populated in CATCH with: SP name, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE
- Format: "SP - Trade.OrdersClose | ERROR_NUMBER: {N} ERROR_LINE: {N} ERROR_MESSAGE: {msg}"
- @CID: if NULL passed in, resolved from Trade.Orders before fail logging
- Fail records go to History.OrdersFail1001 (different table than History.OrdersFail used by OrdersClientRemove)
- After fail logging: THROW re-raises the original exception

### 2.4 PREEXE Service Identifier

**What**: Marks all async change log records from this procedure with a 'PREEXE' service tag.

**Columns/Parameters Involved**: `@RequestingService = 'PREEXE'`

**Rules**:
- @RequestingService is hardcoded to 'PREEXE' (Pre-Execution Service)
- Included in the async OrdersChangeLogAdd payload
- Identifies that order closure was initiated by the pre-execution service (not a client or other system)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The pending order to close. Must exist in Trade.Orders or RAISERROR(60031) fires. |
| 2 | @ActionTypeID | INT | NO | - | CODE-BACKED | The reason for closure: stored as ActionTypeID in History.Orders. Distinguishes triggering (pending order fired), admin close, margin call, etc. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID. Optional - if NULL, resolved from Trade.Orders in the CATCH block for fail logging. Used for InsertAsyncRecord and fail logging. |
| 4 | @ErrOut | NVARCHAR(4000) | YES | '' OUTPUT | CODE-BACKED | OUTPUT: full error context string on failure, including SP name, error number, line, and message. Returns '' if no error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.Orders | READ + DELETE | Source of order data; deleted after archiving |
| @OrderID | History.Orders | INSERT (WRITE) | Archive with @ActionTypeID and CloseOcurred=GETDATE() |
| @CID | Customer.Login | READ | Gets ClientVersion for fail record (on error path, if @CID initially NULL) |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues OrdersChangeLogAdd with OperationTypeID=2, RequestingService='PREEXE' |
| Conditional | Trade.DetachFromParentOrder | EXEC (CALL) | Demo DB: removes CopyTrader parent link |
| On error | History.OrdersFail1001 | INSERT (WRITE) | Fail record archive (note: different table from OrdersClientRemove's OrdersFail) |
| Internal | Maintenance.Feature | READ | Demo DB check (FeatureID=22) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreateWrapper | @TriggeringOrderID | EXEC (CALL) | Calls this to close the triggering pending order when a new position is placed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersClose (procedure)
+-- Trade.Orders (table) [READ + DELETE - order data]
+-- History.Orders (table) [WRITE - archive]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async change log]
+-- Trade.DetachFromParentOrder (procedure) [EXEC - copy+ detach, Demo DB only]
+-- History.OrdersFail1001 (table) [WRITE - fail record, error path]
+-- Customer.Login (table) [READ - ClientVersion, error path]
+-- Maintenance.Feature (table) [READ - Demo DB check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | SELECT for existence check and archive source; DELETE to remove |
| History.Orders | Table | INSERT with @ActionTypeID to archive the closed order |
| Trade.InsertAsyncRecord | Stored Procedure | Queues OrdersChangeLogAdd (OperationTypeID=2, PREEXE) |
| Trade.DetachFromParentOrder | Stored Procedure | Demo DB only: removes CopyTrader parent-child order link |
| History.OrdersFail1001 | Table | Fail archive (distinct from History.OrdersFail) |
| Customer.Login | Table | ClientVersion for failure context |
| Maintenance.Feature | Table | Demo DB detection (FeatureID=22) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreateWrapper | Stored Procedure | Calls Trade.OrdersClose to close the triggering pending order atomically with the new position creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Transaction safety | Automatic rollback on any error |
| Error 60031 | Pre-check | Order not found in Trade.Orders - checked BEFORE BEGIN TRANSACTION |
| History.OrdersFail1001 | Note | Different from History.OrdersFail - specific to server-close failures (vs client-remove failures in OrdersFail) |
| @CID optional | Flexibility | @CID=NULL supported - procedure resolves it from Trade.Orders in CATCH if needed |

---

## 8. Sample Queries

### 8.1 Close a pending order with a specific action type
```sql
DECLARE @ErrorOut NVARCHAR(4000) = '';

EXEC Trade.OrdersClose
    @OrderID      = 123456789,
    @ActionTypeID = 7,           -- e.g., 7=triggered/executed pending order
    @CID          = 111222,
    @ErrOut       = @ErrorOut OUTPUT;

SELECT @ErrorOut AS Error;
```

### 8.2 Verify the archived record after closure
```sql
SELECT
    ho.OrderID,
    ho.CID,
    ho.ActionTypeID,
    ho.CloseOcurred,
    ho.InstrumentID,
    ho.Amount
FROM History.Orders ho WITH (NOLOCK)
WHERE ho.OrderID = 123456789
ORDER BY ho.CloseOcurred DESC;
```

### 8.3 Check History.OrdersFail1001 for server-close failures
```sql
SELECT TOP 10
    OrderID,
    CID,
    FailReason,
    FailOccurred,
    InstrumentID
FROM History.OrdersFail1001 WITH (NOLOCK)
ORDER BY FailOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (InsertAsyncRecord, DetachFromParentOrder) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersClose.sql*
