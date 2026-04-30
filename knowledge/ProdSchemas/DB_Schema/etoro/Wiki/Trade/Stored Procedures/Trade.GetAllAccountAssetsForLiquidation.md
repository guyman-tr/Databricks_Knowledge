# Trade.GetAllAccountAssetsForLiquidation

> Returns a customer's positions split into liquidatable and non-liquidatable lists, plus pending close orders and mirrors.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Four result sets: liquidatable positions, non-liquidatable positions, pending close orders, mirrors |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a simplified version of Trade.GetAccountAssetsForLiquidation. It retrieves a customer's open manual positions, classifies them as liquidatable or non-liquidatable based on instrument type and settlement rules, and also returns pending close execution plans and mirror (copy trading) relationships.

The key difference from GetAccountAssetsForLiquidation is that this procedure returns fewer result sets (4 instead of 7) and only includes the essential data needed for the liquidation engine - PositionID and InstrumentID for positions, rather than full position details. This makes it more efficient for scenarios where the caller only needs to know which positions can be closed, not the full position state.

Non-liquidatable positions are identified by matching the position's instrument type and settlement type against rules in `Trade.NonLiquidatablePositionRules`. Copy positions (MirrorID > 0) are excluded from liquidation entirely.

---

## 2. Business Logic

### 2.1 Position Classification

**What**: Classifies open manual positions as liquidatable or non-liquidatable.

**Columns/Parameters Involved**: `Trade.PositionTbl.InstrumentID`, `Trade.InstrumentMetaData.InstrumentTypeID`, `Trade.PositionTbl.SettlementTypeID`, `Trade.NonLiquidatablePositionRules`

**Rules**:
- Only open positions (`StatusID = 1`) for the given customer are considered
- Only manual positions (`MirrorID = 0`) are included - copy positions are excluded
- A position is non-liquidatable if its InstrumentTypeID + SettlementTypeID combination exists in `Trade.NonLiquidatablePositionRules`
- Liquidatable positions are returned in Result Set 1; non-liquidatable in Result Set 2

### 2.2 Pending Close Orders

**What**: Returns positions that have pending close orders waiting for market.

**Columns/Parameters Involved**: `Trade.OrderForClose`, `Trade.CloseExecutionPlan`

**Rules**:
- Joins OrderForClose to CloseExecutionPlan at Level = 0 (top-level plan)
- Filters to StatusID = 11 (WaitingForMarket)
- Only returns PositionID - the liquidation engine needs to know which positions already have pending closes

### 2.3 Mirror Relationships

**What**: Returns all copy trading mirrors for the customer.

**Columns/Parameters Involved**: `Trade.Mirror.MirrorID`, `Trade.Mirror.IsActive`

**Rules**:
- Returns both active and inactive mirrors
- The liquidation engine may need to stop copies before liquidating

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose assets to retrieve for liquidation. |

### Result Set 1 - Liquidatable Positions

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | PositionID | INT | CODE-BACKED | Position eligible for liquidation. |
| 2 | InstrumentID | INT | CODE-BACKED | Instrument the position is in. |

### Result Set 2 - Non-Liquidatable Positions

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | PositionID | INT | CODE-BACKED | Position protected from liquidation. |
| 2 | InstrumentID | INT | CODE-BACKED | Instrument the position is in. |

### Result Set 3 - Pending Close Orders

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | PositionID | INT | CODE-BACKED | Position with a pending close order (WaitingForMarket). |

### Result Set 4 - Mirrors

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | MirrorID | INT | CODE-BACKED | Copy trading mirror relationship ID. |
| 2 | IsActive | BIT | CODE-BACKED | Whether the mirror is currently active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | Direct Read | Source of open positions |
| JOIN | Trade.InstrumentMetaData | Lookup | Instrument type for classification |
| LEFT JOIN | Trade.NonLiquidatablePositionRules | Classification | Rules defining non-liquidatable combinations |
| JOIN | Trade.OrderForClose | Direct Read | Pending close orders |
| JOIN | Trade.CloseExecutionPlan | Lookup | Close execution plan details |
| FROM | Trade.Mirror | Direct Read | Copy trading relationships |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllAccountAssetsForLiquidation (procedure)
├── Trade.PositionTbl (table)
├── Trade.InstrumentMetaData (table)
├── Trade.NonLiquidatablePositionRules (table)
├── Trade.OrderForClose (table)
├── Trade.CloseExecutionPlan (table)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open positions source |
| Trade.InstrumentMetaData | Table | Instrument type lookup |
| Trade.NonLiquidatablePositionRules | Table | Liquidation eligibility rules |
| Trade.OrderForClose | Table | Pending close orders |
| Trade.CloseExecutionPlan | Table | Close execution plan level check |
| Trade.Mirror | Table | Copy trading mirrors |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get liquidation assets for a customer

```sql
EXEC Trade.GetAllAccountAssetsForLiquidation @CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllAccountAssetsForLiquidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllAccountAssetsForLiquidation.sql*
