# Trade.OpenExecutionPlanTbl

> A memory-optimized table-valued parameter type carrying open-order execution plans: order, mirror, units, level, settlement, hedging, and correlation data for bulk order creation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID (indexed) |
| **Partition** | N/A |
| **Indexes** | 1 (IDX_OrderID nonclustered hash on OrderID, BUCKET_COUNT=2) |

---

## 1. Business Meaning

Trade.OpenExecutionPlanTbl is a memory-optimized table-valued parameter type that holds open-order execution plans. Each row represents one order's execution parameters: CID, MirrorID, Units, Level, SettlementType, IsHedged, OpenActionType, OpenCorrelationID, and related fields. It enables bulk submission of multiple open orders in a single procedure call.

This type exists to support OrderForOpenCreate and OrderForOpenCreateWrapper, which accept a batch of open-order plans and execute them. Memory optimization reduces locking and improves throughput for high-volume order creation.

The application builds an OpenExecutionPlanTbl with one or more order plans and passes it as a READONLY parameter. The procedure iterates or JOINs against the TVP to create the corresponding orders.

---

## 2. Business Logic

OrderID + CID + MirrorID + Units + Level + SettlementType + IsHedged + OpenActionType + OpenCorrelationID form an execution plan unit. ParentOpenCorrelationID supports correlation of child orders to parent; Amount is optional and may be computed from Units.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Order identifier for this execution plan. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - account placing the order. |
| 3 | MirrorID | int | NO | - | CODE-BACKED | Mirror ID for copy-trade context. |
| 4 | Units | decimal(16,6) | NO | - | CODE-BACKED | Order size in units. |
| 5 | Level | smallint | NO | - | NAME-INFERRED | Execution level or tier. |
| 6 | SettlementType | int | NO | - | CODE-BACKED | Settlement type (e.g. cash, physical). |
| 7 | IsHedged | bit | NO | - | NAME-INFERRED | 1 if order is hedged. |
| 8 | OpenActionType | tinyint | NO | - | CODE-BACKED | Type of open action. |
| 9 | OpenCorrelationID | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID for grouping related opens. |
| 10 | ParentOpenCorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Parent correlation ID for child orders. |
| 11 | Amount | money | YES | - | NAME-INFERRED | Optional notional amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID, MirrorID semantically reference Customer and Mirror entities.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreate | @OpenExecutionPlan | Parameter (TVP) | Creates open orders from execution plan batch |
| Trade.OrderForOpenCreateWrapper | @OpenExecutionPlan | Parameter (TVP) | Wrapper that passes plan to OrderForOpenCreate |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenCreate | Stored Procedure | READONLY parameter for bulk open order creation |
| Trade.OrderForOpenCreateWrapper | Stored Procedure | READONLY parameter for bulk open order creation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns |
|------------|------|---------|
| IDX_OrderID | NONCLUSTERED HASH | OrderID (BUCKET_COUNT=2) |

Memory-optimized type (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk open

```sql
DECLARE @Plan Trade.OpenExecutionPlanTbl;
INSERT INTO @Plan (OrderID, CID, MirrorID, Units, Level, SettlementType, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount)
VALUES (1001, 12345, 1, 100.5, 1, 0, 0, 1, NEWID(), NULL, 10000);
EXEC Trade.OrderForOpenCreate @OpenExecutionPlan = @Plan;
```

### 8.2 Multiple orders with correlation

```sql
DECLARE @Plan Trade.OpenExecutionPlanTbl;
DECLARE @CorrID uniqueidentifier = NEWID();
INSERT INTO @Plan (OrderID, CID, MirrorID, Units, Level, SettlementType, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount)
VALUES (1001, 12345, 1, 100, 1, 0, 0, 1, @CorrID, NULL, NULL),
       (1002, 12345, 1, 50, 1, 0, 0, 1, NEWID(), @CorrID, NULL);
EXEC Trade.OrderForOpenCreate @OpenExecutionPlan = @Plan;
```

### 8.3 Via wrapper procedure

```sql
DECLARE @Plan Trade.OpenExecutionPlanTbl;
INSERT INTO @Plan (OrderID, CID, MirrorID, Units, Level, SettlementType, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount)
SELECT OrderID, CID, MirrorID, Units, 1, 0, 0, 1, OpenCorrelationID, NULL, NULL
FROM Staging.OpenOrders;
EXEC Trade.OrderForOpenCreateWrapper @OpenExecutionPlan = @Plan;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OpenExecutionPlanTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OpenExecutionPlanTbl.sql*
