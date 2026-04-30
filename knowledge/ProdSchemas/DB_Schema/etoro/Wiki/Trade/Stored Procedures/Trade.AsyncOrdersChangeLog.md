# Trade.AsyncOrdersChangeLog

> Async dispatcher for order change log operations - routes XML payloads to the appropriate change log procedure (OrdersChangeLogAdd, OrdersEntryChangeLogAdd, or OrdersExitChangeLogAdd) and optionally archives completed orders to History.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params (XML payload containing OrderID and routing info) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.AsyncOrdersChangeLog is an asynchronous dispatcher that decouples order change log writes from the critical path of trade execution. When a position is opened or closed, the change log records (which track the order lifecycle) are written asynchronously via this procedure rather than synchronously during the trade, reducing latency on the hot path.

The procedure was introduced in November 2018 to move order change log writes from synchronous to asynchronous processing. Before this change, every position open/close had to wait for the change log INSERT to complete, adding latency to trade execution.

The procedure receives an XML payload from a Service Broker queue (indicated by the @Params xml, @PartsToDo, @ID signature pattern). It parses the XML to extract the order ID, operation type, and target procedure name, then routes to one of three handlers: Trade.OrdersChangeLogAdd (general change log), Trade.OrdersEntryChangeLogAdd (entry/open order change log with optional archival), or Trade.OrdersExitChangeLogAdd (exit/close order change log with optional archival).

---

## 2. Business Logic

### 2.1 Procedure Name Routing (Whitelist)

**What**: Routes the XML payload to one of three allowed procedures based on @ProcedureName.

**Columns/Parameters Involved**: `@ProcedureName`

**Rules**:
- Only three procedure names are allowed: Trade.OrdersChangeLogAdd, Trade.EntryOrderPostActions, Trade.ExitOrderPostActions
- Any other @ProcedureName: RAISERROR 'Invalid Procedure name'
- This whitelist prevents arbitrary procedure execution from the queue

**Diagram**:
```
XML Payload (@Params)
    |
    v
[Parse XML -> extract OrderID, OperationTypeID, ProcedureName, ...]
    |
    v
[Validate ProcedureName in whitelist]
    |
    +---> 'Trade.OrdersChangeLogAdd'
    |         EXEC Trade.OrdersChangeLogAdd
    |         RETURN
    |
    +---> 'Trade.EntryOrderPostActions'
    |         EXEC Trade.OrdersEntryChangeLogAdd
    |         IF OperationTypeID = 2 (Close/Cancel)
    |             DELETE Trade.OrdersEntryTbl -> History.OrdersEntryTbl
    |         RETURN
    |
    +---> 'Trade.ExitOrderPostActions'
              EXEC Trade.OrdersExitChangeLogAdd
              IF OperationTypeID = 2 (Close/Cancel)
                  DELETE Trade.OrdersExitTbl -> History.OrdersExitTbl
              RETURN
```

### 2.2 Order Archival on Close (OperationTypeID = 2)

**What**: When the operation type is 2 (close/cancel), the order record is moved from the active table to the history table.

**Columns/Parameters Involved**: `@OperationTypeID`, `@OrderID`

**Rules**:
- Entry orders: DELETE from Trade.OrdersEntryTbl, OUTPUT INTO History.OrdersEntryTbl
- Exit orders: DELETE from Trade.OrdersExitTbl, OUTPUT INTO History.OrdersExitTbl
- Uses DELETE...OUTPUT pattern for atomic move (no separate INSERT + DELETE)
- Only the specific @OrderID row is moved

### 2.3 Silent Error Handling

**What**: Errors are swallowed and the procedure returns -1.

**Rules**:
- TRY/CATCH wraps all logic
- On error: RETURN -1 (no THROW, no RAISERROR)
- This is intentional for async processing - the calling queue should not retry on failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | xml | NO | - | CODE-BACKED | XML payload from the Service Broker queue containing all order change log data. Root element with child elements: OrderID, OperationTypeID, ClientRequestGuid, ProcedureName, CurrentUnitsToDeduct, PreviousUnitsToDeduct, IsSettled, SettlementTypeID, IsNoStopLoss, IsNoTakeProfit, RequestingService. |
| 2 | @PartsToDo | INT | YES | NULL | CODE-BACKED | Service Broker queue activation parameter. Number of parts remaining in the queue batch. Standard SB pattern. |
| 3 | @ID | INT | YES | NULL | CODE-BACKED | Service Broker queue activation parameter. Message ID or batch ID. Standard SB pattern. |

**Parsed XML elements (internal variables)**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | @OrderID | INT | NO | - | CODE-BACKED | Order ID being logged. Parsed from XML Root/OrderID. Identifies the order in Trade.OrdersEntryTbl or Trade.OrdersExitTbl. |
| 5 | @OperationTypeID | INT | YES | 1 | CODE-BACKED | Operation type: 1=Open/Create, 2=Close/Cancel. Defaults to 1 if not provided. When 2, triggers archival to History tables. |
| 6 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID for the client request. Passed through to the change log procedures for traceability. |
| 7 | @ProcedureName | sysname | NO | - | CODE-BACKED | Target procedure: 'Trade.OrdersChangeLogAdd', 'Trade.EntryOrderPostActions', or 'Trade.ExitOrderPostActions'. Must match whitelist. |
| 8 | @UnitsToDeduct | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Current units to deduct for partial close scenarios. Only used by Trade.OrdersExitChangeLogAdd. |
| 9 | @PreviousUnitsToDeduct | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Previous units to deduct value before this operation. Only used by Trade.OrdersExitChangeLogAdd. |
| 10 | @IsSettled | BIT | YES | NULL | CODE-BACKED | Real stock flag: 1=Real, 0=CFD. Passed to Trade.OrdersChangeLogAdd. |
| 11 | @SettlementTypeID | TINYINT | YES | NULL | CODE-BACKED | Settlement type from Dictionary.SettlementTypes. Passed to Trade.OrdersChangeLogAdd. |
| 12 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | Whether the position has no stop loss. Passed to Trade.OrdersChangeLogAdd. |
| 13 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | Whether the position has no take profit. Passed to Trade.OrdersChangeLogAdd. |
| 14 | @RequestingService | VARCHAR(10) | YES | NULL | CODE-BACKED | Name of the service that initiated the change log write. Passed to Trade.OrdersChangeLogAdd. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Trade.OrdersChangeLogAdd | EXEC | General order change log writer |
| EXEC | Trade.OrdersEntryChangeLogAdd | EXEC | Entry (open) order change log writer |
| EXEC | Trade.OrdersExitChangeLogAdd | EXEC | Exit (close) order change log writer |
| DELETE...OUTPUT | Trade.OrdersEntryTbl | DELETE | Archives completed entry orders (OperationTypeID=2) |
| INSERT | History.OrdersEntryTbl | INSERT | History archive for entry orders |
| DELETE...OUTPUT | Trade.OrdersExitTbl | DELETE | Archives completed exit orders (OperationTypeID=2) |
| INSERT | History.OrdersExitTbl | INSERT | History archive for exit orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Service Broker queue | Queue activation | EXEC | Invoked asynchronously from the SBR queue for order change log processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AsyncOrdersChangeLog (procedure)
+-- Trade.OrdersChangeLogAdd (procedure)
+-- Trade.OrdersEntryChangeLogAdd (procedure)
+-- Trade.OrdersExitChangeLogAdd (procedure)
+-- Trade.OrdersEntryTbl (table)
+-- Trade.OrdersExitTbl (table)
+-- History.OrdersEntryTbl (table)
+-- History.OrdersExitTbl (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersChangeLogAdd | Procedure | EXEC - writes general order change log |
| Trade.OrdersEntryChangeLogAdd | Procedure | EXEC - writes entry order change log |
| Trade.OrdersExitChangeLogAdd | Procedure | EXEC - writes exit order change log |
| Trade.OrdersEntryTbl | Table | DELETE - removes completed entry orders for archival |
| Trade.OrdersExitTbl | Table | DELETE - removes completed exit orders for archival |
| History.OrdersEntryTbl | Table | INSERT (via OUTPUT) - receives archived entry orders |
| History.OrdersExitTbl | Table | INSERT (via OUTPUT) - receives archived exit orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Service Broker queue | Infrastructure | Activates this SP for async change log processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Procedure whitelist | Security | Only Trade.OrdersChangeLogAdd, Trade.EntryOrderPostActions, Trade.ExitOrderPostActions are allowed |
| TRY/CATCH RETURN -1 | Error handling | Errors are silently caught - appropriate for async queue processing |
| DELETE...OUTPUT | Atomicity | Atomic move from active to history tables using DELETE with OUTPUT INTO |

---

## 8. Sample Queries

### 8.1 Check recent order change logs

```sql
SELECT TOP 20 *
FROM   Trade.OrdersChangeLog WITH (NOLOCK)
ORDER BY OrdersChangeLogID DESC;
```

### 8.2 View archived entry orders

```sql
SELECT TOP 10 OrderID, CID, InstrumentID, Leverage, Amount, IsBuy,
       OpenOccurred, ClosedOccurred
FROM   History.OrdersEntryTbl WITH (NOLOCK)
ORDER BY ClosedOccurred DESC;
```

### 8.3 View archived exit orders

```sql
SELECT TOP 10 OrderID, PositionID, CID, CloseActionType,
       OpenOccurred, CloseOccurred
FROM   History.OrdersExitTbl WITH (NOLOCK)
ORDER BY CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AsyncOrdersChangeLog | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AsyncOrdersChangeLog.sql*
