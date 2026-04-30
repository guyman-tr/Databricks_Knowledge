# History.GetOnePipValueDollarForDealing

> Scalar function that computes the USD value of one pip using Trade.LastWeekPrices instead of an XML snapshot - the "Dealing" variant of GetOnePipValueDollar used by History.GetNetProfitForDealing.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollarForDealing(@CID, @InstrumentID, @ProviderID, @IsBuy, @pSpreadedPipBid, @pSpreadedPipAsk, @pPercision) RETURNS MONEY` |
| **Purpose** | One-pip USD value using last-week price data - "Dealing" variant without XML price parameter |

---

## 1. Business Meaning

`History.GetOnePipValueDollarForDealing` is the "Dealing" variant of `History.GetOnePipValueDollar`. It computes the same one-pip USD value using the same three-case currency logic (direct USD pair, indirect USD pair, cross pair), but sources prices from `Trade.LastWeekPrices` instead of an XML snapshot parameter. This makes it suitable for Dealing engine calculations where a pre-built price XML is not available.

The key difference from the base function: no `@PriceXML` parameter. Prices come from `Trade.LastWeekPrices` - a table holding end-of-week prices used for rollover/financing calculations. The ProviderID filter on the price table join is commented out (`--AND TCRP.ProviderID = @ProviderID`), meaning the first matching instrument price is used regardless of provider.

The primary consumer is `History.GetNetProfitForDealing` (batch #24).

See `History.GetOnePipValueDollar.md` for the full one-pip value formula and variant comparison table.

---

## 2. Business Logic

### 2.1 One-Pip Value Formula (Same Three Cases as Base Function)

Same three-case logic as `History.GetOnePipValueDollar`:
- Case 1 (SellCurrencyAbbr = 'USD'): `DollarRatio` directly
- Case 2 (BuyCurrencyAbbr = 'USD'): `DollarRatio / (TCRP.Bid + @SpreadBid)` or `DollarRatio / (TCRP.Ask + @SpreadAsk)` - prices from `Trade.LastWeekPrices`
- Case 3 (cross pair): `DollarRatio / (TCRP.Bid + SpreadGroup_adjustment)` or `DollarRatio * (TCRP.Bid + SpreadGroup_adjustment)` - with SpreadGroup adjustment from Trade.GetSpreadGroup + Trade.ProviderToInstrument
- Fallback: 0 if no instrument mapping found

### 2.2 Key Differences from GetOnePipValueDollar

| Aspect | GetOnePipValueDollar | GetOnePipValueDollarForDealing |
|--------|---------------------|-------------------------------|
| Price source | `@PriceXML` parsed to table | `Trade.LastWeekPrices` |
| ProviderID filter on prices | YES (`AND TCRP.ProviderID = @ProviderID`) | NO (commented out) |
| @PriceXML parameter | Required | Not present |
| Cross pair spread | SpreadGroup-adjusted (CAST/POWER) | SpreadGroup-adjusted (same) |
| Use case | Batch P&L with snapshot prices | Dealing engine P&L with week prices |

---

## 3. Data Overview

Execution blocked (EXECUTE permission not granted to McpUserRO for scalar functions). Behavior matches `History.GetOnePipValueDollar` with Trade.LastWeekPrices as the price source.

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INTEGER | Customer ID. If NULL -> spread = 0. If set -> resolves SpreadGroupID for cross-pair spread adjustment. |
| 2 | @InstrumentID | INTEGER | Trading instrument. Used for BuyCurrencyID, SellCurrencyID, DollarRatio lookup. |
| 3 | @ProviderID | INTEGER | Liquidity provider. Used for Occuracy (rounding precision). NOTE: ProviderID filter on price table is commented out - provider filtering is NOT applied. |
| 4 | @IsBuy | INTEGER | Position direction: 1=buy, 0=sell. |
| 5 | @pSpreadedPipBid | dtPrice | Raw spread in pips for bid side. NULL treated as 0. |
| 6 | @pSpreadedPipAsk | dtPrice | Raw spread in pips for ask side. NULL treated as 0. |
| 7 | @pPercision | TINYINT | Decimal precision for spread conversion. NULL treated as 0. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD value of one pip. Returns 0 if no instrument mapping. Rounded to Trade.Provider.Occuracy decimal places. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID | Trade.Provider | Query (cross-schema) | Occuracy for rounding |
| @InstrumentID | Trade.Instrument | Query (cross-schema) | BuyCurrencyID, SellCurrencyID, DollarRatio |
| @InstrumentID | Dictionary.Currency | Query (cross-schema) | Currency abbreviation for case detection |
| @CID | Customer.Customer | Query (cross-schema) | SpreadGroupID (cross-pair only) |
| SpreadGroupID | Trade.GetSpreadGroup | Query (cross-schema) | Spread group bid for cross-pair |
| @InstrumentID | Trade.ProviderToInstrument | Query (cross-schema) | Precision for spread scaling |
| @InstrumentID | Trade.LastWeekPrices | Query (cross-schema) | Bid/Ask prices (no ProviderID filter) |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| History.GetNetProfitForDealing | Function (#24 this batch) | ACTIVE - calls this function to compute pip USD value for P&L |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetOnePipValueDollarForDealing (scalar function)
|--> Trade.Provider (cross-schema)
|--> Trade.Instrument (cross-schema)
|--> Dictionary.Currency (cross-schema)
|--> Customer.Customer (cross-schema)
|--> Trade.GetSpreadGroup (view, cross-schema)
|--> Trade.ProviderToInstrument (cross-schema)
+--> Trade.LastWeekPrices (cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table | Occuracy |
| Trade.Instrument | Table | BuyCurrencyID, SellCurrencyID, DollarRatio |
| Dictionary.Currency | Table | Currency abbreviation |
| Customer.Customer | Table | SpreadGroupID |
| Trade.GetSpreadGroup | View | Spread group bid |
| Trade.ProviderToInstrument | Table | Precision |
| Trade.LastWeekPrices | Table | Bid/Ask prices |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| History.GetNetProfitForDealing | YES |

---

## 7. Technical Details

For variant comparison table see `History.GetOnePipValueDollar.md` Section 7.1.

---

## 8. Sample Queries

### 8.1 Compute one-pip USD value for EUR/USD using last-week prices

```sql
SELECT History.GetOnePipValueDollarForDealing(
    14866508,  -- @CID
    1,         -- @InstrumentID (EUR/USD)
    1,         -- @ProviderID
    1,         -- @IsBuy
    1,         -- @pSpreadedPipBid
    1,         -- @pSpreadedPipAsk
    4          -- @pPercision
) AS OnePipUSD_Dealing
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 8.8/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollarForDealing | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollarForDealing.sql*
