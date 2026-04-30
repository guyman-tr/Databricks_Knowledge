# Trade.FnCalculatePnL

> Core PnL (Profit and Loss) calculation engine that computes the monetary result of a trading position given its direction, size, settlement type, open/close rates, and conversion rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with single column `PnL` (decimal, ROUND to 2 decimals) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnCalculatePnL is the foundational PnL calculation formula for eToro's trading platform. It computes the profit or loss of a trading position by combining the entry rate, exit rate, currency conversion rates, position size (units), trade direction (buy/sell), and the PnL calculation version. Every position's realized and unrealized PnL ultimately flows through this function or its wrappers.

This function exists because PnL calculation logic must be consistent across all consumers - open position displays, close calculations, hedge exposure, and end-of-day snapshots. Centralizing the formula in a single inline TVF ensures one source of truth for the most critical financial number on the platform. Without it, PnL could diverge between views, leading to incorrect margin calls, wrong equity calculations, and regulatory reporting errors.

This function is never called directly by views or stored procedures. Instead, it is consumed exclusively by two wrapper functions: Trade.FnCalculateCurrentPnL (which supplies live market rates) and Trade.FnCalculatePnLByRates (which accepts explicit end rates). Those wrappers in turn feed Trade.FnCalculatePnLWrapper, which is consumed by the Trade.PnL view and dozens of downstream consumers.

---

## 2. Business Logic

### 2.1 Dual PnL Calculation Formulas

**What**: Two distinct formulas exist based on the position's PnL version and settlement type, reflecting a historical evolution in how multi-currency PnL is computed.

**Columns/Parameters Involved**: `@PnLVersion`, `@IsSettled`, `@InitRate`, `@EndRate`, `@InitConversionRate`, `@EndConversionRate`, `@Units`, `@IsBuy`

**Rules**:
- **Legacy formula** (PnLVersion=1 AND IsSettled=1 - real stock positions on v1): `ROUND((EndRate * EndConversionRate - InitRate * InitConversionRate) * Units * Direction, 2)`. This converts BOTH open and close prices to the account currency BEFORE computing the difference, which means the conversion rate movement between open and close affects PnL.
- **Standard formula** (all other cases - CFDs, v2 positions, etc.): `ROUND((EndRate - InitRate) * EndConversionRate * Units * Direction, 2)`. This computes the price difference in the instrument's native currency first, then converts to account currency using only the current conversion rate. Conversion rate changes between open and close do NOT affect PnL.
- Direction multiplier: `IIF(@IsBuy=1, 1, -1)` - Buy (long) positions profit when price rises; Sell (short) positions profit when price falls.
- Result is always rounded to 2 decimal places (cents precision).

**Diagram**:
```
PnLVersion=1 AND IsSettled=1 (Legacy Real Stock):
  PnL = (EndRate x EndConvRate - InitRate x InitConvRate) x Units x Dir
        |_________________________|   |__________________________|
         Close value in acct ccy       Open value in acct ccy
         (conversion embedded)          (conversion embedded)

All other cases (Standard - CFDs, v2+):
  PnL = (EndRate - InitRate) x EndConvRate x Units x Dir
        |__________________|   |__________|
         Price diff in           Convert to
         instrument ccy          account ccy
```

### 2.2 Direction Multiplier

**What**: Converts the raw price difference into a signed PnL based on position direction.

**Columns/Parameters Involved**: `@IsBuy`, result PnL

**Rules**:
- Buy (long) position (@IsBuy=1): Positive PnL when EndRate > InitRate (price went up)
- Sell (short) position (@IsBuy=0): Positive PnL when EndRate < InitRate (price went down)
- The multiplier `IIF(@IsBuy=1, 1, -1)` is applied after the rate calculation

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1 = Buy/Long (profit when price rises), 0 = Sell/Short (profit when price falls). Maps to `PositionTbl.IsBuy`. Used as multiplier: `IIF(@IsBuy=1, 1, -1)`. |
| 2 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units in the position. From `PositionTbl.AmountInUnitsDecimal`. Multiplied by per-unit PnL to get total position PnL. |
| 3 | @IsSettled | TINYINT | NO | - | VERIFIED | LEGACY settlement flag. 1 = real stock position (actual share ownership), 0 = CFD. NOT "settlement complete." Only affects PnL when @PnLVersion=1: real stock positions use the legacy conversion-embedded formula. Maps to `PositionTbl.IsSettled`. See [Settlement Type](_glossary.md#settlement-type). |
| 4 | @InitRate | dbo.dtPrice | NO | - | CODE-BACKED | Opening price rate when the position was opened. From `PositionTbl.InitForexRate`. In instrument's native price currency. |
| 5 | @InitConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Currency conversion rate at position open (instrument currency to account currency). From `PositionTbl.InitConversionRate`. Only used in legacy formula (PnLVersion=1, IsSettled=1). |
| 6 | @EndRate | dbo.dtPrice | NO | - | CODE-BACKED | Closing/current price rate. For open positions this is the live market bid/ask; for closed positions this is the execution close rate. Supplied by caller (FnCalculateCurrentPnL provides live rate, FnCalculatePnLByRates accepts explicit rate). |
| 7 | @EndConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Current currency conversion rate (instrument currency to account currency). In the standard formula, this is the ONLY conversion rate used. In the legacy formula, both init and end conversion rates are used. |
| 8 | @PnLVersion | TINYINT | NO | - | CODE-BACKED | PnL calculation version flag from `PositionTbl.PnLVersion` (default 0). Version 1 with IsSettled=1 triggers the legacy formula where both conversion rates are embedded. All other combinations (including version 0, which is the default) use the standard formula. |
| 9 | PnL (return) | decimal (implied) | NO | - | CODE-BACKED | Computed profit or loss rounded to 2 decimal places. Positive = profit, negative = loss. In the customer's account denomination currency. Returned as a single-column, single-row TABLE result via `SELECT TOP 1`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a pure calculation function with no table or view dependencies.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FnCalculateCurrentPnL | CROSS APPLY | Function call | Supplies live market rates from FnGetCurrentClosingRate and FnGetCurrentConversionRate, then calls FnCalculatePnL for the actual PnL math. |
| Trade.FnCalculatePnLByRates | OUTER APPLY | Function call | Accepts explicit end rates (or falls back to live rates), then calls FnCalculatePnL for the actual PnL math. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnCalculatePnL (function)
(no dependencies - leaf node, pure calculation)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnCalculateCurrentPnL | Function | CROSS APPLY - live PnL calculation using current market rates |
| Trade.FnCalculatePnLByRates | Function | OUTER APPLY - PnL calculation with explicit or fallback rates |
| Trade.FnCalculatePnLWrapper | Function | Indirect - calls FnCalculateCurrentPnL and FnCalculatePnLByRates |
| Trade.PnL | View | Indirect - via FnCalculatePnLWrapper chain |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline table-valued function returning single-column `PnL` via SELECT TOP 1 |
| ROUND(..., 2) | Precision | All results rounded to 2 decimal places (cents precision) |

---

## 8. Sample Queries

### 8.1 Calculate PnL for a specific open position using current rates

```sql
SELECT  p.PositionID,
        p.CID,
        p.InstrumentID,
        pnl.PnL
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnCalculatePnL(
            p.IsBuy,
            p.AmountInUnitsDecimal,
            p.IsSettled,
            p.InitForexRate,
            p.InitConversionRate,
            cp.BuyPrice,
            1.0,
            p.PnLVersion
        ) pnl
        CROSS APPLY (
            SELECT TOP 1 BuyPrice
            FROM Trade.CurrencyPrice WITH (NOLOCK)
            WHERE InstrumentID = p.InstrumentID
        ) cp
WHERE   p.PositionID = 12345;
```

### 8.2 Compare legacy vs standard formula for a hypothetical trade

```sql
SELECT  legacy.PnL AS LegacyPnL,
        standard.PnL AS StandardPnL
FROM    Trade.FnCalculatePnL(1, 100.0, 1, 150.50, 1.10, 155.75, 1.15, 1) legacy
        CROSS JOIN
        Trade.FnCalculatePnL(1, 100.0, 1, 150.50, 1.10, 155.75, 1.15, 0) standard;
```

### 8.3 Bulk PnL calculation for all open positions of a customer

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        p.IsBuy,
        p.AmountInUnitsDecimal AS Units,
        pnl.PnL
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnCalculatePnL(
            p.IsBuy,
            p.AmountInUnitsDecimal,
            p.IsSettled,
            p.InitForexRate,
            ISNULL(p.InitConversionRate, 1.0),
            cp.BuyPrice,
            1.0,
            ISNULL(p.PnLVersion, 0)
        ) pnl
        CROSS APPLY (
            SELECT TOP 1 BuyPrice
            FROM Trade.CurrencyPrice WITH (NOLOCK)
            WHERE InstrumentID = p.InstrumentID
        ) cp
WHERE   p.CID = 12345678
        AND p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object directly. PnL calculation context inherited from Trade.PositionTbl documentation and Settlement Type glossary entry.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnCalculatePnL | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnCalculatePnL.sql*
