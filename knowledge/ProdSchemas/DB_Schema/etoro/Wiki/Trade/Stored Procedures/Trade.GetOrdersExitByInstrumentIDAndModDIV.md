# Trade.GetOrdersExitByInstrumentIDAndModDIV

> Returns pending exit orders for a single instrument with modulo-based sharding - the single-instrument predecessor to the TVP-based OME exit order matching SP (GetOrderMatchingItemsByInstrumentID_ExitOrders).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT + @ModDivider INT + @ModResult INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersExitByInstrumentIDAndModDIV` retrieves pending exit orders from `Trade.OrdersExit` for a single instrument, filtered by modulo sharding. It is the exit-order counterpart to `GetOrdersEntryByInstrumentIDAndModDIV` and `GetOrdersByInstrumentIDAndModDIV`, and the single-instrument predecessor to `GetOrderMatchingItemsByInstrumentID_ExitOrders` (TVP-based).

**WHY:** Used by older OME instances that retrieve exit orders per-instrument rather than in instrument batches (TVP). The modulo sharding distributes exit order processing across multiple OME instances to avoid duplicate processing.

**HOW:** SELECT from Trade.OrdersExit INNER JOIN Trade.Position to get InstrumentID and CID (not stored in Trade.OrdersExit directly). Filters by InstrumentID (from Position) and modulo shard of OrderID.

---

## 2. Business Logic

### 2.1 Modulo Sharding for OME Exit Order Processing

**What:** Same modulo sharding pattern as the entry and standard order counterparts. Each OME instance handles a subset of OrderIDs.

**Columns/Parameters Involved:** `@ModDivider`, `@ModResult`

**Rules:**
- `WHERE o.OrderID % @ModDivider = @ModResult` -> this OME shard's exit orders for this instrument
- Ensures no two OME instances process the same exit order

### 2.2 Position Join Required - InstrumentID Not in OrdersExit

**What:** Trade.OrdersExit does not store InstrumentID or CID directly. These must be retrieved via JOIN to Trade.Position using PositionID.

**Columns/Parameters Involved:** `PositionID`

**Rules:**
- `INNER JOIN Trade.Position p ON o.PositionID = p.PositionID` -> required for InstrumentID and CID
- `WHERE InstrumentID = @InstrumentID` -> filters against Position.InstrumentID (not OrdersExit)
- Only exit orders with a corresponding open position are returned (INNER JOIN - orphaned exit orders excluded)

### 2.3 Minimal Column Set for OME

**What:** Returns only the columns the OME needs to process an exit order. No amount, leverage, or stop/take-profit data needed for exit order matching.

**Rules:**
- 5 output columns: OrderID, InstrumentID, CID, PositionID, OpenActionType
- InstrumentID and CID sourced from Trade.Position (not Trade.OrdersExit)
- OpenActionType from Trade.OrdersExit - the action type that opened the position being closed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Single instrument to retrieve exit orders for. Matched against Trade.Position.InstrumentID. |
| 2 | @ModDivider | INT | NO | - | CODE-BACKED | Total number of OME shards for modulo partitioning. |
| 3 | @ModResult | INT | NO | - | CODE-BACKED | This OME shard's remainder value. |

**Output columns (from Trade.OrdersExit INNER JOIN Trade.Position):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Exit order ID. Sourced from Trade.OrdersExit. Used for modulo shard filter. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position being closed. Sourced from Trade.Position (not stored in Trade.OrdersExit). |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. Sourced from Trade.Position. |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | The open position being closed by this exit order. From Trade.OrdersExit.PositionID. |
| 5 | OpenActionType | INT | YES | - | CODE-BACKED | The action type that originally opened the position. From Trade.OrdersExit. Determines exit processing path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersExit | Trade.OrdersExit | Lookup | Source of pending exit orders |
| INNER JOIN Trade.Position | Trade.Position | Enrichment | Provides InstrumentID and CID (not stored in OrdersExit) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersExitByInstrumentIDAndModDIV (procedure)
|- Trade.OrdersExit (table) - pending exit orders
|- Trade.Position (view) - provides InstrumentID and CID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | Source of pending exit orders with modulo shard filter |
| Trade.Position | View | Provides InstrumentID and CID for the associated open position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by older OME application code for single-instrument exit order matching |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN Trade.Position | Data requirement | Excludes exit orders with no open position (INNER - not LEFT JOIN) |
| SET NOCOUNT ON | Session setting | Suppresses row count messages |
| WHERE InstrumentID = @InstrumentID | Filter | Filters on Position.InstrumentID, not OrdersExit |

---

## 8. Sample Queries

### 8.1 Execute for Bitcoin, OME shard 0 of 4

```sql
EXEC Trade.GetOrdersExitByInstrumentIDAndModDIV
    @InstrumentID = 1,
    @ModDivider = 4,
    @ModResult = 0
```

### 8.2 View pending exit orders for an instrument

```sql
SELECT oe.OrderID, p.InstrumentID, p.CID, oe.PositionID, oe.OpenActionType
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON oe.PositionID = p.PositionID
WHERE p.InstrumentID = 1
```

### 8.3 Modulo shard preview

```sql
SELECT oe.OrderID, p.InstrumentID, p.CID, oe.PositionID
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON oe.PositionID = p.PositionID
WHERE p.InstrumentID = 1 AND oe.OrderID % 4 = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 6.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersExitByInstrumentIDAndModDIV | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersExitByInstrumentIDAndModDIV.sql*
