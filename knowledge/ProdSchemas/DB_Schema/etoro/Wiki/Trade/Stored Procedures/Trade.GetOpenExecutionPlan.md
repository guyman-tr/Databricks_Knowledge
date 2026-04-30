# Trade.GetOpenExecutionPlan

> Native-compiled stored procedure that retrieves the full open-execution plan for a given order, returning all copy-tree nodes with their units, levels, settlement, and hedge flags.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT - the open order whose plan is fetched |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenExecutionPlan` fetches the rows from `Trade.OpenExecutionPlan` that belong to a single open order. Each row is one node in the position-open tree: the root (the initiating customer) plus any copy-trade children. Together they describe exactly how the order will be (or was) split and executed across the copy-trade hierarchy.

**WHY:** Before the trading execution engine can open positions it needs the plan - which CIDs, how many units each, at which tree level, with which settlement type, and whether hedging is active. This SP is the query gateway: it delivers that plan to the execution engine or to callers that need to inspect plan state (e.g., to determine which nodes are still pending vs already executed by joining against `ExecutedOpenOrders`).

**HOW:** Called from application code (trading execution services) after an `OrderForOpen` is created and the plan is inserted by `Trade.OrderForOpenCreate`. The procedure runs in a memory-optimized context (native compilation, SNAPSHOT isolation) for maximum throughput during the high-frequency open-order processing path. Once the plan is consumed and positions are opened, the plan rows are cleaned up by `Trade.CleanupOpenExecutionPlanJob` / `Trade.DeleteOpenExecutionPlanJob`.

---

## 2. Business Logic

### 2.1 Copy-Trade Tree Execution Plan

**What:** A single `OrderForOpen` can spawn multiple position opens across a copy-trade tree. Each tree node is one row in `OpenExecutionPlan`, linked by `ParentOpenCorrelationID`. This SP returns all nodes for the given order.

**Columns/Parameters Involved:** `@OrderID`, `Level`, `OpenCorrelationID`, `ParentOpenCorrelationID`, `CID`, `MirrorID`, `Units`

**Rules:**
- Level 0 = root node (the initiating customer's own position open)
- Level > 0 = copy-trade child nodes (copiers or sub-copiers)
- `ParentOpenCorrelationID IS NULL` for the root; populated for child nodes
- `OpenCorrelationID` is the join key back to `Trade.ExecutedOpenOrders` to determine what was actually opened

**Diagram:**
```
OrderForOpen (OrderID=X)
 └── OpenExecutionPlan rows (Level 0, 1, 2, ...)
       Level 0: CID=A, Units=100, ParentOpenCorrelationID=NULL  (initiator)
       Level 1: CID=B, MirrorID=M1, Units=50                    (copier of A)
       Level 2: CID=C, MirrorID=M2, Units=25                    (copier of B)
```

### 2.2 Native Compilation and SNAPSHOT Isolation

**What:** The SP is marked `WITH NATIVE_COMPILATION, SCHEMABINDING` and executes in `ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT)`, reflecting its role in the high-throughput open-order path.

**Columns/Parameters Involved:** N/A (execution mode metadata)

**Rules:**
- SNAPSHOT isolation means the SELECT sees a consistent point-in-time snapshot - concurrent inserts by `OrderForOpenCreate` will not block this read
- Native compilation eliminates interpreted query processing overhead for this hot path
- `SCHEMABINDING` means schema changes to `Trade.OpenExecutionPlan` require dropping this SP first

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | Input: the open order whose execution plan to retrieve. Must be a valid OrderForOpen.OrderID. All rows with this OrderID are returned. |

**Return Columns (from Trade.OpenExecutionPlan):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | OpenCorrelationID | uniqueidentifier | NO | - | CODE-BACKED | Unique ID for this plan node. The join key to Trade.ExecutedOpenOrders.OpenCorrelationID - used to determine if this node has been executed. |
| R2 | ParentOpenCorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Parent node's OpenCorrelationID. NULL for root (Level 0). Enables reconstruction of the copy-tree hierarchy. |
| R3 | Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units to open for this node. Allocated by the execution plan based on mirror ratio and available credit. |
| R4 | Level | smallint | NO | - | CODE-BACKED | Tree depth: 0=root (initiating customer), 1=direct copier, 2=copier-of-copier. Used to determine execution order. |
| R5 | IsHedged | bit | NO | - | CODE-BACKED | Whether this node has an active hedge. 1=hedged position; affects the execution path taken in the execution engine. |
| R6 | CID | int | NO | - | CODE-BACKED | Customer ID who owns this plan node. The customer for whom a position will be opened at this tree level. |
| R7 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror ID. 0=root/non-copy node; >0=copy node referencing Trade.Mirror. |
| R8 | OpenActionType | tinyint | NO | - | CODE-BACKED | Reason this open was initiated: 0=Manual (customer action), 1=OpenByUnregisterMirror (mirror detach), 2=OpenByBackOffice. Inherited from Dictionary.OrdersExitOpenActionType. |
| R9 | SettlementTypeID | int | NO | - | CODE-BACKED | Settlement type for this node: 0=CFD, 1=REAL (stock ownership), 2=TRS (crypto), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. From Dictionary.SettlementTypes. Determines PnL formula and execution path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OpenExecutionPlan | Direct query | SELECT all rows for the given OrderID |
| @OrderID | Trade.OrderForOpen | Implicit | @OrderID must correspond to an open order |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application code (trading-execution-services) | N/A | CALLER | Called from the pre/post execution service to retrieve plan before processing opens |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenExecutionPlan (procedure)
└── Trade.OpenExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlan | Table | SELECT - retrieves all plan rows for @OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application execution services | External | Calls this SP to fetch the open plan before executing position opens |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Execution Mode:** Native compilation (`WITH NATIVE_COMPILATION, SCHEMABINDING`). Runs in `ATOMIC` block with `TRANSACTION ISOLATION LEVEL = SNAPSHOT`.

---

## 8. Sample Queries

### 8.1 Retrieve execution plan for a specific order
```sql
EXEC Trade.GetOpenExecutionPlan @OrderID = 24207615
```

### 8.2 Check plan vs executed - find unexecuted nodes
```sql
SELECT oep.OpenCorrelationID,
       oep.CID,
       oep.Units,
       oep.Level,
       oep.MirrorID,
       CASE WHEN eo.PositionID IS NULL THEN 'Pending' ELSE 'Executed' END AS ExecutionStatus,
       eo.PositionID
FROM   Trade.OpenExecutionPlan oep WITH (NOLOCK)
       LEFT JOIN Trade.ExecutedOpenOrders eo WITH (NOLOCK)
           ON oep.OrderID = eo.OrderID
           AND oep.OpenCorrelationID = eo.OpenCorrelationID
WHERE  oep.OrderID = 24207615
ORDER  BY oep.Level
```

### 8.3 Reconstruct the copy-tree hierarchy for an order
```sql
SELECT oep.Level,
       oep.CID,
       oep.MirrorID,
       oep.Units,
       oep.SettlementTypeID,
       st.Name AS SettlementType,
       oep.IsHedged,
       oep.OpenCorrelationID,
       oep.ParentOpenCorrelationID
FROM   Trade.OpenExecutionPlan oep WITH (NOLOCK)
       LEFT JOIN Dictionary.SettlementTypes st WITH (NOLOCK)
           ON oep.SettlementTypeID = st.ID
WHERE  oep.OrderID = 24207615
ORDER  BY oep.Level, oep.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenExecutionPlan | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenExecutionPlan.sql*
