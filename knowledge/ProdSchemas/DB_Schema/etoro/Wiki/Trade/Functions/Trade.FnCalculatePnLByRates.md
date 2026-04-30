# Trade.FnCalculatePnLByRates

> Computes PnL using optionally pre-supplied closing and conversion rates, falling back to live market rates only when not provided — enabling both real-time and historical/what-if PnL scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with PnLInDollars, PnLInCents, CurrentClosingRate, CurrentClosingRateID, ConversionRate, ConversionRateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnCalculatePnLByRates is the flexible PnL calculation function that supports both live and pre-supplied rates. Unlike FnCalculateCurrentPnL (which always fetches live rates), this function accepts optional end closing and conversion rates. When provided, it skips the live rate lookup entirely and uses the caller's values; when NULL, it falls back to live market data.

This dual behavior supports multiple scenarios:
- **Live PnL**: Pass NULL for @EndClosingRate and @EndConversionRate → behaves identically to FnCalculateCurrentPnL
- **Historical PnL**: Pass rates captured at a specific point in time → reproduces PnL at that moment
- **What-if PnL**: Pass hypothetical rates → models PnL under different price scenarios
- **Close PnL**: Pass the actual close rates → computes the final realized PnL

The function uses OUTER APPLY instead of CROSS APPLY, allowing the rate lookup subqueries to be skipped entirely when pre-supplied rates are available (the WHERE clause `@EndConversionRate IS NULL` short-circuits the lookup).

---

## 2. Business Logic

### 2.1 Rate Resolution with Optional Override

**What**: OUTER APPLY with conditional WHERE clause enables rate bypass.

**Columns/Parameters Involved**: `@EndClosingRate`, `@EndClosingRateID`, `@EndConversionRate`, `@EndConversionRateID`

**Rules**:
- **Conversion rate**: If `@EndConversionRate IS NOT NULL` → use `@EndConversionRate` and `@EndConversionRateID`, skip FnGetCurrentConversionRate entirely
- **Closing rate**: If `@EndClosingRate IS NOT NULL` → use `@EndClosingRate` and `@EndClosingRateID`, skip FnGetCurrentClosingRate entirely
- **Fallback**: If either is NULL → execute the corresponding live rate function via OUTER APPLY
- ISNULL coalesces pre-supplied rates with live rates for the final PnL calculation
- IIF selects the correct PriceRateID based on whether override was used

### 2.2 Dummy Table Pattern

**What**: Uses `(SELECT 1 AS 'dummy') DummyTableForOuterApply` as the FROM clause anchor.

**Purpose**: Required because OUTER APPLY needs a base table. The dummy table always produces exactly one row, ensuring the OUTER APPLY chain returns exactly one result row regardless of which rate paths are taken.

### 2.3 PnL Output

**What**: Same as FnCalculateCurrentPnL — PnLInDollars, PnLInCents (×100), and rate audit trail.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument identifier. |
| 2 | @IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy, 0=Sell. |
| 3 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Position size in units. |
| 4 | @IsSettled | TINYINT | NO | - | VERIFIED | Settlement type: 1=real, 0=CFD. |
| 5 | @InitRate | dbo.dtPrice | NO | - | CODE-BACKED | Position open rate. |
| 6 | @InitConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Conversion rate at position open. |
| 7 | @PnLVersion | TINYINT | NO | - | VERIFIED | PnL formula version selector. |
| 8 | @EstimatedClosingMarkups | DECIMAL | NO | - | CODE-BACKED | Closing spread markups (used only when falling back to live rate). |
| 9 | @EstimatedClosingConversionMarkups | DECIMAL | NO | - | CODE-BACKED | Conversion spread markups (used only when falling back to live rate). |
| 10 | @AccountCurrencyID | INT | NO | - | CODE-BACKED | Account currency (used only when falling back to live rate). |
| 11 | @EndClosingRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Pre-supplied closing rate. NULL triggers live rate lookup. |
| 12 | @EndClosingRateID | BIGINT | NO | 0 | CODE-BACKED | PriceRateID of pre-supplied closing rate. 0 if not provided. |
| 13 | @EndConversionRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Pre-supplied conversion rate. NULL triggers live rate lookup. |
| 14 | @EndConversionRateID | BIGINT | NO | 0 | CODE-BACKED | PriceRateID of pre-supplied conversion rate. 0 if not provided. |
| 15 | PnLInDollars (return) | decimal | YES | - | CODE-BACKED | Calculated PnL in account currency. |
| 16 | PnLInCents (return) | decimal | YES | - | CODE-BACKED | PnL × 100 for minor-unit systems. |
| 17 | CurrentClosingRate (return) | decimal | YES | - | CODE-BACKED | Closing rate used (pre-supplied or live). |
| 18 | CurrentClosingRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of closing rate used. |
| 19 | ConversionRate (return) | decimal | YES | - | CODE-BACKED | Conversion rate used (pre-supplied or live). |
| 20 | ConversionRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of conversion rate used. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Conversion fallback | Trade.FnGetCurrentConversionRate | OUTER APPLY | Live conversion rate (only when @EndConversionRate IS NULL) |
| Closing fallback | Trade.FnGetCurrentClosingRate | OUTER APPLY | Live closing rate (only when @EndClosingRate IS NULL) |
| PnL formula | Trade.FnCalculatePnL | OUTER APPLY | PnL computation using final rates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD PnL with snapshot rates |
| Position close procedures | CROSS APPLY | Procedure reference | Final PnL at close with actual close rates |
| Dividend/corporate action procedures | CROSS APPLY | Procedure reference | PnL at snapshot time with historical rates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnCalculatePnLByRates (function, L2)
  ├── Trade.FnGetCurrentConversionRate (function, L1) [conditional]
  │     ├── Trade.FnGetConversionInstrument (function, L0)
  │     ├── Trade.FnIsRealPosition (function, L0)
  │     └── Trade.CurrencyPrice (table)
  ├── Trade.FnGetCurrentClosingRate (function, L1) [conditional]
  │     ├── Trade.FnIsRealPosition (function, L0)
  │     └── Trade.CurrencyPrice (table)
  └── Trade.FnCalculatePnL (function, L0)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCurrentConversionRate | Function (L1) | OUTER APPLY: conditional live conversion rate |
| Trade.FnGetCurrentClosingRate | Function (L1) | OUTER APPLY: conditional live closing rate |
| Trade.FnCalculatePnL | Function (L0) | OUTER APPLY: PnL formula |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay* | Views | PnL with optional rate overrides |
| Position close procedures | Procedures | Final realized PnL |
| Corporate action procedures | Procedures | Snapshot PnL with historical rates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 6 columns |
| TOP 1 | Row guarantee | Ensures single-row return |
| OUTER APPLY + WHERE IS NULL | Conditional execution | Rate lookups skipped when pre-supplied rates exist |
| dbo.dtPrice | User-defined type | Custom decimal type for price precision |
| Default @EndClosingRateID=0, @EndConversionRateID=0 | Defaults | Simplifies caller when no pre-supplied rate IDs |

### 7.3 Comparison with FnCalculateCurrentPnL

| Aspect | FnCalculateCurrentPnL | FnCalculatePnLByRates |
|--------|----------------------|----------------------|
| Rate source | Always live | Pre-supplied OR live |
| JOIN type | CROSS APPLY | OUTER APPLY (conditional) |
| Extra parameters | None | @EndClosingRate, @EndClosingRateID, @EndConversionRate, @EndConversionRateID |
| Use case | Real-time portfolio | Historical, close, what-if, and live |
| Dummy table | Not needed | Required for OUTER APPLY anchor |

---

## 8. Sample Queries

### 8.1 Calculate PnL with pre-supplied rates (historical)

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculatePnLByRates(
            1001, 1, 100.0, 0, 155.75, 1.1234, 0, 0, 0, 1,
            160.50,     -- EndClosingRate (pre-supplied)
            123456789,  -- EndClosingRateID
            1.1100,     -- EndConversionRate (pre-supplied)
            987654321   -- EndConversionRateID
        ) pnl;
```

### 8.2 Calculate PnL with live rates (NULL overrides)

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculatePnLByRates(
            1001, 1, 100.0, 0, 155.75, 1.1234, 0, 0, 0, 1,
            NULL, 0, NULL, 0  -- Falls back to live rates
        ) pnl;
```

### 8.3 Mixed: pre-supplied closing rate, live conversion rate

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculatePnLByRates(
            1001, 1, 100.0, 0, 155.75, 1.1234, 0, 0, 0, 1,
            160.50, 123456789,  -- Pre-supplied closing rate
            NULL, 0             -- Live conversion rate
        ) pnl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. PnL calculation documented in internal platform architecture.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnCalculatePnLByRates | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnCalculatePnLByRates.sql*
