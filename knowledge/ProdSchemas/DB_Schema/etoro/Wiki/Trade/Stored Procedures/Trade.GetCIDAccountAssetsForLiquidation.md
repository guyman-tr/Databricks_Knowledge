# Trade.GetCIDAccountAssetsForLiquidation

> Retrieves a complete breakdown of a customer's account assets for the margin call liquidation process - categorizing positions as liquidatable vs non-liquidatable, plus pending orders and mirrors.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 5 result sets: liquidatable positions, non-liquidatable positions, pending close orders, open rate orders, and mirrors |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the margin call liquidation engine for a specific customer. When a customer's equity falls below the maintenance margin requirement, the system must determine which assets can be liquidated and in what order. This procedure provides the full picture: which positions can be force-closed (liquidatable), which cannot (non-liquidatable due to regulatory rules), what close orders are already pending, what open rate orders exist that should be cancelled, and what copy trading mirrors are active.

The procedure exists because liquidation is a critical risk management process with regulatory constraints. Not all positions can be force-closed - real stock positions in certain instrument types may be exempt from automated liquidation (as defined in `Trade.NonLiquidatablePositionRules`). The liquidation engine needs this categorized view to make correct decisions.

Data flows from `Trade.PositionTbl` (open positions) joined to `Trade.InstrumentMetaData` (instrument type) and `Trade.NonLiquidatablePositionRules` (liquidation exemption rules). Additional result sets come from `Trade.OrderForClose` + `Trade.CloseExecutionPlan` (pending closes), `Trade.Orders` (rate orders), `Trade.Mirror` (copy mirrors), and `Trade.OrderForOpen` (pending market orders). Only manual positions (MirrorID = 0) are evaluated for liquidation.

---

## 2. Business Logic

### 2.1 Liquidatability Classification

**What**: Categorizes each open position as liquidatable or non-liquidatable based on instrument type and settlement type rules.

**Columns/Parameters Involved**: `InstrumentTypeID`, `SettlementTypeID`, `NonLiquidatablePositionRules`

**Rules**:
- Position JOINed to InstrumentMetaData for InstrumentTypeID
- LEFT JOIN to NonLiquidatablePositionRules on InstrumentTypeID + SettlementTypeID
- If match found (NLPR.InstrumentTypeID IS NOT NULL) -> IsNonLiquidatable = 1 (protected from forced close)
- If no match -> IsNonLiquidatable = 0 (can be force-closed)
- Only manual positions are evaluated: `WHERE MirrorID = 0`

**Diagram**:
```
Open Positions (StatusID=1, MirrorID=0)
       |
       v
JOIN InstrumentMetaData -> InstrumentTypeID
       |
       v
LEFT JOIN NonLiquidatablePositionRules
       |
       +-- Match found -----> Non-liquidatable (result set 2)
       |
       +-- No match --------> Liquidatable (result set 1)
```

### 2.2 Multi-Result Set Architecture

**What**: Returns 5 separate result sets for different asset categories.

**Rules**:
- Result Set 1: Liquidatable positions (PositionID, InstrumentID) - can be force-closed
- Result Set 2: Non-liquidatable positions (PositionID, InstrumentID) - cannot be force-closed
- Result Set 3: Positions already in close queue (from OrderForClose + CloseExecutionPlan, Level=0, StatusID=11=WaitingForMarket)
- Result Set 4: Open rate orders (from Trade.Orders) - should be cancelled during liquidation
- Result Set 5: Active mirrors (MirrorID, IsActive) - may need to be paused or detached
- Result Set 6: Pending market orders (from OrderForOpen, StatusID=11=WaitingForMarket, MirrorID=0) - manual entry orders to cancel

### 2.3 Waiting For Market Status

**What**: Identifies orders that are waiting for market conditions to execute.

**Columns/Parameters Involved**: `StatusID`, `@waitingForMarket`

**Rules**:
- `@waitingForMarket = 11` - hardcoded status for orders awaiting market open/conditions
- Used to filter OrderForClose and OrderForOpen to only pending (not yet executed) orders
- These orders should be considered during liquidation - either let them execute or cancel them

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to evaluate for liquidation. All queries are scoped to this customer. |

Result Set 1 - Liquidatable Positions:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Position that CAN be force-closed during margin call liquidation. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the liquidatable position. Needed by the close engine. |

Result Set 2 - Non-Liquidatable Positions:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Position that CANNOT be force-closed due to NonLiquidatablePositionRules. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the protected position. |

Result Set 3 - Pending Close Orders:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Position with a pending close order at execution plan Level=0 waiting for market. |

Result Set 4 - Open Rate Orders:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | OrderID | BIGINT | NO | - | CODE-BACKED | Rate order (limit/stop) that should be cancelled during liquidation. |

Result Set 5 - Mirrors:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | MirrorID | INT | NO | - | CODE-BACKED | Copy trading mirror relationship ID. |
| 9 | IsActive | BIT | NO | - | CODE-BACKED | Whether the mirror is currently active. Active mirrors may need pausing during liquidation. |

Result Set 6 - Pending Manual Market Orders:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 10 | OrderID | BIGINT | NO | - | CODE-BACKED | Manual entry market order awaiting execution. Should be cancelled during liquidation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.PositionTbl | SELECT FROM | Open positions for liquidation evaluation |
| (body) | Trade.InstrumentMetaData | INNER JOIN | Instrument type for liquidation rule matching |
| (body) | Trade.NonLiquidatablePositionRules | LEFT JOIN | Liquidation exemption rules by instrument type + settlement type |
| (body) | Trade.OrderForClose | INNER JOIN | Pending close orders |
| (body) | Trade.CloseExecutionPlan | INNER JOIN | Close execution plan (Level=0) |
| (body) | Trade.Orders | SELECT FROM | Open rate orders for the customer |
| (body) | Trade.Mirror | SELECT FROM | Copy trading mirrors |
| (body) | Trade.OrderForOpen | SELECT FROM | Pending market orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCIDAccountAssetsForLiquidation (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.NonLiquidatablePositionRules (table)
+-- Trade.OrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.Orders (table)
+-- Trade.Mirror (table)
+-- Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT FROM - open position data |
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument type classification |
| Trade.NonLiquidatablePositionRules | Table | LEFT JOIN - liquidation exemption rules |
| Trade.OrderForClose | Table | INNER JOIN - pending close orders |
| Trade.CloseExecutionPlan | Table | INNER JOIN - close execution plans |
| Trade.Orders | Table | SELECT FROM - open rate orders |
| Trade.Mirror | Table | SELECT FROM - copy mirrors |
| Trade.OrderForOpen | Table | SELECT FROM - pending market orders |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get liquidation assets for a customer
```sql
EXEC Trade.GetCIDAccountAssetsForLiquidation @CID = 12345;
```

### 8.2 Check non-liquidatable rules
```sql
SELECT  InstrumentTypeID, SettlementTypeID
FROM    Trade.NonLiquidatablePositionRules WITH (NOLOCK);
```

### 8.3 Find customers with open positions and pending orders
```sql
SELECT  DISTINCT p.CID
FROM    Trade.PositionTbl p WITH (NOLOCK)
WHERE   p.StatusID = 1 AND p.MirrorID = 0
        AND EXISTS (SELECT 1 FROM Trade.Orders o WITH (NOLOCK) WHERE o.CID = p.CID);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.6/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCIDAccountAssetsForLiquidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCIDAccountAssetsForLiquidation.sql*
