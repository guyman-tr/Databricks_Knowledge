# Trade.FnCalculateCurrentPnL

> Computes live PnL for a position by chaining the current closing rate, current conversion rate, and PnL formula into a single CROSS APPLY pipeline — the primary real-time PnL function used across the platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with PnLInDollars, PnLInCents, CurrentClosingRate, CurrentClosingRateID, ConversionRate, ConversionRateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnCalculateCurrentPnL is the primary live PnL calculation function for the platform. It chains three lower-level functions in a single CROSS APPLY pipeline:

1. **Trade.FnGetCurrentConversionRate** — resolves the live currency conversion rate from instrument currency to account currency
2. **Trade.FnGetCurrentClosingRate** — resolves the live closing rate (bid/ask based on direction and real/CFD)
3. **Trade.FnCalculatePnL** — applies the PnL formula using all rates

This function is used when NO pre-fetched end rates exist. The caller provides only the position's static parameters (instrument, direction, units, init rates, PnL version), and the function fetches live market data in real time. It returns both the calculated PnL and the rate IDs used, enabling audit trails and rate reconciliation.

This is the most widely used PnL function in the system — consumed by open position views, equity calculations, portfolio summaries, and risk exposure computations.

---

## 2. Business Logic

### 2.1 Live PnL Pipeline

**What**: Three-step CROSS APPLY chain computes PnL from live market data.

**Columns/Parameters Involved**: All 10 parameters

**Rules**:
1. `FnGetCurrentConversionRate(@InstrumentID, @AccountCurrencyID, @EstimatedClosingConversionMarkups, @IsBuy, @IsSettled)` → resolves ConversionRate + PriceRateID
2. `FnGetCurrentClosingRate(@IsBuy, @IsSettled, @InstrumentID, @EstimatedClosingMarkups)` → resolves CurrentClosingRate + PriceRateID
3. `FnCalculatePnL(@IsBuy, @Units, @IsSettled, @InitRate, @InitConversionRate, CurrentClosingRate, ConversionRate, @PnLVersion)` → computes PnL

**Output**: PnL in dollars, PnL in cents (×100), and the rate values + IDs used

### 2.2 PnL in Cents

**What**: `PnLInCents = PnLInDollars * 100`

**Purpose**: Cent-denominated PnL is used by downstream systems (e.g., the trading engine) that work in minor currency units to avoid floating-point precision issues.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. Passed to rate lookup functions. |
| 2 | @IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy, 0=Sell. Determines bid/ask selection and PnL sign. |
| 3 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Position size in units. Multiplier in PnL formula. |
| 4 | @IsSettled | TINYINT | NO | - | VERIFIED | Settlement type: 1=real asset, 0=CFD. Affects rate tier (discounted vs standard). |
| 5 | @InitRate | dbo.dtPrice | NO | - | CODE-BACKED | Opening rate when position was opened. |
| 6 | @InitConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Conversion rate when position was opened. Used only in PnLVersion=1 settled formula. |
| 7 | @PnLVersion | TINYINT | NO | - | VERIFIED | PnL formula version: 1=legacy (InitConversionRate factored in), other=standard. |
| 8 | @EstimatedClosingMarkups | DECIMAL | NO | - | CODE-BACKED | Estimated closing spread markups. Passed to FnGetCurrentClosingRate. |
| 9 | @EstimatedClosingConversionMarkups | DECIMAL | NO | - | CODE-BACKED | Estimated conversion spread markups. Passed to FnGetCurrentConversionRate. |
| 10 | @AccountCurrencyID | INT | NO | - | CODE-BACKED | Customer's account currency. Passed to FnGetCurrentConversionRate. |
| 11 | PnLInDollars (return) | decimal | YES | - | CODE-BACKED | Calculated PnL in account currency (major units). |
| 12 | PnLInCents (return) | decimal | YES | - | CODE-BACKED | PnL × 100, for systems operating in minor currency units. |
| 13 | CurrentClosingRate (return) | decimal | YES | - | CODE-BACKED | Live closing rate used in calculation, from CurrencyPrice. |
| 14 | CurrentClosingRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of the closing rate, for audit trail. |
| 15 | ConversionRate (return) | decimal | YES | - | CODE-BACKED | Live conversion rate used, from CurrencyPrice. |
| 16 | ConversionRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of the conversion rate, for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @AccountCurrencyID, @IsBuy, @IsSettled | Trade.FnGetCurrentConversionRate | CROSS APPLY | Live conversion rate |
| @IsBuy, @IsSettled, @InstrumentID | Trade.FnGetCurrentClosingRate | CROSS APPLY | Live closing rate |
| All rate params | Trade.FnCalculatePnL | CROSS APPLY | PnL calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay variants | CROSS APPLY | View reference | EOD PnL snapshots |
| Trade.OpenPositionIntraDay variants | CROSS APPLY | View reference | Real-time portfolio PnL |
| Position close procedures | CROSS APPLY | Procedure reference | Close-time PnL calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnCalculateCurrentPnL (function, L2)
  ├── Trade.FnGetCurrentConversionRate (function, L1)
  │     ├── Trade.FnGetConversionInstrument (function, L0)
  │     ├── Trade.FnIsRealPosition (function, L0)
  │     └── Trade.CurrencyPrice (table)
  ├── Trade.FnGetCurrentClosingRate (function, L1)
  │     ├── Trade.FnIsRealPosition (function, L0)
  │     └── Trade.CurrencyPrice (table)
  └── Trade.FnCalculatePnL (function, L0)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnGetCurrentConversionRate | Function (L1) | CROSS APPLY: live conversion rate |
| Trade.FnGetCurrentClosingRate | Function (L1) | CROSS APPLY: live closing rate |
| Trade.FnCalculatePnL | Function (L0) | CROSS APPLY: PnL formula |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay* | Views | Live PnL in EOD snapshots |
| Trade.OpenPositionIntraDay* | Views | Real-time PnL for portfolio |
| Position close/update procedures | Procedures | PnL at close time |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 6 columns |
| TOP 1 | Row guarantee | Ensures single-row return from CROSS APPLY chain |
| dbo.dtPrice | User-defined type | Custom decimal type for price precision |

---

## 8. Sample Queries

### 8.1 Calculate live PnL for a specific position

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculateCurrentPnL(
            1001,       -- InstrumentID
            1,          -- IsBuy
            100.0,      -- Units
            0,          -- IsSettled (CFD)
            155.75,     -- InitRate
            1.1234,     -- InitConversionRate
            0,          -- PnLVersion
            0,          -- EstimatedClosingMarkups
            0,          -- EstimatedClosingConversionMarkups
            1           -- AccountCurrencyID (USD)
        ) pnl;
```

### 8.2 Get PnL for all open positions of a customer

```sql
SELECT  p.PositionID,
        p.InstrumentID,
        pnl.PnLInDollars,
        pnl.CurrentClosingRate,
        pnl.ConversionRate
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnCalculateCurrentPnL(
            p.InstrumentID, p.IsBuy, p.AmountInUnitsDecimal, p.IsSettled,
            p.InitRate, p.InitConversionRate, p.PnLVersion,
            ISNULL(p.EstimatedClosingMarkups, 0),
            ISNULL(p.EstimatedClosingConversionMarkups, 0),
            1  -- AccountCurrencyID
        ) pnl
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. PnL calculation architecture described in internal platform documentation.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FnCalculateCurrentPnL | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnCalculateCurrentPnL.sql*
