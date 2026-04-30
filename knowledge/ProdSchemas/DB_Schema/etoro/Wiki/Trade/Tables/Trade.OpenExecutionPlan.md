# Trade.OpenExecutionPlan

> Memory-optimized table storing the execution plan for position-open orders - a tree structure for copy-trade with one row per copy-tree level, linking OrderID to OpenCorrelationID for hierarchical execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID, OpenCorrelationID (composite PK) |
| **Partition** | No |
| **Indexes** | 7 (PK + 6 nonclustered) |

---

## 1. Business Meaning

**WHAT:** `OpenExecutionPlan` is a transient, memory-optimized table that holds the *plan* for opening one or more positions when a customer submits an order-for-open. Each row represents one node in the copy-trade tree: which customer (CID), which mirror (MirrorID), how many units, at what level, and with which settlement type. The table supports hierarchical opens where one OrderForOpen can spawn multiple positions across a copy tree (e.g., mirror parent and child investors).

**WHY:** When a user opens a position that propagates through copy-trading (mirror relationships), the system must know *how* to break that open into individual hedge executions - which customers, units, and order - before sending to the execution engine. OpenExecutionPlan decouples the user-initiated open request from the actual execution, allowing hierarchical position opens and correct allocation logic. Each order can have multiple OpenExecutionPlan rows (one per copy-tree level).

**HOW:** Data flows in when `Trade.OrderForOpenCreate` receives an order-for-open and a TVP `@OpenExecutionPlan` of type `Trade.OpenExecutionPlanTbl`. It INSERTs rows from the TVP into this table. The execution jobs (`Trade.OrderForOpenJob`, `Trade.CleanupOpenExecutionPlanJob`, `Trade.DeleteOpenExecutionPlanJob`) read the plan, execute opens, and either DELETE rows for completed orders or MERGE into `History.OpenExecutionPlan` for archival. Readers such as `Trade.GetOpenExecutionPlan` and `Trade.GetOrderForOpenContextData` fetch plan details for display or processing. ExecutedOpenOrders links back via OpenCorrelationID to record what was actually opened.

---

## 2. Business Logic

### 2.1 Plan Creation (OrderForOpenCreate)

**What:** When an open request is accepted, the caller supplies a `Trade.OpenExecutionPlanTbl` TVP with one row per copy-tree node. OrderForOpenCreate inserts these rows into OpenExecutionPlan atomically with the OrderForOpen record. On update flow (triggering order replacing waiting-for-market open), existing rows are DELETEd and new ones inserted from the TVP.

**Columns/Parameters Involved:** OrderID, CID, MirrorID, Units, Level, SettlementTypeID, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount

**Rules:**
- PK is (OrderID, OpenCorrelationID) - each order can have multiple rows (one per tree node)
- OpenCorrelationID uniquely identifies a node; ParentOpenCorrelationID links to parent node (NULL for root)
- Level indicates tree depth; Level 0 typically root
- On WAITING_FOR_MARKET update: DELETE FROM Trade.OpenExecutionPlan WHERE OrderID = @OrderID, then re-insert from new TVP

### 2.2 Plan Execution and ExecutedOpenOrders Link

**What:** When a position is opened, `Trade.PositionOpen` inserts into ExecutedOpenOrders with (OrderID, PositionID, OpenCorrelationID, ...). The OpenCorrelationID in ExecutedOpenOrders matches OpenCorrelationID in OpenExecutionPlan - thus plan rows can be joined to executed results. OrderForOpenUpdate uses LEFT JOIN ExecutedOpenOrders on (oep.OrderID = eo.OrderID AND oep.OpenCorrelationID = eo.OpenCorrelationID) to detect which plan nodes are not yet executed (eo.PositionID IS NULL).

**Columns/Parameters Involved:** OpenCorrelationID, OrderID, PositionID, Units, Level, CID, MirrorID

**Rules:**
- OpenCorrelationID is the join key between plan and execution
- GetOrderForOpenContextData retrieves PostAdjustmentRatio, ParentPositionID, TreeID from ExecutedOpenOrders WHERE OpenCorrelationID = @ParentOpenCorrelationID for hierarchy resolution

### 2.3 Cleanup and Archival

**What:** `Trade.CleanupOpenExecutionPlanJob` and `Trade.DeleteOpenExecutionPlanJob` move OpenExecutionPlan rows to History.OpenExecutionPlan (with OccurredAsDate for partition elimination) and delete from Trade once orders complete and are no longer in Trade.OrderForOpen.

**Columns/Parameters Involved:** OrderID, OpenCorrelationID

**Rules:**
- Cleanup identifies OrderIDs in OpenExecutionPlan EXCEPT OrderForOpen
- DeleteExecutedOpenOrdersJob and DeleteOpenExecutionPlanJob run in OrderForOpenJob chain
- History table partitions by OccurredAsDate

---

## 3. Data Overview

| OrderID | CID | MirrorID | Units | Level | SettlementTypeID | IsHedged | OpenActionType | OpenCorrelationID | ParentOpenCorrelationID | Amount | Meaning |
|---------|-----|-----------|------|-------|------------------|----------|----------------|-------------------|-------------------------|--------|---------|
| 24207615 | 14820307 | 0 | 0.004166 | 0 | 1 | 1 | 0 | 7BCF4C68-BAD0-489D-A7B6-FF20C840A5E5 | NULL | 99.98 | Root-level open, REAL settlement, hedged, Manual, single node |

*SettlementTypeID 1 = REAL. OpenActionType 0 = Manual. IsHedged=1 indicates position has hedge.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | References Trade.OrderForOpen.OrderID. The open order this plan belongs to. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. References Customer.CustomerStatic.CID. Owner of this tree node. |
| 3 | MirrorID | int | NO | - | CODE-BACKED | Mirror/trader ID. 0 for non-copy; >0 for copy-trade. |
| 4 | Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units to open for this node. |
| 5 | Level | smallint | NO | - | CODE-BACKED | Tree level (0=root). Hierarchical ordering. |
| 6 | SettlementTypeID | int | NO | - | CODE-BACKED | Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. |
| 7 | IsHedged | bit | NO | - | CODE-BACKED | Whether this node has an open hedge. Affects execution path. |
| 8 | OpenActionType | tinyint | NO | - | CODE-BACKED | Dictionary.OrdersExitOpenActionType: 0=Manual, 1=OpenByUnregisterMirror, 2=OpenByBackOffice. |
| 9 | OpenCorrelationID | uniqueidentifier | NO | - | CODE-BACKED | Unique ID for this plan node. Joins to ExecutedOpenOrders.OpenCorrelationID. |
| 10 | ParentOpenCorrelationID | uniqueidentifier | NULL | - | CODE-BACKED | Parent node's OpenCorrelationID. NULL for root. |
| 11 | Amount | money | NULL | - | CODE-BACKED | Position amount for this node. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderForOpen | Implicit FK | Parent open order |
| CID | Customer.CustomerStatic | Implicit FK | Customer owning this node |
| MirrorID | Trade.Mirror | Implicit FK | Copy-trade mirror |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit FK | Settlement lookup |
| OpenActionType | Dictionary.OrdersExitOpenActionType | Implicit FK | Open reason lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreate | @OpenExecutionPlan | WRITER | Inserts plan from TVP |
| Trade.OrderForOpenUpdate | oep | READER | Execution summary, plan vs executed |
| Trade.GetOpenExecutionPlan | oep | READER | Returns plan by OrderID |
| Trade.GetOrderForOpenContextData | ExecutedOpenOrders | READER | Parent data via OpenCorrelationID |
| Trade.GetExecutedOpenPositionCorrelationIDs | oep | READER | Join with ExecutedOpenOrders |
| Trade.GetOpenOrderExecutedUnits | oep | READER | Join with ExecutedOpenOrders |
| Trade.CleanupOpenExecutionPlanJob | - | DELETER | Archives and removes |
| Trade.DeleteOpenExecutionPlanJob | - | DELETER | Explicit order cleanup |
| Trade.ViewBulkOrders | toep | READER | Bulk order view |
| Trade.GetOrdersForExecutionReportV2 | toep | READER | Execution report |
| Trade.FailedDelayedCopyOrders | p | READER | Failed copy analysis |
| Trade.PositionOpen | - | Indirect | Uses OpenCorrelationID for ExecutedOpenOrders |
| History.OpenExecutionPlan | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OpenExecutionPlan (table)
├── Trade.OrderForOpen (table) [implicit]
├── Trade.ExecutedOpenOrders (table) [OpenCorrelationID join]
├── Customer.CustomerStatic (table) [implicit, CID]
├── Trade.Mirror (table) [implicit, MirrorID]
└── Dictionary.SettlementTypes (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|-----------------|
| Trade.OrderForOpen | Parent order |
| Trade.OpenExecutionPlanTbl | TVP shape for insert |
| Customer.CustomerStatic | CID lookup |
| Trade.Mirror | MirrorID lookup |
| Dictionary.SettlementTypes | SettlementTypeID lookup |
| Dictionary.OrdersExitOpenActionType | OpenActionType lookup |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|-----------------|
| History.OpenExecutionPlan | Archive target |
| Trade.ExecutedOpenOrders | Links via OpenCorrelationID |
| Trade.GetOpenExecutionPlan | Primary reader |
| Trade.OrderForOpenUpdate | Execution summary |
| Trade.GetOrderForOpenContextData | Parent resolution |
| Trade.ViewBulkOrders, GetOrdersForExecutionReportV2 | Reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| PK__Trade_OpenExecutionPlan_OrderID_OpenCorrelationID | PRIMARY KEY NONCLUSTERED HASH | OrderID, OpenCorrelationID | PK, BUCKET_COUNT 65536 |
| IDX_IsHedged | NONCLUSTERED HASH | IsHedged | IsHedged filter, BUCKET_COUNT 2 |
| IDX_Level | NONCLUSTERED HASH | Level | Level filter, BUCKET_COUNT 32 |
| IX_CID | NONCLUSTERED HASH | CID | CID lookup, BUCKET_COUNT 65536 |
| IX_MirrorID | NONCLUSTERED HASH | MirrorID | MirrorID lookup, BUCKET_COUNT 65536 |
| IX_OpenCorrelationID_IsHedged | NONCLUSTERED | OpenCorrelationID, IsHedged | Correlation + hedge join |
| IX_OrderID | NONCLUSTERED HASH | OrderID | Order lookup, BUCKET_COUNT 16384 |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK__Trade_OpenExecutionPlan_OrderID_OpenCorrelationID | PRIMARY KEY | (OrderID, OpenCorrelationID) |

---

## 8. Sample Queries

```sql
-- Get execution plan for an order (Trade.GetOpenExecutionPlan)
SELECT OpenCorrelationID, ParentOpenCorrelationID, Units, Level, IsHedged, CID, MirrorID, OpenActionType, SettlementTypeID
FROM Trade.OpenExecutionPlan WITH (NOLOCK)
WHERE OrderID = 24207615;

-- Plan vs executed: find plan nodes not yet executed
SELECT oep.OpenCorrelationID, oep.CID, oep.Units, eo.PositionID
FROM Trade.OpenExecutionPlan oep WITH (NOLOCK)
LEFT JOIN Trade.ExecutedOpenOrders eo WITH (NOLOCK)
    ON oep.OrderID = eo.OrderID AND oep.OpenCorrelationID = eo.OpenCorrelationID
WHERE oep.OrderID = 24207615 AND eo.PositionID IS NULL;

-- Distribution by SettlementTypeID
SELECT SettlementTypeID, COUNT(*) AS Cnt
FROM Trade.OpenExecutionPlan WITH (NOLOCK)
GROUP BY SettlementTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10*
