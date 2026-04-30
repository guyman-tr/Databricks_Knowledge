# Trade.CloseExecutionPlan

> Memory-optimized table storing the execution plan for closing positions—maps which positions and units to close for each order-for-close before actual hedge execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID, PositionID (composite PK) |
| **Partition** | No |
| **Indexes** | 6 (PK + 5 nonclustered) |

---

## 1. Business Meaning

**WHAT:** `CloseExecutionPlan` is a transient, memory-optimized table that holds the *plan* for closing one or more positions when a customer submits a close request. Each row represents one position segment (or tree node) to be closed as part of an `OrderForClose`. The plan includes which position(s), how many units, and at what level in the position hierarchy. Data is ephemeral—rows live here only while the close is pending; once execution completes, they are archived to `History.CloseExecutionPlan` and deleted from this table.

**WHY:** When a user closes a position tree (e.g., a copied mirror position with multiple child positions), the system must know *how* to break that closure into individual hedge closes—which positions, units, and order—before sending to the execution engine. This table decouples the user-initiated close request from the actual execution, allowing hierarchical position closes and correct PnL/allocation logic.

**HOW:** Data flows in when `Trade.OrderForCloseCreate` receives an order-for-close and a TVP `@CloseExecutionPlan`. It INSERTs rows from the TVP into this table. The execution jobs (`Trade.OrderForCloseJob`, `Trade.DeleteCloseExecutionPlanJob`, `Trade.CleanupCloseExecutionPlanJob`) read the plan, execute closes, and either DELETE rows for completed orders or MERGE into `History.CloseExecutionPlan` for archival. Readers such as `Trade.GetCloseExecutionPlan` and `Trade.GetOrderForClose` join this table to fetch position details for display or processing.

---

## 2. Business Logic

### 2.1 Execution Plan Creation (OrderForCloseCreate)

**What**: When a close request is accepted, the caller supplies a `Trade.CloseExecutionPlanTbl` TVP with one row per position (or tree level) to close. `OrderForCloseCreate` inserts these rows into `CloseExecutionPlan` atomically with the `OrderForClose` record.

**Columns/Parameters Involved**: OrderID, PositionID, Units, Level, CID, CloseActionType, IsHedged

**Rules**:
- PK is (OrderID, PositionID)—each order can have multiple positions, each position appears once per order
- On update flow (triggering order replacing waiting-for-market close), existing rows are DELETEd and new ones inserted
- Level=0 typically indicates the root/top-level position in the close tree

### 2.2 Plan Execution and Archival

**What**: Background jobs process orders-for-close. When an order completes or is cleaned up, its CloseExecutionPlan rows are moved to `History.CloseExecutionPlan` (with `OccurredAsDate`) and deleted from this table.

**Columns/Parameters Involved**: OrderID, PositionID, Units, Level, CID, CloseActionType, IsHedged

**Rules**:
- `DeleteCloseExecutionPlanJob` and `CleanupCloseExecutionPlanJob` MERGE into History then DELETE from Trade
- History table partitions by `OccurredAsDate` for efficient queries
- Rows remain in Trade only while the close is in progress (StatusID not terminal)

### 2.3 CloseActionType and IsHedged

**What**: CloseActionType indicates the business reason for the close (e.g., user-initiated, stop-loss, take-profit, copy mirror close). IsHedged indicates whether the position has an open hedge—affects execution path and fee logic.

**Columns/Parameters Involved**: CloseActionType, IsHedged

**Rules**:
- CloseActionType maps to `Dictionary.OrderForExecutionCloseActionType` (e.g., 13 = common value in live data)
- IsHedged=1 means the position has a corresponding hedge; affects routing and PnL calculation

---

## 3. Data Overview

| OrderID | PositionID | Units | Level | CID | CloseActionType | IsHedged | Meaning |
|---------|------------|-------|-------|-----|-----------------|----------|---------|
| 24293319 | 2152667128 | 23.088983 | 0 | 24497758 | 13 | 1 | Single position close, hedged, action type 13 |
| 24293320 | 2152667856 | 19.132184 | 0 | 24497758 | 13 | 1 | Another position for same order batch |
| 24293321 | 2152667859 | 19.475073 | 0 | 24497758 | 13 | 1 | Third position in same customer's close plan |

*Live data: ~978 rows, CloseActionType 13 dominates (~968), Level=0 for root positions.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | References `Trade.OrderForClose.OrderID`. The close order this plan belongs to. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | References `Trade.PositionTbl.PositionID`. The position to close. |
| 3 | Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units to close for this position in this plan. |
| 4 | Level | smallint | NO | - | CODE-BACKED | Tree level (0=root). Used for hierarchical close ordering; Level=0 commonly filters root positions. |
| 5 | CID | int | NO | - | CODE-BACKED | Customer ID. References `Customer.CustomerStatic.CID`. |
| 6 | CloseActionType | tinyint | NO | - | CODE-BACKED | Reason/type of close. Maps to `Dictionary.OrderForExecutionCloseActionType.ID`. |
| 7 | IsHedged | bit | NO | - | CODE-BACKED | Whether the position has an open hedge. Affects execution path and fee logic. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderForClose | Implicit FK | Parent close order |
| PositionID | Trade.PositionTbl | Implicit FK | Position being closed |
| CID | Customer.CustomerStatic | Implicit FK | Customer owning the position |
| CloseActionType | Dictionary.OrderForExecutionCloseActionType | Implicit FK | Close reason lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseCreate | @CloseExecutionPlan | WRITER | Inserts plan from TVP |
| Trade.OrderForCloseUpdate | cep | READER | Reads plan for order updates |
| Trade.DeleteCloseExecutionPlanJob | OrderID | DELETER | Archives and removes completed plans |
| Trade.CleanupCloseExecutionPlanJob | OrderID | DELETER | Archives stale plans |
| Trade.GetCloseExecutionPlan | cep | READER | Returns plan by OrderID |
| Trade.GetOrderForClose | CEP | READER | Joins for order display |
| Trade.ExecuteCashPayment | - | - | N/A (different table) |
| Trade.CashPaymentStatus | MonitorID→CashingOperationMonitor | N/A | Different flow |
| History.CloseExecutionPlan | OrderID, PositionID | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table) [implicit]
├── Trade.PositionTbl (table) [implicit]
├── Customer.CustomerStatic (table) [implicit]
└── Dictionary.OrderForExecutionCloseActionType (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table | Parent order; plan rows exist only while order is active |
| Trade.PositionTbl | Table | Position being closed |
| Customer.CustomerStatic | Table | Customer context |
| Dictionary.OrderForExecutionCloseActionType | Table | CloseActionType lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseCreate | Stored Procedure | WRITER—inserts from TVP |
| Trade.OrderForCloseUpdate | Stored Procedure | READER |
| Trade.DeleteCloseExecutionPlanJob | Stored Procedure | DELETER—archives to History |
| Trade.CleanupCloseExecutionPlanJob | Stored Procedure | DELETER—archives stale plans |
| Trade.GetCloseExecutionPlan | Stored Procedure | READER |
| Trade.GetOrderForClose | Stored Procedure | READER |
| History.CloseExecutionPlan | Table | Archive destination |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Filter | Notes |
|-----------|------|-------------|----------|--------|------|
| PK__Trade_CloseExecutionPlan_OrderID_PositionID | NONCLUSTERED HASH (PK) | OrderID, PositionID | - | - | BUCKET_COUNT=65536 |
| IX_OrderID | NONCLUSTERED | OrderID ASC | - | - | Lookup by order |
| IX_PositionID_IsHedged_NonHash | NONCLUSTERED | PositionID, IsHedged | - | - | Position + hedge filter |
| IDX_CID | NONCLUSTERED HASH | CID | - | - | BUCKET_COUNT=65536 |
| IDX_IsHedged | NONCLUSTERED HASH | IsHedged | - | - | BUCKET_COUNT=2 |
| IDX_Level | NONCLUSTERED HASH | Level | - | - | BUCKET_COUNT=32 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK__Trade_CloseExecutionPlan_OrderID_PositionID | PRIMARY KEY | (OrderID, PositionID). Ensures one plan row per (order, position). |

---

## 8. Sample Queries

### 8.1 Get execution plan for an order
```sql
SELECT  cep.OrderID,
        cep.PositionID,
        cep.Units,
        cep.Level,
        cep.CID,
        cep.CloseActionType,
        cep.IsHedged
FROM    Trade.CloseExecutionPlan cep WITH (NOLOCK)
WHERE   cep.OrderID = @OrderID
```

### 8.2 Count active plans by CID
```sql
SELECT  cep.CID,
        COUNT(*) AS PlanRowCount,
        COUNT(DISTINCT cep.OrderID) AS OrderCount
FROM    Trade.CloseExecutionPlan cep WITH (NOLOCK)
GROUP BY cep.CID
ORDER BY PlanRowCount DESC
```

### 8.3 Find root-level positions in plans (Level=0)
```sql
SELECT  cep.OrderID,
        cep.PositionID,
        cep.Units,
        cep.CID,
        o.StatusID AS OrderStatusID
FROM    Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose o WITH (NOLOCK) ON cep.OrderID = o.OrderID
WHERE   cep.Level = 0
ORDER BY cep.OrderID, cep.PositionID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trade.CloseExecutionPlan (TRAD) | Confluence | Memory-optimized table for execution plan; used during pre-execution for hierarchical position closes |
| Trade.OrderForCloseCreate (TRAD) | Confluence | Creates/updates orders-for-close and associated execution plans; handles new creation and waiting-for-market updates |
| Trade.GetOrderForClose (TRAD) | Confluence | Retrieves order-for-close with execution plan; mirrors activity for level 0 positions |

---

*Generated: 2026-03-14 | Quality: 8.5/10 | Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: Atlassian: 3 Confluence | Procedures: OrderForCloseCreate, DeleteCloseExecutionPlanJob, CleanupCloseExecutionPlanJob, GetCloseExecutionPlan, GetOrderForClose analyzed | Live data: ~978 rows*
