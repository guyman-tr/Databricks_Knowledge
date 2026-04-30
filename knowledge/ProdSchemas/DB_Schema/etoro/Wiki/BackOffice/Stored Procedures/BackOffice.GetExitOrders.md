# BackOffice.GetExitOrders

> Returns all exit (position-close) orders for a customer - both completed synchronous orders from Trade.OrdersExit and pending WAITING_FOR_MARKET async close orders from Trade.OrderForClose via CloseExecutionPlan - with IsAsync flag to distinguish source.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CID lookup; returns UNION of Trade.OrdersExit + Trade.OrderForClose (StatusID=11, Level=0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetExitOrders is the position-close (exit) order history procedure, the symmetric counterpart of BackOffice.GetEntryOrders. It provides BackOffice staff with a complete view of a customer's position-close orders: orders that have already been processed synchronously (from Trade.OrdersExit) and orders still waiting for market conditions before closing (WAITING_FOR_MARKET async orders from Trade.OrderForClose).

The async close path is more complex than the async open path: a close order in Trade.OrderForClose is linked to a position via Trade.CloseExecutionPlan (CEP), with `Level=0` selecting only the root execution plan entry (the actual position to close, not any sub-plan levels). The position partition-aware join (`PositionPartitionCol = PositionID % 50`) is required because Trade.Position uses partitioning.

---

## 2. Business Logic

### 2.1 UNION of Two Close Order Tables

**What**: Combines completed synchronous exit orders with pending WAITING_FOR_MARKET async close orders.

**Columns/Parameters Involved**: `Trade.OrdersExit`, `Trade.OrderForClose`, `Trade.CloseExecutionPlan`, `StatusID=11`, `Level=0`, `IsAsync`

**Rules**:
- **Set 1 (IsAsync=0)**: All rows from `Trade.OrdersExit` for the customer. Completed synchronous close orders. InstrumentID and MirrorID are resolved from `Trade.Position` via LEFT JOIN on PositionID.
- **Set 2 (IsAsync=1)**: Rows from `Trade.OrderForClose` WHERE `StatusID=11` (WAITING_FOR_MARKET) AND `CID=@CID`. INNER JOIN to `Trade.CloseExecutionPlan` WHERE `Level=0` filters to root-level execution plan entries only (excludes sub-plan entries for complex multi-position close operations).
- The async path uses INNER JOIN to CloseExecutionPlan (unlike the sync path which uses LEFT JOIN to Position directly) - every async close order must have a CloseExecutionPlan entry to appear.
- Position is LEFT JOINed with partition awareness: `TPP.PositionPartitionCol = CEP.PositionID % 50` - required because Trade.Position is partitioned and the join must align the partition column.

### 2.2 Partition-Aware Position Join

**What**: The async path joins Trade.Position using both PositionID and the partition column.

**Rules**:
- `Trade.Position.PositionPartitionCol = PositionID % 50` is a modulo-50 partitioning scheme
- Without the partition column in the JOIN predicate, SQL Server may scan all partitions; with it, partition elimination limits the scan to one partition
- This join pattern only appears in Set 2 (async); Set 1 uses a simple LEFT JOIN on PositionID alone (sufficient for the sync OrdersExit path where partition scan cost is acceptable or positions are accessed differently)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID whose exit orders are to be retrieved. Filters both Trade.OrdersExit and Trade.OrderForClose. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | OrderID | bigint | NO | - | CODE-BACKED | Unique order identifier. From Trade.OrdersExit.OrderID or Trade.OrderForClose.OrderID. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID. Always equals @CID. |
| R3 | InstrumentID | int | YES | - | CODE-BACKED | The financial instrument of the position being closed. Resolved from Trade.Position.InstrumentID via LEFT JOIN. NULL if the position is no longer in Trade.Position (rare for archived positions). |
| R4 | InstrumentDisplayName | nvarchar | YES | - | CODE-BACKED | Human-readable instrument name. From Trade.InstrumentMetaData via LEFT JOIN on InstrumentID. NULL if InstrumentID is NULL or instrument not in metadata. |
| R5 | PositionID | bigint | YES | - | CODE-BACKED | The position being closed. From Trade.OrdersExit.PositionID (Set 1) or Trade.CloseExecutionPlan.PositionID (Set 2). |
| R6 | OpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp of the order event. From Trade.OrdersExit.OpenOccurred or Trade.OrderForClose.OpenOccurred. |
| R7 | MirrorID | int | YES | - | CODE-BACKED | For CopyTrader positions: the mirror relationship ID. From Trade.Position.MirrorID. NULL for manually traded positions. |
| R8 | IsAsync | bit | NO | - | CODE-BACKED | Source indicator. 0 = order came from Trade.OrdersExit (synchronous/completed). 1 = order came from Trade.OrderForClose with StatusID=11 (WAITING_FOR_MARKET async pending). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TOEx (first) | Trade.OrdersExit | SELECT | Completed synchronous exit orders for the customer |
| TOEx (second) | Trade.OrderForClose | SELECT | Pending WAITING_FOR_MARKET async close orders (StatusID=11) |
| CEP | Trade.CloseExecutionPlan | INNER JOIN | Execution plan for async close orders; Level=0 selects root entries |
| TPP | Trade.Position | LEFT JOIN | Provides InstrumentID, MirrorID; partition-aware join in async path |
| TIMD | Trade.InstrumentMetaData | LEFT JOIN | Provides InstrumentDisplayName |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from BackOffice UI to display a customer's exit order history for operations staff.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetExitOrders (procedure)
├── Trade.OrdersExit (table - cross-schema)
├── Trade.OrderForClose (table - cross-schema)
├── Trade.CloseExecutionPlan (table - cross-schema)
├── Trade.Position (table - cross-schema)
└── Trade.InstrumentMetaData (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | SET 1 - completed synchronous exit orders for @CID |
| Trade.OrderForClose | Table | SET 2 - pending WAITING_FOR_MARKET close orders (StatusID=11) for @CID |
| Trade.CloseExecutionPlan | Table | INNER JOIN (SET 2) - resolves OrderForClose to PositionID; Level=0 filters to root entries only |
| Trade.Position | Table | LEFT JOIN (both sets) - resolves PositionID to InstrumentID and MirrorID; partition-aware in SET 2 |
| Trade.InstrumentMetaData | Table | LEFT JOIN (both sets) - provides InstrumentDisplayName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice UI | External | READER - displays exit order history for a customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. SET NOCOUNT ON is present. The partition-aware join `TPP.PositionPartitionCol = CEP.PositionID % 50` enables partition elimination on Trade.Position, critical for performance given Trade.Position's size.

### 7.2 Constraints

N/A for Stored Procedure. Notable: unlike GetEntryOrders which uses INNER JOIN to InstrumentMetaData, GetExitOrders uses LEFT JOIN - allowing the procedure to return close orders even when the position's instrument metadata is unavailable (e.g., delisted instruments).

---

## 8. Sample Queries

### 8.1 Get all exit orders for a customer
```sql
EXEC BackOffice.GetExitOrders @CID = 12345
-- Returns: OrderID, CID, InstrumentID, InstrumentDisplayName, PositionID,
--          OpenOccurred, MirrorID, IsAsync
```

### 8.2 Ad-hoc: pending async close orders for a customer
```sql
SELECT
    tof.OrderID, tof.CID, cep.PositionID, tof.OpenOccurred,
    tpp.InstrumentID, timd.InstrumentDisplayName, tpp.MirrorID,
    1 AS IsAsync
FROM Trade.OrderForClose tof WITH (NOLOCK)
INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK) ON cep.OrderID = tof.OrderID
LEFT JOIN Trade.Position tpp WITH (NOLOCK)
    ON tpp.PositionID = cep.PositionID
    AND tpp.PositionPartitionCol = cep.PositionID % 50
LEFT JOIN Trade.InstrumentMetaData timd WITH (NOLOCK) ON timd.InstrumentID = tpp.InstrumentID
WHERE cep.Level = 0
  AND tof.StatusID = 11
  AND tof.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetExitOrders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetExitOrders.sql*
