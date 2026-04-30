# Trade.CalcOverNightFeeRates_TRDOPS

> TRDOPS (Trading Operations) variant of overnight fee calculation - identical to Trade.CalcOverNightFeeRates but excludes markup from MARGIN_TRADE (SettlementTypeID=5) fee formulas.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsAlertTriggered (OUTPUT - whether fee deviation alert was triggered) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CalcOverNightFeeRates_TRDOPS is the Trading Operations (TRDOPS) variant of the overnight fee calculation engine. It follows the same logic as Trade.CalcOverNightFeeRates - fetching closing prices from the Price linked server, joining with interest rates and override hierarchy, and computing daily/weekly fees - but differs in one key formula: for MARGIN_TRADE instruments (SettlementTypeID=5), this variant uses only the base InterestRate without adding the Markup component.

This variant exists because MARGIN_TRADE instruments may use a different fee model managed by the trading operations team. The standard CalcOverNightFeeRates adds Markup to the InterestRate for SettlementTypeID=5, while this TRDOPS version keeps the raw interest rate. This allows operations to separately control margin trade overnight fees.

The calculated fees are passed to Trade.UpdateInstrumentToFeeConfigTableV2, which merges them into the live fee configuration table. The procedure is called from admin tools or scheduled jobs managed by the trading operations team.

---

## 2. Business Logic

### 2.1 Fee Calculation Formula (TRDOPS Variant)

**What**: Same as Trade.CalcOverNightFeeRates but with a different MARGIN_TRADE formula.

**Columns/Parameters Involved**: `LastPrice`, `InterestRateBuy/Sell`, `MarkupBuy/Sell`, `ConversionRateAsk`

**Rules**:
- Standard instruments: `(LastPrice * (InterestRate + Markup) * ConversionRateAsk) / 365` (same as base version)
- SettlementTypeID = 5 (MARGIN_TRADE): `InterestRate / 365` (NO markup, NO price, NO conversion)
- Base version uses: `(InterestRate + Markup) / 365` for SettlementTypeID=5
- The ONLY formula difference between this and Trade.CalcOverNightFeeRates is the exclusion of Markup for MARGIN_TRADE

### 2.2 Interest Rate Override Hierarchy

**What**: Three-level override priority (identical to base version).

**Rules**:
- Priority 1: Instrument-specific override (Dictionary.InterestRateOverride where InstrumentID matches)
- Priority 2: Exchange-specific override (where ExchangeID matches, InstrumentID is NULL)
- Priority 3: InstrumentType-specific override (where InstrumentTypeID matches, ExchangeID and InstrumentID are NULL)
- Fallback: Base interest rate from Dictionary.InterestRate

### 2.3 Instrument Type and Fee Pattern Filtering

**What**: Same filtering as base version.

**Rules**:
- InstrumentTypeID IN (2, 4, 5, 6, 10) = Commodities, Indices, Stocks, ETF, Crypto
- OverNightFeePatternID IN (0, 1) only - PatternID=2 (manual) excluded
- PatternID = 0: Buy side free for non-leveraged, sell side free only for futures
- PatternID = 1: Both sides charged

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppLoginName | VARCHAR(50) | YES | NULL | CODE-BACKED | Name of the ops tool user or job triggering the fee recalculation. Passed through to Trade.UpdateInstrumentToFeeConfigTableV2 as @UpdatedByUser for audit. |
| 2 | @IsAlertTriggered | BIT OUTPUT | NO | - | CODE-BACKED | Returns 1 if any calculated fee deviates significantly from the previous value. Used by the calling tool to trigger notifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OPENQUERY | [AO-PRICE-LSN-ROR].Price.History.ClosingPrices | Linked Server | Fetches latest closing prices per instrument |
| FROM | Trade.GetInstrument | SELECT | Instrument catalog with type, currency, exchange |
| JOIN | Dictionary.Currency | SELECT | Maps SellCurrencyID to InterestRateID |
| JOIN | Dictionary.InterestRate | SELECT | Base interest rates and markups |
| JOIN | Dictionary.InterestRateOverride | SELECT | Three-level override hierarchy |
| APPLY | Trade.FnGetCurrentConversionRate | FUNCTION | Currency conversion rates |
| JOIN | Trade.FuturesMetaData | SELECT | Identifies futures instruments |
| EXEC | Trade.UpdateInstrumentToFeeConfigTableV2 | EXEC | Merges fees into live configuration |
| TVP | Trade.InstrumentToFeeConfigTypeV2 | Type | UDT for fee values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading OpsTool API | External | EXEC | Called from the TRDOPS admin tool for fee management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CalcOverNightFeeRates_TRDOPS (procedure)
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
| Trade.GetInstrument | View/Synonym | SELECT - instrument catalog |
| Dictionary.Currency | Table | JOIN - currency to interest rate mapping |
| Dictionary.InterestRate | Table | JOIN - base rates |
| Dictionary.InterestRateOverride | Table | LEFT JOIN x3 - override hierarchy |
| Trade.FnGetCurrentConversionRate | Function | OUTER APPLY - conversion rates |
| Trade.FuturesMetaData | Table | LEFT JOIN - futures identification |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Procedure | EXEC - merges fees |
| Trade.InstrumentToFeeConfigTypeV2 | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading OpsTool API | External | Calls this SP for TRDOPS fee calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LastPrice > 0 | Filter | Instruments without valid closing price excluded |
| ConversionRateAsk > 0 | Filter | Instruments without conversion rate excluded |
| OverNightFeePatternID IN (0,1) | Filter | Manual (2) instruments excluded |

---

## 8. Sample Queries

### 8.1 Compare fee outputs between standard and TRDOPS versions for MARGIN_TRADE

```sql
SELECT  InstrumentID, SettlementTypeID,
        BuyOverNightFee, SellOverNightFee
FROM    Trade.InstrumentToFeeConfigTable WITH (NOLOCK)
WHERE   SettlementTypeID = 5
ORDER BY InstrumentID;
```

### 8.2 Check MARGIN_TRADE interest rates without markup

```sql
SELECT  ir.InstrumentTypeID, ir.SettlementTypeID,
        ir.InterestRateBuy, ir.InterestRateSell,
        ir.MarkupBuy, ir.MarkupSell
FROM    Dictionary.InterestRate ir WITH (NOLOCK)
WHERE   ir.SettlementTypeID = 5;
```

### 8.3 Execute the TRDOPS fee calculation

```sql
DECLARE @AlertTriggered BIT;
EXEC Trade.CalcOverNightFeeRates_TRDOPS @AppLoginName = 'ops_admin', @IsAlertTriggered = @AlertTriggered OUTPUT;
SELECT @AlertTriggered AS IsAlertTriggered;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trading OpsTool API - InterestRate HLD | Confluence | TRDOPS fee management context and admin API integration |
| Interest Rates (TCM) | Confluence | Business context for MARGIN_TRADE fee calculation differences |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CalcOverNightFeeRates_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CalcOverNightFeeRates_TRDOPS.sql*
