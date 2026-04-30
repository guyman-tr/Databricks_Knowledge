# Trade.OrdersForCloseType

> Memory-optimized TVP for close orders: order ID, status, position, units, request metadata, execution outcome, and error info.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID |
| **Partition** | N/A |
| **Indexes** | 1 (ix1 nonclustered on OrderID) |

---

## 1. Business Meaning

Trade.OrdersForCloseType is a memory-optimized table-valued parameter type that represents close orders and their lifecycle state. Each row holds an order ID, customer, status, position, units to deduct, request metadata (GUID, timestamps), execution ID, and error details. It is used when processing portfolios of close orders in bulk.

This type exists to pass batches of close orders into procedures that process order status, execution, and error handling. PortfolioForApiInnerMot declares a variable of this type and populates it for API portfolio processing.

The type flows as a local table variable. Callers or procedures insert rows and pass the table (or use it internally) for JOINs and status updates.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups order identity (OrderID, PositionID), status and execution fields, and error messaging.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | YES | - | CODE-BACKED | Close order ID. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID. |
| 3 | StatusID | int | YES | - | CODE-BACKED | Order status. |
| 4 | PositionID | bigint | YES | - | CODE-BACKED | Position being closed. |
| 5 | UnitsToDeduct | decimal(16,6) | YES | - | NAME-INFERRED | Units to deduct from position. |
| 6 | RequestGuid | uniqueidentifier | YES | - | NAME-INFERRED | Request correlation GUID. |
| 7 | RequestOccurred | datetime | YES | - | NAME-INFERRED | When the close request occurred. |
| 8 | OpenDateTime | datetime | YES | - | NAME-INFERRED | Order open date. |
| 9 | LastUpdate | datetime | YES | - | NAME-INFERRED | Last update timestamp. |
| 10 | ExecutionID | bigint | YES | - | CODE-BACKED | Execution result ID. |
| 11 | ErrorCode | int | YES | - | CODE-BACKED | Error code if execution failed. |
| 12 | ErrorMessage | varchar(1000) | YES | - | CODE-BACKED | Error message if execution failed. |
| 13 | InstrumentID | int | YES | - | CODE-BACKED | Instrument of the position. |
| 14 | OrderType | int | YES | - | CODE-BACKED | Close order type. |
| 15 | LotsToDeduct | decimal(16,6) | YES | - | NAME-INFERRED | Lots to deduct (alternative to UnitsToDeduct). |

---

## 5. Relationships

### 5.1 References To (this object points to)

OrderID, PositionID, CID, InstrumentID semantically reference Trade and Customer entities. No declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PortfolioForApiInnerMot | @OrdersForClose | Local variable (TVP) | Holds close orders for portfolio API processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PortfolioForApiInnerMot | Stored Procedure | Local table variable for close orders in portfolio API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| ix1 | NONCLUSTERED | OrderID |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate OrdersForCloseType

```sql
DECLARE @OrdersForClose Trade.OrdersForCloseType;
INSERT INTO @OrdersForClose
    (OrderID, CID, StatusID, PositionID, UnitsToDeduct, RequestGuid,
     RequestOccurred, OpenDateTime, LastUpdate, InstrumentID, OrderType)
VALUES
    (9001, 50001, 1, 1001, 100.5, NEWID(), GETDATE(), GETDATE(), GETDATE(), 101, 2);
```

### 8.2 Populate with error info

```sql
INSERT INTO @OrdersForClose
    (OrderID, CID, StatusID, ErrorCode, ErrorMessage, InstrumentID, OrderType)
VALUES
    (9002, 50001, 3, 500, 'Insufficient margin', 101, 2);
```

### 8.3 Batch from order table

```sql
INSERT INTO @OrdersForClose
SELECT OrderID, CID, StatusID, PositionID, UnitsToDeduct, RequestGuid,
       RequestOccurred, OpenDateTime, LastUpdate, ExecutionID, ErrorCode,
       ErrorMessage, InstrumentID, OrderType, LotsToDeduct
FROM Trade.OrderForCloseTbl
WHERE StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 8 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersForCloseType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrdersForCloseType.sql*
