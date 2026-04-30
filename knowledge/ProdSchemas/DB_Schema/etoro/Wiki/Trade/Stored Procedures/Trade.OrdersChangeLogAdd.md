# Trade.OrdersChangeLogAdd

> Inserts an audit record into History.OrdersChangeLog capturing an order modification event with operation type, settlement flags, stop-loss/take-profit flags, and requesting service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (the order being logged) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersChangeLogAdd records an audit trail entry whenever an order is modified. Each call captures the OrderID, what type of operation was performed, who requested it, and relevant flags (settlement, stop-loss, take-profit settings). This provides a complete history of all changes to orders for compliance, debugging, and operational review.

Created by Alex on 2018-06-28 (FB 51445).

---

## 2. Business Logic

### 2.1 Change Log Insertion

**What**: Inserts a single audit record into History.OrdersChangeLog.

**Columns/Parameters Involved**: All parameters mapped 1:1 to History.OrdersChangeLog columns.

**Rules**:
- Direct INSERT with no transformation
- @OrderID is OUTPUT (allows chaining with order creation)
- @OperationTypeID defaults to 1 (standard operation)
- No validation on input values
- TRY/CATCH re-throws errors to caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | OrderID being logged. Declared OUTPUT to allow chaining with order creation procedures. |
| 2 | @OperationTypeID | INT | YES | 1 | CODE-BACKED | Type of operation performed on the order (default 1 = standard). Maps to a dictionary/enum. |
| 3 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID linking this change to the originating client request. |
| 4 | @IsSettled | BIT | YES | NULL | CODE-BACKED | Whether the order is marked as settled at the time of this change. |
| 5 | @SettlementTypeID | TINYINT | YES | NULL | CODE-BACKED | Settlement type at the time of this change. |
| 6 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | Whether the order has no stop-loss set. |
| 7 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | Whether the order has no take-profit set. |
| 8 | @RequestingService | VARCHAR(10) | YES | NULL | CODE-BACKED | Name/identifier of the service that requested this order change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.OrdersChangeLog | INSERT | Target audit table receiving the change record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpen | (post-open) | EXEC | Called after position opening to log the order change |
| Order modification procedures | Various | EXEC | Called whenever orders are modified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersChangeLogAdd (procedure)
+-- History.OrdersChangeLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersChangeLog | Table | INSERT - audit destination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpen | Procedure | EXEC - logs order changes during position open |
| Order management procedures | Procedures | EXEC - audit trail |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| TRY/CATCH with THROW | Error handling | Re-throws errors to caller |
| @OrderID OUTPUT | Chaining | Allows caller to use OrderID after procedure returns |

---

## 8. Sample Queries

### 8.1 View recent order change log entries

```sql
SELECT TOP 20 OrderID, OperationTypeID, ClientRequestGuid, IsSettled, RequestingService, *
FROM   History.OrdersChangeLog WITH (NOLOCK)
ORDER BY 1 DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersChangeLogAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersChangeLogAdd.sql*
