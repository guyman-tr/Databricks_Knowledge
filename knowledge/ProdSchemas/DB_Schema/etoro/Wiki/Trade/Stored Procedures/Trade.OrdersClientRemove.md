# Trade.OrdersClientRemove

> Cancels a pending open order at the customer's request - archiving it to History.Orders and removing it from Trade.Orders, with CopyTrader detachment for copy orders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (order to cancel) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer submits a pending open order (e.g., a limit order) and subsequently decides to cancel it before it executes, this procedure processes that cancellation. It is the "customer-side cancel" path - the user asked to remove their own order. The counterpart `Trade.OrdersServerRemove` handles server-side removal (e.g., when the order fails validation on the execution server).

The procedure archives the order to History.Orders (with ActionTypeID=1 = ClientRemove) before deleting it from Trade.Orders, ensuring the order record is never permanently lost. For CopyTrader copy orders, it also triggers the detachment of the parent-child relationship.

Data flow: The calling service provides the @OrderID and @CID. Ownership validation is performed when @RequestingService is supplied. The order is archived to History.Orders, deleted from Trade.Orders, and an async change log record is queued. On failure, the order is copied to History.OrdersFail for investigation.

---

## 2. Business Logic

### 2.1 Order Archive-and-Delete Pattern

**What**: All order removals (client or server) follow a consistent archive-then-delete pattern.

**Columns/Parameters Involved**: `History.Orders.ActionTypeID`, `Trade.Orders`

**Rules**:
- ActionTypeID = 1 hardcoded (ClientRemove) - distinguishes client cancels from server removes or expiry
- INSERT INTO History.Orders from Trade.Orders SELECT (copies ALL fields)
- CloseOcurred = GETDATE() in History record
- DELETE FROM Trade.Orders WHERE OrderID = @OrderID AND CID = @CID (double-checks ownership during delete)
- All within BEGIN TRANSACTION / COMMIT TRANSACTION

### 2.2 Ownership Validation (Service-Side)

**What**: When called from a service (@RequestingService IS NOT NULL), validates that @CID matches the order's owner.

**Columns/Parameters Involved**: `@RequestingService`, `@CID`, `Trade.Orders.CID`

**Rules**:
- If @RequestingService is NULL: skip ownership check (legacy direct call mode)
- If @RequestingService is specified: SELECT CID from Trade.Orders WHERE OrderID = @OrderID
  - If not found: RAISERROR(60000), RETURN 60000
  - If CID mismatch: RAISERROR(60001), RETURN 60001
- Comment notes that @CIDFromOrder ownership validation is made on service - this is an additional DB-level guard

### 2.3 CopyTrader Order Detachment (Demo DB Only)

**What**: For copy+ orders with a parent, removes the parent-child link in the demo database.

**Columns/Parameters Involved**: `@ParentOrderID`, `Maintenance.Feature.FeatureID=22`, `Trade.DetachFromParentOrder`

**Rules**:
- Runs only if @ParentOrderID > 0 (this is a copy order)
- AND only in Demo DB (Maintenance.Feature WHERE FeatureID=22 AND Value=0)
- Calls Trade.DetachFromParentOrder @OrderID, @ParentOrderID, 0
- The demo DB check prevents this from running in production (demo and prod share schema but not data)

### 2.4 Error Handling

**What**: On failure, records the failed attempt in History.OrdersFail for investigation.

**Columns/Parameters Involved**: `History.OrdersFail`, `@ClientVersion`

**Rules**:
- On CATCH: ROLLBACK, then RAISERROR(60000) "OrdersCustomerRemove", RETURN 60000
- Gets @ClientVersion from Customer.Login before inserting fail record
- Inserts to History.OrdersFail with FailReason = 'Error on Order Removing by Customer'
- Note: error 60000 is re-raised after the fail log INSERT (before that INSERT, different errors are possible)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The pending order ID to cancel. Must exist in Trade.Orders and belong to @CID (when @RequestingService is specified). |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the order owner. Used for ownership validation and as the CID in async record insertion. |
| 3 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key from the client cancel request. Included in async change log payload and fail record. |
| 4 | @RequestingService | varchar(10) | YES | NULL | CODE-BACKED | Service identifier for the calling service. When non-NULL: enables ownership validation (CID check). When NULL: legacy direct-call mode, no ownership check. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.Orders | READ + DELETE | Source of order data; deleted after archiving |
| @OrderID | History.Orders | INSERT (WRITE) | Archive destination - ActionTypeID=1 (ClientRemove) |
| @CID | Customer.Login | READ | Gets @ClientVersion for fail record (on error path only) |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues OrdersChangeLogAdd async record (OperationTypeID=2) |
| Conditional | Trade.DetachFromParentOrder | EXEC (CALL) | Removes CopyTrader parent link (Demo DB + copy+ order only) |
| On error | History.OrdersFail | INSERT (WRITE) | Fail record archive |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Confluence: Trade.OrdersClientRemove | External | Dedicated Confluence page in TRAD/DB (page 13795229771) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersClientRemove (procedure)
+-- Trade.Orders (table) [READ + DELETE - order data source]
+-- History.Orders (table) [WRITE - archive]
+-- Customer.Login (table) [READ - ClientVersion, on error only]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async change log]
+-- Trade.DetachFromParentOrder (procedure) [EXEC - copy+ detach, conditional]
+-- History.OrdersFail (table) [WRITE - fail record, on error only]
+-- Maintenance.Feature (table) [READ - Demo DB check for DetachFromParentOrder]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | SELECT for validation and archive source; DELETE to remove the order |
| History.Orders | Table | INSERT with ActionTypeID=1 to archive the cancelled order |
| Trade.InsertAsyncRecord | Stored Procedure | Queues OrdersChangeLogAdd with OperationTypeID=2 |
| Trade.DetachFromParentOrder | Stored Procedure | Removes parent-child link for CopyTrader orders in Demo DB |
| Customer.Login | Table | Reads ClientVersion for failure recording (error path only) |
| History.OrdersFail | Table | Archive for failed cancel attempts |
| Maintenance.Feature | Table | Read to determine if Demo DB (FeatureID=22) for copy+ detach logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Confluence: Trade.OrdersClientRemove | External | Documented in TRAD/DB Confluence (page 13795229771) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Transaction safety | Any error automatically rolls back the transaction |
| Error 60000 | Business error | Order not found (RAISERROR) or unexpected error (catch path) |
| Error 60001 | Business error | CID does not match the order's owner - unauthorized cancel attempt |
| Archive before delete | Audit rule | Order is always copied to History.Orders before deletion - no permanent data loss |

---

## 8. Sample Queries

### 8.1 Cancel a pending order
```sql
EXEC Trade.OrdersClientRemove
    @OrderID          = 123456789,
    @CID              = 111222,
    @ClientRequestGuid = '550E8400-E29B-41D4-A716-446655440000',
    @RequestingService = 'PREEXE';
```

### 8.2 Check the archive record after cancellation
```sql
SELECT
    ho.OrderID,
    ho.CID,
    ho.ActionTypeID,
    ho.CloseOcurred,
    ho.InstrumentID,
    ho.Amount,
    ho.IsBuy
FROM History.Orders ho WITH (NOLOCK)
WHERE ho.OrderID = 123456789
ORDER BY ho.CloseOcurred DESC;
```

### 8.3 Check for failed cancellation attempts
```sql
SELECT TOP 10
    OrderID,
    CID,
    FailReason,
    FailOccurred,
    InstrumentID
FROM History.OrdersFail WITH (NOLOCK)
WHERE CID = 111222
  AND FailReason LIKE '%Order Removing%'
ORDER BY FailOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.OrdersClientRemove](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795229771) | Confluence | Dedicated documentation page in TRAD/DB folder |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed (InsertAsyncRecord, DetachFromParentOrder) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersClientRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersClientRemove.sql*
