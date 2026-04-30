# Trade.FnCalculatePnLWrapper

> Unified PnL calculation entry point that routes to FnCalculateCurrentPnL (live rates) or FnCalculatePnLByRates (pre-supplied rates) based on whether @EndClosingRate and @EndConversionRate are provided.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with PnLInDollars, PnLInCents, CurrentClosingRate, CurrentClosingRateID, ConversionRate, ConversionRateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FnCalculatePnLWrapper is the primary entry point for PnL calculation across the platform. It abstracts the choice between live market rates and pre-supplied rates behind a single function call. Callers pass position parameters; when @EndClosingRate and @EndConversionRate are both NULL, the function delegates to Trade.FnCalculateCurrentPnL (which fetches live rates). When either end rate is provided, it delegates to Trade.FnCalculatePnLByRates (which uses the supplied rates or falls back to live for the missing one).

This unified interface exists so that views (e.g., Trade.OpenPositionEndOfDay, Trade.PnL), procedures (Trade.ManualPositionClose, Trade.PositionReopen, Trade.PositionsWithWrongPnLAlert, Trade.CalcPNLForSpecificRate), and any future consumers need only one function to call. The routing logic is centralized, avoiding duplicate conditional logic across dozens of call sites.

Data flows: the function is invoked via CROSS APPLY from position views and procedures. It receives position-level parameters (InstrumentID, IsBuy, Units, IsSettled, InitRate, InitConversionRate, PnLVersion, markups, AccountCurrencyID) plus optional end rates. It returns a single row with PnL values and rate IDs for audit.

---

## 2. Business Logic

### 2.1 Conditional Route to Live vs ByRates

**What**: UNION ALL with mutually exclusive WHERE clauses routes to the correct inner function.

**Columns/Parameters Involved**: `@EndClosingRate`, `@EndConversionRate`

**Rules**:
- When `@EndClosingRate IS NULL AND @EndConversionRate IS NULL` → call FnCalculateCurrentPnL (live rates only)
- When `@EndClosingRate IS NOT NULL OR @EndConversionRate IS NOT NULL` → call FnCalculatePnLByRates (accepts pre-supplied rates)
- The two branches are mutually exclusive; exactly one produces rows
- Both inner functions return the same column set (6 columns), so the UNION ALL merges seamlessly

**Diagram**:
```
Caller passes @EndClosingRate, @EndConversionRate
         │
         ▼
    ┌─────────────────────────────────────────────────────┐
    │ Both NULL?  → FnCalculateCurrentPnL (live rates)    │
    │ Either set? → FnCalculatePnLByRates (rates or fallback)│
    └─────────────────────────────────────────────────────┘
         │
         ▼
    PnLInDollars, PnLInCents, CurrentClosingRate, CurrentClosingRateID,
    ConversionRate, ConversionRateID
```

### 2.2 Parameter Inheritance

**What**: All base parameters (1–10) are passed identically to both inner functions.

**Rules**: @InstrumentID, @IsBuy, @Units, @IsSettled, @InitRate, @InitConversionRate, @PnLVersion, @EstimatedClosingMarkups, @EstimatedClosingConversionMarkups, @AccountCurrencyID flow through unchanged. FnCalculatePnLByRates additionally receives @EndClosingRate, @EndClosingRateID, @EndConversionRate, @EndConversionRateID.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. Passed to rate lookup and PnL formula. |
| 2 | @IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy, 0=Sell. Determines bid/ask selection and PnL sign. See [Open Position Action Type](_glossary.md#open-position-action-type). |
| 3 | @Units | decimal(16,6) | NO | - | CODE-BACKED | Position size in units. Multiplier in PnL formula. |
| 4 | @IsSettled | TINYINT | NO | - | VERIFIED | Settlement type: 1=real asset, 0=CFD. Affects rate tier and PnL formula. See [Settlement Type](_glossary.md#settlement-type). |
| 5 | @InitRate | dbo.dtPrice | NO | - | CODE-BACKED | Opening rate when position was opened. |
| 6 | @InitConversionRate | dbo.dtPrice | NO | - | CODE-BACKED | Conversion rate when position was opened. Used only in PnLVersion=1 settled formula. |
| 7 | @PnLVersion | TINYINT | NO | - | VERIFIED | PnL formula version: 1=legacy (InitConversionRate factored in), other=standard. |
| 8 | @EstimatedClosingMarkups | DECIMAL | NO | - | CODE-BACKED | Estimated closing spread markups. Passed to rate lookup when using live rates. |
| 9 | @EstimatedClosingConversionMarkups | DECIMAL | NO | - | CODE-BACKED | Estimated conversion spread markups. Passed to rate lookup when using live rates. |
| 10 | @AccountCurrencyID | INT | NO | - | CODE-BACKED | Customer's account currency. Passed to FnGetCurrentConversionRate when using live rates. |
| 11 | @EndClosingRate | dbo.dtPrice | YES | - | CODE-BACKED | Pre-supplied closing rate. NULL = use live rate. When NOT NULL (with or without @EndConversionRate), routes to FnCalculatePnLByRates. |
| 12 | @EndClosingRateID | bigint | NO | - | CODE-BACKED | PriceRateID of pre-supplied closing rate. 0 if not provided. |
| 13 | @EndConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | Pre-supplied conversion rate. NULL = use live rate. When NOT NULL (with or without @EndClosingRate), routes to FnCalculatePnLByRates. |
| 14 | @EndConversionRateID | bigint | NO | - | CODE-BACKED | PriceRateID of pre-supplied conversion rate. 0 if not provided. |
| 15 | PnLInDollars (return) | decimal | YES | - | CODE-BACKED | Calculated PnL in account currency (major units). Inherited from inner functions. |
| 16 | PnLInCents (return) | decimal | YES | - | CODE-BACKED | PnL × 100, for systems operating in minor currency units. Inherited from inner functions. |
| 17 | CurrentClosingRate (return) | decimal | YES | - | CODE-BACKED | Closing rate used in calculation (live or pre-supplied). |
| 18 | CurrentClosingRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of the closing rate, for audit trail. |
| 19 | ConversionRate (return) | decimal | YES | - | CODE-BACKED | Conversion rate used in calculation. |
| 20 | ConversionRateID (return) | bigint | YES | - | CODE-BACKED | PriceRateID of the conversion rate, for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Parameters | Trade.FnCalculateCurrentPnL | CROSS APPLY (conditional) | Live PnL when end rates are NULL |
| Parameters | Trade.FnCalculatePnLByRates | CROSS APPLY (conditional) | PnL with pre-supplied or mixed rates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay | CROSS APPLY | View reference | EOD PnL snapshots |
| Trade.OpenPositionEndOfDayWith2Pnl | CROSS APPLY | View reference | Dual PnL view |
| Trade.OpenPositionEndOfDay_* variants | CROSS APPLY | View reference | EOD view variants |
| Trade.PnL | CROSS APPLY | View reference | Unified PnL view |
| Trade.ManualPositionClose | CROSS APPLY | Procedure reference | Close-time PnL |
| Trade.PositionReopen | CROSS APPLY | Procedure reference | Reopen PnL |
| Trade.PositionsWithWrongPnLAlert | CROSS APPLY | Procedure reference | PnL validation |
| Trade.CalcPNLForSpecificRate | CROSS APPLY | Procedure reference | Ad-hoc PnL calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FnCalculatePnLWrapper (function)
├── Trade.FnCalculateCurrentPnL (function)
│     ├── Trade.FnGetCurrentConversionRate (function)
│     │     ├── Trade.FnGetConversionInstrument (function)
│     │     ├── Trade.FnIsRealPosition (function)
│     │     └── Trade.CurrencyPrice (table)
│     ├── Trade.FnGetCurrentClosingRate (function)
│     │     ├── Trade.FnIsRealPosition (function)
│     │     └── Trade.CurrencyPrice (table)
│     └── Trade.FnCalculatePnL (function)
└── Trade.FnCalculatePnLByRates (function)
      ├── Trade.FnGetCurrentConversionRate (function) [conditional]
      ├── Trade.FnGetCurrentClosingRate (function) [conditional]
      └── Trade.FnCalculatePnL (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FnCalculateCurrentPnL | Function | CROSS APPLY when @EndClosingRate and @EndConversionRate both NULL |
| Trade.FnCalculatePnLByRates | Function | CROSS APPLY when either end rate is provided |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay | View | CROSS APPLY for PnL |
| Trade.OpenPositionEndOfDayWith2Pnl | View | CROSS APPLY for dual PnL |
| Trade.PnL | View | CROSS APPLY for PnL |
| Trade.ManualPositionClose | Procedure | CROSS APPLY for close PnL |
| Trade.PositionReopen | Procedure | CROSS APPLY for reopen PnL |
| Trade.PositionsWithWrongPnLAlert | Procedure | CROSS APPLY for PnL validation |
| Trade.CalcPNLForSpecificRate | Procedure | CROSS APPLY for ad-hoc PnL |
| Trade.OpenPositionEndOfDay_* variants | Views | CROSS APPLY for EOD PnL |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 6 columns |
| UNION ALL | Logic | Mutually exclusive branches via WHERE |
| dbo.dtPrice | User-defined type | Custom decimal type for price precision |

---

## 8. Sample Queries

### 8.1 Calculate live PnL (no end rates)

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculatePnLWrapper(
            1001, 1, 100.0, 0, 155.75, 1.1234, 0, 0, 0, 1,
            NULL, 0, NULL, 0  -- Routes to FnCalculateCurrentPnL
        ) pnl;
```

### 8.2 Calculate PnL with pre-supplied close rates

```sql
SELECT  pnl.PnLInDollars, pnl.CurrentClosingRate, pnl.ConversionRate
FROM    Trade.FnCalculatePnLWrapper(
            1001, 1, 100.0, 0, 155.75, 1.1234, 0, 0, 0, 1,
            160.50, 123456789, 1.1100, 987654321  -- Routes to FnCalculatePnLByRates
        ) pnl;
```

### 8.3 Get PnL for all open positions of a customer

```sql
SELECT  p.PositionID, p.InstrumentID, pnl.PnLInDollars, pnl.CurrentClosingRate
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.FnCalculatePnLWrapper(
            p.InstrumentID, p.IsBuy, p.AmountInUnitsDecimal, p.IsSettled,
            p.InitRate, p.InitConversionRate, p.PnLVersion,
            ISNULL(p.EstimatedClosingMarkups, 0),
            ISNULL(p.EstimatedClosingConversionMarkups, 0),
            p.AccountCurrencyID,
            NULL, 0, NULL, 0
        ) pnl
WHERE   p.CID = 12345678 AND p.StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Dependency docs*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ consumers | Dependencies: FnCalculateCurrentPnL, FnCalculatePnLByRates documented | Corrections: 0 applied*
*Object: Trade.FnCalculatePnLWrapper | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FnCalculatePnLWrapper.sql*
