# Trade.OrderWithPositions_MOT

> Memory-optimized TVP combining close orders with their linked position ID: order metadata, status, execution, and error info.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID |
| **Partition** | N/A |
| **Indexes** | 1 (IX_OrderID nonclustered on OrderID) |

---

## 1. Business Meaning

Trade.OrderWithPositions_MOT is a memory-optimized table-valued parameter type that pairs close orders with their associated position. Each row holds order ID, customer, status, units to deduct, request metadata, execution and error details, instrument, order type, and position ID. It supports API procedures that need order-plus-position data in a single structure.

This type exists to provide a combined order-and-position view for mirror-data API responses. GetMirrorDataWithCIDAndMirrorIdForAPI and GetMirrorDataWithCIDForAPI declare variables of this type, populate them from order/position joins, and use them for output.

The type flows as a local table variable. Procedures populate it from joined order and position data, then SELECT from it for API results.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type groups order identity, status, execution, and position linkage.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Close order ID. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 3 | StatusID | int | NO | - | CODE-BACKED | Order status. |
| 4 | UnitsToDeduct | decimal(16,6) | YES | - | NAME-INFERRED | Units to deduct from position. |
| 5 | RequestGuid | uniqueidentifier | YES | - | NAME-INFERRED | Request correlation GUID. |
| 6 | RequestOccurred | datetime | NO | - | NAME-INFERRED | When the close request occurred. |
| 7 | OpenDateTime | datetime | NO | - | NAME-INFERRED | Order open date. |
| 8 | LastUpdate | datetime | NO | - | NAME-INFERRED | Last update timestamp. |
| 9 | ExecutionID | bigint | YES | - | CODE-BACKED | Execution result ID. |
| 10 | ErrorCode | int | NO | - | CODE-BACKED | Error code if execution failed. |
| 11 | ErrorMessage | varchar(1000) | YES | - | CODE-BACKED | Error message if execution failed. |
| 12 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position. |
| 13 | OrderType | int | NO | - | CODE-BACKED | Close order type. |
| 14 | PositionID | bigint | NO | - | CODE-BACKED | Position being closed. |
| 15 | LotsToDeduct | decimal(16,6) | YES | - | NAME-INFERRED | Lots to deduct. |

---

## 5. Relationships

### 5.1 References To (this object points to)

OrderID, PositionID, CID, InstrumentID semantically reference Trade and Customer entities. No declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | @OrderWithPositions_MOT | Local variable (TVP) | Holds order-with-position data for mirror API output |
| Trade.GetMirrorDataWithCIDForAPI | @OrderWithPositions_MOT | Local variable (TVP) | Holds order-with-position data for mirror API output |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorDataWithCIDAndMirrorIdForAPI | Stored Procedure | Local table variable for mirror API order+position data |
| Trade.GetMirrorDataWithCIDForAPI | Stored Procedure | Local table variable for mirror API order+position data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| IX_OrderID | NONCLUSTERED | OrderID |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate OrderWithPositions_MOT

```sql
DECLARE @OrderWithPositions_MOT Trade.OrderWithPositions_MOT;
INSERT INTO @OrderWithPositions_MOT
    (OrderID, CID, StatusID, UnitsToDeduct, RequestGuid, RequestOccurred,
     OpenDateTime, LastUpdate, ExecutionID, ErrorCode, ErrorMessage,
     InstrumentID, OrderType, PositionID, LotsToDeduct)
VALUES
    (9001, 50001, 1, 100.5, NEWID(), GETDATE(), GETDATE(), GETDATE(),
     NULL, 0, NULL, 101, 2, 1001, 1.005);
```

### 8.2 Populate from order and position join

```sql
INSERT INTO @OrderWithPositions_MOT
SELECT o.OrderID, o.CID, o.StatusID, o.UnitsToDeduct, o.RequestGuid,
       o.RequestOccurred, o.OpenDateTime, o.LastUpdate, o.ExecutionID,
       o.ErrorCode, o.ErrorMessage, p.InstrumentID, o.OrderType,
       o.PositionID, o.LotsToDeduct
FROM Trade.OrderForCloseTbl o
JOIN Trade.PositionTbl p ON o.PositionID = p.PositionID
WHERE o.CID = @CID;
```

### 8.3 Query for API output

```sql
SELECT OrderID, CID, StatusID, PositionID, InstrumentID, UnitsToDeduct
FROM @OrderWithPositions_MOT
WHERE StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderWithPositions_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrderWithPositions_MOT.sql*
