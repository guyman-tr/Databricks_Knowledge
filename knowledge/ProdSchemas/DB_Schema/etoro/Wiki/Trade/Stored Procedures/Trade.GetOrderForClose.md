# Trade.GetOrderForClose

> Returns the close order record and associated open position/mirror data for a given OrderID - used during close-order processing to retrieve the full context of what is being closed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForClose` returns two result sets for a given close order: (1) the full `Trade.OrderForClose` row with all 30 order fields, and (2) a cross-reference of the open positions still being held under this order, enriched with their mirror association.

**WHY:** During close-order execution, the execution engine needs the order record itself (what to close, how much, what execution context) AND the current state of the positions still open under that order (to confirm they exist and get their mirror status). The dual-result design supports atomic context loading in a single round trip.

**HOW:** First `SELECT` fetches the OrderForClose row directly. Second `SELECT` joins `Trade.CloseExecutionPlan` -> `Trade.PositionTbl` -> `Trade.Mirror` to return only Level=0 (root) plan nodes for positions still open (StatusID=1).

---

## 2. Business Logic

### 2.1 Close Order Fields

**What:** The first result set returns the complete close order state including execution tracking, error handling, and order classification fields.

**Key fields:**
- `StatusID`: Current processing state of the close order
- `UnitsToDeduct`: Units being removed from the position in this close
- `FilledAmountInUnits`: How much has been filled so far (for partial closes)
- `OrderType`: Type of close (market, limit, stop-triggered, etc.)
- `MirrorCloseActionType`: Why a copy position was closed
- `CustomerFlow`: Whether this was customer-initiated or system-initiated
- `LotsToDeduct`: Lot-based equivalent of UnitsToDeduct

### 2.2 Position Context - Level 0 Root Plan Nodes Only

**What:** The second result set returns only `CloseExecutionPlan.Level = 0` rows - the root-level positions in the close execution tree. This excludes child/hierarchical positions.

**Columns/Parameters Involved:** `CEP.Level`, `TPOS.StatusID`, `MIR.IsActive`

**Rules:**
- `CEP.Level = 0` -> root level only (not child positions in copy-tree execution)
- `TPOS.StatusID = 1` -> position must still be open
- Returns PositionID, MirrorID, and Mirror.IsActive to help the caller know if the copy relationship is still active

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The close order ID to retrieve. References Trade.OrderForClose.OrderID. |

**Result Set 1 - Close Order (from Trade.OrderForClose):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | Close order primary key. |
| R2 | CID | int | NO | CODE-BACKED | Customer who owns the close order. |
| R3 | StatusID | int | NO | CODE-BACKED | Current status of the close order. |
| R4 | PositionID | bigint | YES | CODE-BACKED | Primary position being closed (root position). |
| R5 | UnitsToDeduct | decimal | YES | CODE-BACKED | Units to remove from the position. |
| R6 | FilledAmountInUnits | decimal | YES | CODE-BACKED | Units filled so far (partial fill tracking). |
| R7 | RequestGuid | uniqueidentifier | YES | CODE-BACKED | Idempotency GUID for this close request. |
| R8 | RequestOccurred | datetime | YES | CODE-BACKED | When the close was requested. |
| R9 | LastUpdate | datetime | YES | CODE-BACKED | Last modification timestamp. |
| R10 | OpenOccurred | datetime | YES | CODE-BACKED | When the order was opened/activated. |
| R11 | ErrorCode | int | YES | CODE-BACKED | Error code if close failed. |
| R12 | ErrorMessage | nvarchar | YES | CODE-BACKED | Error description if close failed. |
| R13 | ExecutionID | bigint | YES | CODE-BACKED | Execution batch ID for this close. |
| R14 | ClientViewRateID | bigint | YES | CODE-BACKED | Rate record ID seen by the customer at time of close request. |
| R15 | InstrumentID | int | NO | CODE-BACKED | Instrument being closed. |
| R16 | OrderType | tinyint | YES | CODE-BACKED | Close order type (market, limit, stop, etc.). |
| R17 | AggregatedAmountInUnits | decimal | YES | CODE-BACKED | Total units being closed across all positions in the plan. |
| R18 | DelayedOrderID | bigint | YES | CODE-BACKED | Linked delayed order ID if triggered from a delayed order. |
| R19 | TriggeringOrderID | bigint | YES | CODE-BACKED | Order that triggered this close (e.g., stop-loss trigger). |
| R20 | TriggeringOrderType | tinyint | YES | CODE-BACKED | Type of the triggering order. |
| R21 | CustomerFlow | bit | YES | CODE-BACKED | 1=customer-initiated close, 0=system-initiated. |
| R22 | MirrorCloseActionType | tinyint | YES | CODE-BACKED | Why a copy position was closed (mirror-specific close reason). |
| R23 | LotsToDeduct | decimal | YES | CODE-BACKED | Lot-based equivalent of UnitsToDeduct. |

**Result Set 2 - Open Positions in Close Plan (Level 0 only):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R24 | PositionID | bigint | NO | CODE-BACKED | Position ID of the open position at Level 0 in the close plan. |
| R25 | MirrorID | int | YES | CODE-BACKED | Mirror ID of the position (from PositionTbl). |
| R26 | IsActive | bit | YES | CODE-BACKED | Mirror.IsActive - whether the copy relationship is currently active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForClose | Direct query | Fetch close order row WHERE OrderID = @OrderID |
| @OrderID + Level=0 | Trade.CloseExecutionPlan | Direct query | Get root-level plan entries for this order |
| CloseExecutionPlan.PositionID | Trade.PositionTbl | JOIN | Get position row including MirrorID, StatusID |
| PositionTbl.MirrorID | Trade.Mirror | JOIN | Get mirror IsActive flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close-order execution service | N/A | CALLER | Loads close order context before execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForClose (procedure)
├── Trade.OrderForClose (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.PositionTbl (table)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table | SELECT close order row by OrderID |
| Trade.CloseExecutionPlan | Table | JOIN to get Level=0 plan positions |
| Trade.PositionTbl | Table | JOIN to get MirrorID + StatusID=1 filter |
| Trade.Mirror | Table | JOIN to get IsActive flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close-order execution service | External | Loads two-result-set close context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** All tables use `WITH (NOLOCK)`. The two-result-set design is intentional - callers consume result set 1 for order state and result set 2 for position context.

---

## 8. Sample Queries

### 8.1 Get close order and position context
```sql
EXEC Trade.GetOrderForClose @OrderID = 987654321
```

### 8.2 Manual equivalent - result set 1
```sql
SELECT OrderID, CID, StatusID, PositionID, UnitsToDeduct, FilledAmountInUnits,
       RequestGuid, RequestOccurred, LastUpdate, OpenOccurred, ErrorCode,
       ErrorMessage, ExecutionID, ClientViewRateID, InstrumentID, OrderType,
       AggregatedAmountInUnits, DelayedOrderID, TriggeringOrderID,
       TriggeringOrderType, CustomerFlow, MirrorCloseActionType, LotsToDeduct
FROM   Trade.OrderForClose WITH (NOLOCK)
WHERE  OrderID = 987654321
```

### 8.3 Manual equivalent - result set 2 (open positions in plan)
```sql
SELECT CEP.PositionID, TPOS.MirrorID, MIR.IsActive
FROM   Trade.CloseExecutionPlan CEP WITH (NOLOCK)
       JOIN Trade.PositionTbl TPOS WITH (NOLOCK) ON TPOS.PositionID = CEP.PositionID
       JOIN Trade.Mirror MIR WITH (NOLOCK) ON TPOS.MirrorID = MIR.MirrorID
WHERE  CEP.OrderID = 987654321 AND CEP.Level = 0 AND TPOS.StatusID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForClose.sql*
