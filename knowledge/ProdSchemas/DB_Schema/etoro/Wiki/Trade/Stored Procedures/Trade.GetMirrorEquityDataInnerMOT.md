# Trade.GetMirrorEquityDataInnerMOT

> Natively compiled (memory-optimized) inner procedure that returns active open and close orders for a mirror-CID pair, used as part of the equity calculation pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure (Natively Compiled) |
| **Key Identifier** | Returns: 2 result sets (open orders + close orders with execution plans) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorEquityDataInnerMOT is a natively compiled (memory-optimized table) procedure that retrieves active orders for a specific mirror-CID pair. It returns two result sets: (1) non-terminal orders-for-open with their instrument/leverage/amount details, and (2) non-terminal orders-for-close with their position-level execution plans.

This procedure exists as a performance-critical inner component of the mirror equity calculation pipeline. It is called by Trade.GetMirrorEquityData and benefits from native compilation for fast, lock-free reads from memory-optimized tables. The SNAPSHOT isolation and SCHEMABINDING ensure consistent reads without blocking.

The "MOT" suffix indicates Memory-Optimized Table compatibility. The ATOMIC block with SNAPSHOT isolation is required for natively compiled procedures.

---

## 2. Business Logic

### 2.1 Active Open Orders

**What**: Returns non-terminal open orders for this mirror-CID pair with core financial details.

**Columns/Parameters Involved**: `@CID`, `@MirrorID`, `Trade.OrderForOpen`, `Dictionary.OrderForExecutionStatus`

**Rules**:
- Joins to Dictionary.OrderForExecutionStatus to filter on IsTerminal=0 (active orders only)
- Returns instrument, leverage, amount, direction, and order type for equity impact calculation
- StatusID and RequestGuid included for order lifecycle tracking

### 2.2 Active Close Orders with Execution Plans

**What**: Returns non-terminal close orders with their position-level execution plans.

**Columns/Parameters Involved**: `Trade.OrderForClose`, `Trade.CloseExecutionPlan`

**Rules**:
- Joins OrderForClose to CloseExecutionPlan to get PositionID per close order
- Filters on IsTerminal=0 for active orders only
- UnitsToDeduct indicates how many units will be closed (partial or full)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @CID | int | IN | - | CODE-BACKED | Customer ID to filter orders for. |
| 2 | @MirrorID | int | IN | - | CODE-BACKED | Mirror ID to filter open orders for. Close orders filtered by CID only (all mirrors). |

### 4.2 Result Set 1 (Active Open Orders)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | OrderID | bigint | NO | CODE-BACKED | Open order identifier. |
| 2 | InstrumentID | int | YES | CODE-BACKED | Instrument for this order. |
| 3 | Leverage | int | YES | CODE-BACKED | Leverage multiplier. |
| 4 | Amount | money | YES | CODE-BACKED | Order amount in dollars. |
| 5 | IsBuy | bit | YES | CODE-BACKED | 1=Buy/Long, 0=Sell/Short. |
| 6 | ParentPositionID | bigint | YES | CODE-BACKED | Parent position for copy trades. |
| 7 | AmountInUnits | decimal | YES | CODE-BACKED | Order amount in instrument units. |
| 8 | OrderTypeID | int | YES | CODE-BACKED | Order type (aliased from OrderType). |
| 9 | IsDiscounted | bit | YES | CODE-BACKED | Legacy discount flag (marked for removal). |
| 10 | StatusID | int | YES | CODE-BACKED | Current order execution status. |
| 11 | RequestGuid | uniqueidentifier | YES | CODE-BACKED | Request correlation GUID. |

### 4.3 Result Set 2 (Active Close Orders)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | OrderID | bigint | NO | CODE-BACKED | Close order identifier. |
| 2 | PositionID | bigint | YES | CODE-BACKED | Position being closed (from CloseExecutionPlan). |
| 3 | UnitsToDeduct | decimal | YES | CODE-BACKED | Units to close (partial or full). |
| 4 | StatusID | int | YES | CODE-BACKED | Current close order status. |
| 5 | RequestGuid | uniqueidentifier | YES | CODE-BACKED | Request correlation GUID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.OrderForOpen | SELECT (READER) | Active open orders for this mirror |
| FROM | Trade.OrderForClose | SELECT (READER) | Active close orders for this CID |
| JOIN | Trade.CloseExecutionPlan | SELECT (READER) | Maps close orders to positions |
| JOIN | Dictionary.OrderForExecutionStatus | SELECT (READER) | Filters non-terminal orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMirrorEquityData | EXEC | Stored Procedure | Called as inner procedure for equity calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorEquityDataInnerMOT (procedure)
+-- Trade.OrderForOpen (table)
+-- Trade.OrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
+-- Dictionary.OrderForExecutionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | Active open orders |
| Trade.OrderForClose | Table | Active close orders |
| Trade.CloseExecutionPlan | Table | Close order position mapping |
| Dictionary.OrderForExecutionStatus | Table | Terminal status filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMirrorEquityData | Stored Procedure | Calls this as inner MOT procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Natively compiled with SCHEMABINDING. ATOMIC block with SNAPSHOT isolation. EXECUTE AS OWNER.

---

## 8. Sample Queries

### 8.1 Call via parent procedure

```sql
EXEC Trade.GetMirrorEquityData @CID = 67890, @MirrorID = 12345;
```

### 8.2 Direct call (for debugging)

```sql
EXEC Trade.GetMirrorEquityDataInnerMOT @CID = 67890, @MirrorID = 12345;
```

### 8.3 Check active orders for a mirror

```sql
SELECT  ofo.OrderID, ofo.InstrumentID, ofo.Amount, ofo.StatusID
FROM    Trade.OrderForOpen ofo WITH (NOLOCK)
        JOIN Dictionary.OrderForExecutionStatus ofs WITH (NOLOCK) ON ofo.StatusID = ofs.ID
WHERE   ofo.CID = 67890
        AND ofo.MirrorID = 12345
        AND ofs.IsTerminal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorEquityDataInnerMOT | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorEquityDataInnerMOT.sql*
