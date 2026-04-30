# Trade.GetAccountAssetsForLiquidation

> Returns a customer's trading assets split into liquidatable and non-liquidatable positions for margin call liquidation processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 7 result sets: liquidatable positions, non-liquidatable positions, exit orders, entry orders, orders, mirrors, async orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the liquidation-specific variant of Trade.GetAccountAssets. It retrieves all trading assets for a customer during a margin call liquidation event, with the critical addition of splitting positions into "liquidatable" and "non-liquidatable" categories. Non-liquidatable positions are determined by instrument type and settlement type rules defined in Trade.NonLiquidatablePositionRules.

The procedure exists to support the margin call engine. When a customer's equity falls below the maintenance margin, the system must decide which positions to close to restore the account to health. Some positions are protected from automatic liquidation based on regulatory or business rules (e.g., certain real stock positions may not be auto-liquidated). This procedure provides the categorized data needed for that decision.

Data flows from Trade.PositionTbl (direct table access, not the view) joined with Trade.InstrumentMetaData to get the instrument type, and Trade.NonLiquidatablePositionRules to classify positions. Only manual positions (MirrorID=0) with StatusID=1 (Open) are considered. The remaining result sets (exit orders, entry orders, etc.) are identical to Trade.GetAccountAssets but without the Trade.OrdersExit regular path (commented out, only async).

---

## 2. Business Logic

### 2.1 Liquidation Eligibility Classification

**What**: Positions are classified as liquidatable or non-liquidatable based on instrument type and settlement type rules.

**Columns/Parameters Involved**: `InstrumentTypeID`, `SettlementTypeID`, `Trade.NonLiquidatablePositionRules`

**Rules**:
- A position is non-liquidatable (IsNonLiquidatable=1) if its InstrumentTypeID AND SettlementTypeID combination exists in Trade.NonLiquidatablePositionRules
- Uses LEFT JOIN + IS NOT NULL check: if NLPR.InstrumentTypeID IS NOT NULL, the position matches a non-liquidation rule
- Only manual positions (MirrorID=0) with StatusID=1 (Open) are evaluated
- InstrumentTypeID is resolved via Trade.InstrumentMetaData join on InstrumentID

**Diagram**:
```
Trade.PositionTbl (Open, Manual)
         |
   JOIN InstrumentMetaData
         |
   LEFT JOIN NonLiquidatablePositionRules
     ON InstrumentTypeID + SettlementTypeID
         |
    Match found?
    /          \
  YES           NO
   |             |
 Non-liquidatable  Liquidatable
 (Result Set 2)    (Result Set 1)
```

### 2.2 Disabled OrdersExit Path

**What**: The regular Trade.OrdersExit query is commented out, leaving only the async path.

**Columns/Parameters Involved**: `Trade.OrdersExit`, `Trade.OrderForClose`

**Rules**:
- The standard OrdersExit SELECT is commented out (only async close orders via OrderForClose remain)
- Similarly, Trade.OrdersEntry SELECT has `AND 1=0` appended, effectively returning zero rows
- These may be intentional optimizations or temporary changes specific to the liquidation workflow

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID undergoing liquidation evaluation. |

**Result Set 1 - Liquidatable Manual Positions:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Open manual position eligible for liquidation. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the liquidatable position. |

**Result Set 2 - Non-Liquidatable Manual Positions:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Open manual position protected from liquidation by NonLiquidatablePositionRules. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the non-liquidatable position. |

**Result Set 3 - Async Close Orders:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Position with a pending async close order (waiting for market). |

**Result Set 4 - Manual Entry Orders (disabled):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | OrderID | BIGINT | NO | - | CODE-BACKED | Manual entry orders. Currently returns empty set (AND 1=0 filter). |

**Result Set 5 - All Orders:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | OrderID | BIGINT | NO | - | CODE-BACKED | All orders for the customer from Trade.Orders. |

**Result Set 6 - Mirrors:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 9 | MirrorID | BIGINT | NO | - | CODE-BACKED | CopyTrader mirror relationship ID. |
| 10 | IsActive | BIT | NO | - | CODE-BACKED | Whether the mirror (copy) relationship is active. |

**Result Set 7 - Async Entry Orders:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | OrderID | BIGINT | NO | - | CODE-BACKED | Async manual entry order waiting for market (StatusID=11). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | Direct Read | Reads open manual positions for liquidation classification |
| INNER JOIN | Trade.InstrumentMetaData | Lookup | Resolves InstrumentTypeID for liquidation rule matching |
| LEFT JOIN | Trade.NonLiquidatablePositionRules | Lookup | Determines which positions are protected from liquidation |
| INNER JOIN | Trade.OrderForClose | Direct Read | Reads async close orders |
| INNER JOIN | Trade.CloseExecutionPlan | Direct Read | Reads close execution plan entries |
| FROM | Trade.OrdersEntry | Direct Read | Manual entry orders (currently disabled via 1=0) |
| FROM | Trade.Orders | Direct Read | All customer orders |
| FROM | Trade.Mirror | Direct Read | CopyTrader mirrors |
| FROM | Trade.OrderForOpen | Direct Read | Async entry orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAccountAssetsForLiquidation (procedure)
├── Trade.PositionTbl (table)
├── Trade.InstrumentMetaData (table)
├── Trade.NonLiquidatablePositionRules (table)
├── Trade.OrderForClose (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrdersEntry (table)
├── Trade.Orders (table)
├── Trade.Mirror (table)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT - open manual positions |
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument type resolution |
| Trade.NonLiquidatablePositionRules | Table | LEFT JOIN - liquidation eligibility rules |
| Trade.OrderForClose | Table | INNER JOIN - async close orders |
| Trade.CloseExecutionPlan | Table | INNER JOIN - close execution plan |
| Trade.OrdersEntry | Table | SELECT - manual entry orders (disabled) |
| Trade.Orders | Table | SELECT - all orders |
| Trade.Mirror | Table | SELECT - CopyTrader mirrors |
| Trade.OrderForOpen | Table | SELECT - async entry orders |

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

### 8.1 Run liquidation asset check for a customer

```sql
EXEC Trade.GetAccountAssetsForLiquidation @CID = 12345678;
```

### 8.2 Preview non-liquidatable position rules

```sql
SELECT  NLPR.InstrumentTypeID,
        NLPR.SettlementTypeID
FROM    Trade.NonLiquidatablePositionRules NLPR WITH (NOLOCK);
```

### 8.3 Check which positions would be protected for a customer

```sql
SELECT  TP.PositionID,
        TP.InstrumentID,
        IMT.InstrumentTypeID,
        TP.SettlementTypeID,
        IIF(NLPR.InstrumentTypeID IS NOT NULL, 1, 0) AS IsNonLiquidatable
FROM    Trade.PositionTbl TP WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMT WITH (NOLOCK)
    ON TP.InstrumentID = IMT.InstrumentID
LEFT JOIN Trade.NonLiquidatablePositionRules NLPR WITH (NOLOCK)
    ON IMT.InstrumentTypeID = NLPR.InstrumentTypeID
    AND TP.SettlementTypeID = NLPR.SettlementTypeID
WHERE   TP.CID = 12345678
    AND TP.MirrorID = 0
    AND TP.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAccountAssetsForLiquidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAccountAssetsForLiquidation.sql*
