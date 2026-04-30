# Trade.Elad111

> Developer test/debug procedure that calculates overnight fee values for non-leveraged and leveraged instrument positions using interest rates, conversion rates, and closing prices.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns table variable of computed fee values per instrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a developer-created test/debug procedure (named after developer "Elad") that replicates the overnight fee calculation logic from the production fee update pipeline. It computes buy and sell overnight fees for instruments of types Commodities (2), Indices (4), Stocks (5), ETF (6), and Crypto (10), taking into account interest rate overrides at the instrument, exchange, and instrument-type levels.

The procedure exists as a diagnostic tool to inspect fee calculation results without triggering the actual fee update. In production, the real fee update is handled by `Trade.UpdateInstrumentToFeeConfigTableV2` (which is commented out at the end of this procedure). This procedure simply calculates and returns the fee values for review.

Data flows through three CTE stages: INS retrieves instruments with their interest rate and exchange metadata, INS_DATA enriches with conversion rates, closing prices, and interest rate overrides (with a three-level priority: instrument > exchange > instrument type), and FEE computes the actual buy/sell overnight fee amounts. Results are inserted into a table variable typed as `Trade.InstrumentToFeeConfigTypeV2` and returned via SELECT.

---

## 2. Business Logic

### 2.1 Interest Rate Override Priority

**What**: Three-tier override hierarchy for interest rate parameters used in overnight fee calculation.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`, `OverNightFeePatternID`

**Rules**:
- Priority 1 (highest): Instrument-level override from Dictionary.InterestRateOverride (matched by InstrumentID + SettlementTypeID)
- Priority 2: Exchange-level override (matched by ExchangeID + SettlementTypeID, InstrumentID IS NULL)
- Priority 3: Instrument-type-level override (matched by InstrumentTypeID + SettlementTypeID, ExchangeID and InstrumentID both NULL)
- Fallback: Base Dictionary.InterestRate values when no override exists
- ISNULL wraps COALESCE chain to handle NULL overrides gracefully

### 2.2 Overnight Fee Calculation

**What**: Computes daily and weekend overnight fees for both buy and sell directions.

**Columns/Parameters Involved**: `BuyOverNightFee`, `SellOverNightFee`, `LastPrice`, `ConversionRateAsk`, `InterestRateBuy/Sell`, `MarkupBuy/Sell`, `OverNightFeePatternID`, `SettlementTypeID`

**Rules**:
- OverNightFeePatternID=2 (manual): All fees are 0 (excluded from result)
- OverNightFeePatternID=0 or 1: Included in result
- SettlementTypeID=5 (MARGIN_TRADE): Fee = InterestRate / 365 (flat rate, no price dependency)
- Other settlement types: Fee = (LastPrice * (InterestRate + Markup) * ConversionRateAsk) / 365
- End-of-week fees = Daily fee * 3 (covers Saturday + Sunday + carry day)
- NonLeveraged sell fees for OverNightFeePatternID=0: Set to 0 when FuturesMetaData exists for the instrument (futures contract handling)
- FeeCalculationTypeID: 1 for MARGIN_TRADE (SettlementTypeID=5), 0 for all others

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppLoginName | varchar(50) | YES | NULL | CODE-BACKED | Login name of the user running the fee calculation. Intended for audit logging in the commented-out UpdateInstrumentToFeeConfigTableV2 call. Not used in current logic. |
| 2 | @IsAlertTriggered | BIT | NO | - | CODE-BACKED | OUTPUT parameter. Would indicate whether fee changes exceeded alert thresholds. Not populated since the update call is commented out; always returns NULL. |

**Output Columns (from @FeeValuesTbl, typed as Trade.InstrumentToFeeConfigTypeV2):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier. Includes only Commodities (2), Indices (4), Stocks (5), ETF (6), Crypto (10). |
| 2 | NonLeveragedSellEndOfWeekFee | money | NO | - | CODE-BACKED | Weekend sell overnight fee for non-leveraged positions. Triple the daily sell fee. Set to 0 for futures instruments with OverNightFeePatternID=0. |
| 3 | NonLeveragedBuyEndOfWeekFee | money | NO | - | CODE-BACKED | Weekend buy overnight fee for non-leveraged positions. Triple the daily buy fee. 0 for OverNightFeePatternID=0. |
| 4 | NonLeveragedBuyOverNightFee | money | NO | - | CODE-BACKED | Daily buy overnight fee for non-leveraged positions. 0 for OverNightFeePatternID=0. |
| 5 | NonLeveragedSellOverNightFee | money | NO | - | CODE-BACKED | Daily sell overnight fee for non-leveraged positions. 0 for futures with OverNightFeePatternID=0. |
| 6 | LeveragedBuyEndOfWeekFee | money | NO | - | CODE-BACKED | Weekend buy overnight fee for leveraged positions. Triple the daily buy fee. |
| 7 | LeveragedSellEndOfWeekFee | money | NO | - | CODE-BACKED | Weekend sell overnight fee for leveraged positions. Triple the daily sell fee. |
| 8 | LeveragedBuyOverNightFee | money | NO | - | CODE-BACKED | Daily buy overnight fee for leveraged positions. |
| 9 | LeveragedSellOverNightFee | money | NO | - | CODE-BACKED | Daily sell overnight fee for leveraged positions. |
| 10 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | Settlement type from Dictionary.InterestRate. Determines fee formula: 5=MARGIN_TRADE uses flat rate, others use price-based calculation. |
| 11 | FeeCalculationTypeID | int | NO | - | CODE-BACKED | Derived: 1 when SettlementTypeID=5 (MARGIN_TRADE), 0 otherwise. Controls which fee calculation engine processes this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.GetInstrument | VIEW/READ | Reads instrument metadata including InstrumentTypeID, ExchangeID, SellCurrencyID |
| SellCurrencyID | Dictionary.Currency | JOIN | Resolves instrument's sell currency to InterestRateID |
| InterestRateID + InstrumentTypeID | Dictionary.InterestRate | JOIN | Base interest rates and markups per instrument type |
| InstrumentID/ExchangeID/InstrumentTypeID | Dictionary.InterestRateOverride | LEFT JOIN (x3) | Three-level override hierarchy for interest rate parameters |
| InstrumentID | Trade.FnGetCurrentConversionRate | OUTER APPLY | Gets current conversion rate for fee currency conversion |
| InstrumentID | Trade.GetClosingPrice | OUTER APPLY | Gets last closing price for fee calculation basis |
| InstrumentID | Trade.FuturesMetaData | LEFT JOIN | Checks if instrument is a futures contract (affects NonLeveraged sell fee) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found) | - | - | Developer test procedure with no known callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Elad111 (procedure)
+-- Trade.GetInstrument (view)
+-- Dictionary.Currency (table)
+-- Dictionary.InterestRate (table)
+-- Dictionary.InterestRateOverride (table)
+-- Trade.FnGetCurrentConversionRate (function)
+-- Trade.GetClosingPrice (function)
+-- Trade.FuturesMetaData (table)
+-- Trade.InstrumentToFeeConfigTypeV2 (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | FROM - reads instrument metadata |
| Dictionary.Currency | Table | JOIN on SellCurrencyID to get InterestRateID |
| Dictionary.InterestRate | Table | JOIN for base interest rates and markups |
| Dictionary.InterestRateOverride | Table | LEFT JOIN (3x) for override hierarchy |
| Trade.FnGetCurrentConversionRate | Function | OUTER APPLY for conversion rate |
| Trade.GetClosingPrice | Function | OUTER APPLY for closing price |
| Trade.FuturesMetaData | Table | LEFT JOIN to identify futures instruments |
| Trade.InstrumentToFeeConfigTypeV2 | User Defined Type | Table variable type for result set |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: The final EXEC of `Trade.UpdateInstrumentToFeeConfigTableV2` is commented out. This procedure is a read-only diagnostic version of the fee calculation.

---

## 8. Sample Queries

### 8.1 Run Fee Calculation Preview

```sql
DECLARE @Alert BIT
EXEC Trade.Elad111 @AppLoginName = 'DBA', @IsAlertTriggered = @Alert OUTPUT
SELECT @Alert AS AlertTriggered
```

### 8.2 Compare with Current Fee Config

```sql
SELECT fc.InstrumentID,
       fc.NonLeveragedBuyOverNightFee AS CurrentBuyFee,
       fc.LeveragedBuyOverNightFee AS CurrentLevBuyFee
  FROM Trade.InstrumentToFeeConfig fc WITH (NOLOCK)
 WHERE fc.InstrumentID IN (SELECT InstrumentID FROM Trade.GetInstrument WITH (NOLOCK) WHERE InstrumentTypeID = 5)
 ORDER BY fc.InstrumentID
```

### 8.3 Check Interest Rate Override Hierarchy

```sql
SELECT ir.InstrumentTypeID,
       ir.SettlementTypeID,
       ir.InterestRateBuy,
       iro.InstrumentID AS OverrideInstrumentID,
       iro.ExchangeID AS OverrideExchangeID,
       iro.InterestRateBuy AS OverrideBuyRate
  FROM Dictionary.InterestRate ir WITH (NOLOCK)
  LEFT JOIN Dictionary.InterestRateOverride iro WITH (NOLOCK)
    ON ir.InstrumentTypeID = iro.InstrumentTypeID
 WHERE ir.InstrumentTypeID IN (2, 4, 5, 6, 10)
 ORDER BY ir.InstrumentTypeID, ir.SettlementTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Elad111 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Elad111.sql*
