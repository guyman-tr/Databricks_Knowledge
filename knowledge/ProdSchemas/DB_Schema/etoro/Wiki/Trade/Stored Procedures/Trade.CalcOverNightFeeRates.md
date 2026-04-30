# Trade.CalcOverNightFeeRates

> Calculates overnight (swap/rollover) fee rates for all tradeable instruments by combining closing prices, interest rates, conversion rates, and markup overrides, then updates Trade.InstrumentToFeeConfigTable via Trade.UpdateInstrumentToFeeConfigTableV2.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsAlertTriggered (OUTPUT - whether fee deviation alert was triggered) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CalcOverNightFeeRates is the scheduled fee calculation engine that computes daily overnight (swap/rollover) fees for every tradeable instrument. Overnight fees are charged to positions held past the daily rollover time and cover the cost of financing the leveraged position overnight. Weekend fees (end-of-week) are typically 3x the daily rate to cover Saturday and Sunday.

Without this procedure, overnight fees would not be refreshed daily. Since fees depend on closing prices and interest rates that change daily, stale fees would result in incorrect charges to customers. The procedure runs as a scheduled job, typically before the daily rollover window.

The procedure fetches the latest closing prices from the Price database via a linked server (AO-PRICE-LSN-ROR), joins with instrument data, currency interest rates, and a three-level override hierarchy (instrument > exchange > instrument type). It calculates buy/sell overnight and end-of-week fees, then passes the results to Trade.UpdateInstrumentToFeeConfigTableV2 which merges them into the live fee configuration table.

---

## 2. Business Logic

### 2.1 Fee Calculation Formula

**What**: Computes overnight fee as (ClosingPrice x (InterestRate + Markup) x ConversionRate) / 365.

**Columns/Parameters Involved**: `LastPrice`, `InterestRateBuy/Sell`, `MarkupBuy/Sell`, `ConversionRateAsk`

**Rules**:
- Standard formula: `(LastPrice * (InterestRate + Markup) * ConversionRateAsk) / 365`
- SettlementTypeID = 5 (MARGIN_TRADE): `(InterestRate + Markup) / 365` (no price or conversion - fee is absolute)
- OverNightFeePatternID = 2: Fee = 0 (manual override - excluded from calculation)
- End-of-week fee = DailyFee x 3 (covers Saturday + Sunday + Friday night)

### 2.2 Interest Rate Override Hierarchy

**What**: Three-level override priority for interest rates and markups.

**Rules**:
- Priority 1: Instrument-specific override (Dictionary.InterestRateOverride where InstrumentID matches)
- Priority 2: Exchange-specific override (where ExchangeID matches, InstrumentID is NULL)
- Priority 3: InstrumentType-specific override (where InstrumentTypeID matches, ExchangeID and InstrumentID are NULL)
- Fallback: Base interest rate from Dictionary.InterestRate
- Uses COALESCE across all three override levels, then ISNULL to fallback to base rate

### 2.3 Instrument Type Filtering

**What**: Only calculates fees for specific instrument types.

**Rules**:
- InstrumentTypeID IN (2, 4, 5, 6, 10) = Commodities, Indices, Stocks, ETF, Crypto
- Other types (e.g., Forex = 1) are excluded from this calculation

### 2.4 OverNightFeePatternID Logic

**What**: Controls how fees are applied for non-leveraged positions.

**Rules**:
- PatternID = 0: Buy overnight/end-of-week = 0 (buy side free), Sell only charged if NOT a futures instrument
- PatternID = 1: Both buy and sell charged normally
- PatternID = 2: All fees = 0 (manual override, excluded from WHERE clause)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdatedByUser | NVARCHAR(50) | NO | - | CODE-BACKED | Name of the user or job triggering the overnight fee recalculation. Passed through to Trade.UpdateInstrumentToFeeConfigTableV2 for audit tracking. |
| 2 | @IsAlertTriggered | BIT OUTPUT | NO | - | CODE-BACKED | Returns 1 if any calculated fee deviates significantly from the previous value (alert threshold logic is in Trade.UpdateInstrumentToFeeConfigTableV2). Used by the calling job to trigger notifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OPENQUERY | [AO-PRICE-LSN-ROR].Price.History.ClosingPrices | Linked Server | Fetches latest closing prices per instrument |
| FROM | Trade.GetInstrument | SELECT | Gets instrument list with InstrumentTypeID, SellCurrencyID, ExchangeID |
| JOIN | Dictionary.Currency | SELECT | Gets InterestRateID from sell currency |
| JOIN | Dictionary.InterestRate | SELECT | Base interest rates (buy/sell) and markups per instrument type |
| JOIN | Dictionary.InterestRateOverride | SELECT | Three-level override for interest rates and markups |
| APPLY | Trade.FnGetCurrentConversionRate | FUNCTION | Gets currency conversion rate (Ask side) for each instrument |
| JOIN | Trade.FuturesMetaData | SELECT | Identifies futures instruments (affects PatternID=0 sell fee) |
| EXEC | Trade.UpdateInstrumentToFeeConfigTableV2 | EXEC | Merges calculated fees into the live fee configuration table |
| TVP | Trade.InstrumentToFeeConfigTypeV2 | Type | UDT for passing calculated fee values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled SQL Agent Job | Job step | EXEC | Runs daily before the rollover window to refresh overnight fees |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalcOverNightFeeRates (procedure)
+-- Trade.GetInstrument (view/synonym)
+-- Dictionary.Currency (table)
+-- Dictionary.InterestRate (table)
+-- Dictionary.InterestRateOverride (table)
+-- Trade.FnGetCurrentConversionRate (function)
+-- Trade.FuturesMetaData (table)
+-- Trade.UpdateInstrumentToFeeConfigTableV2 (procedure)
+-- Trade.InstrumentToFeeConfigTypeV2 (user-defined table type)
+-- [AO-PRICE-LSN-ROR] (linked server)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View/Synonym | SELECT - instrument catalog with type, currency, exchange |
| Dictionary.Currency | Table | JOIN - maps SellCurrencyID to InterestRateID |
| Dictionary.InterestRate | Table | JOIN - base interest rates and markups |
| Dictionary.InterestRateOverride | Table | LEFT JOIN x3 - override hierarchy |
| Trade.FnGetCurrentConversionRate | Function | OUTER APPLY - currency conversion rates |
| Trade.FuturesMetaData | Table | LEFT JOIN - identifies futures for fee pattern logic |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Procedure | EXEC - merges fees into live table |
| Trade.InstrumentToFeeConfigTypeV2 | UDT | TVP for fee values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent scheduled job | External | Calls this SP on a daily schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LastPrice > 0 | Filter | Instruments without a valid closing price are excluded (prevents division issues) |
| ConversionRateAsk > 0 | Filter | Instruments without a conversion rate are excluded |
| OverNightFeePatternID IN (0,1) | Filter | PatternID=2 (manual) instruments are excluded from automatic calculation |

---

## 8. Sample Queries

### 8.1 View current overnight fee rates per instrument

```sql
SELECT  InstrumentID, BuyOverNightFee, SellOverNightFee,
        BuyEndOfWeekFee, SellEndOfWeekFee, SettlementTypeID
FROM    Trade.InstrumentToFeeConfigTable WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

### 8.2 Check interest rate overrides for a specific instrument

```sql
SELECT  'Instrument' AS Level, InstrumentID, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell
FROM    Dictionary.InterestRateOverride WITH (NOLOCK)
WHERE   InstrumentID = 1001
UNION ALL
SELECT  'Base', NULL, InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell
FROM    Dictionary.InterestRate WITH (NOLOCK)
WHERE   InstrumentTypeID = 5;
```

### 8.3 Execute the overnight fee calculation (admin use)

```sql
DECLARE @AlertTriggered BIT;
EXEC Trade.CalcOverNightFeeRates @UpdatedByUser = 'DailyJob', @IsAlertTriggered = @AlertTriggered OUTPUT;
SELECT @AlertTriggered AS IsAlertTriggered;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trading OpsTool API - InterestRate HLD | Confluence | Interest rate management context and override hierarchy |
| Interest Rates (TCM) | Confluence | Business context for overnight fee calculation methodology |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalcOverNightFeeRates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalcOverNightFeeRates.sql*
