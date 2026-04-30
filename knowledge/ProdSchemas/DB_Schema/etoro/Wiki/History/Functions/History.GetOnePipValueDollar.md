# History.GetOnePipValueDollar

> Scalar function that computes the USD-denominated value of one pip for a given instrument - the foundational P&L unit used by History.GetNetProfit to convert raw pip movements into dollar gains/losses.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollar(@CID, @InstrumentID, @ProviderID, @IsBuy, @pSpreadedPipBid, @pSpreadedPipAsk, @pPercision, @PriceXML) RETURNS MONEY` |
| **Author** | Adi Cohn, 2010-02-18 |
| **Purpose** | One-pip USD value for P&L calculation - primary variant using XML price snapshot |

---

## 1. Business Meaning

`History.GetOnePipValueDollar` answers: *"In US dollars, what is the value of moving one pip for this instrument?"* A "pip" (percentage in point) is the smallest standard price movement for a currency pair or instrument - for EUR/USD, 0.0001; for USD/JPY, 0.01. By multiplying pip count by this function's result, callers convert raw price movements into dollar P&L.

The function is the price-snapshot variant: it accepts an `@PriceXML` parameter containing a real-time price feed snapshot, parses it into an in-memory table, and uses those prices for FX rate lookups. This makes it suitable for batch P&L recomputation (pass a snapshot taken at position close time) without hitting live price tables repeatedly.

The primary consumer is `History.GetNetProfit` (batch #23), which calls this function for each position row to calculate realized P&L.

**Family overview** - this function is one of six closely related GetOnePipValueDollar variants in the History schema:
- `GetOnePipValueDollar` (this): XML price snapshot, spread-adjusted, SpreadGroup-adjusted for cross pairs. Primary - used by History.GetNetProfit.
- `GetOnePipValueDollarForDealing`: Uses Trade.LastWeekPrices, same spread/SpreadGroup logic. Used by History.GetNetProfitForDealing.
- `GetOnePipValueDollarForDealing_2`: Exact duplicate of ForDealing. No active consumers.
- `GetOnePipValueDollarForDealing_old`: Older ForDealing without SpreadGroup adjustment. No active consumers.
- `GetOnePipValueDollarForDealing_org`: Identical to _old. No active consumers.
- `GetOnePipValueDollarHedge`: XML snapshot, no spread params, no @CID, simplified cross logic. Called from Dealing application.

---

## 2. Business Logic

### 2.1 One-Pip USD Value Formula

**What**: Computes the USD value of one pip by applying DollarRatio (a per-instrument pip value in quote currency) and converting to USD using the appropriate FX rate.

**Columns/Parameters Involved**: `@InstrumentID`, `@IsBuy`, `@PriceXML`, `Trade.Instrument.DollarRatio`, `Trade.Instrument.BuyCurrencyID`, `Trade.Instrument.SellCurrencyID`

**Rules** - Three cases based on currency pair structure:

**Case 1: SellCurrencyAbbr = 'USD'** (e.g., EUR/USD, GBP/USD - "direct" USD pairs)
- `@Result = Trade.Instrument.DollarRatio`
- No FX conversion needed: DollarRatio is already expressed in USD per pip for these instruments
- This is the simplest case, ~majority of forex instruments

**Case 2: BuyCurrencyAbbr = 'USD'** (e.g., USD/JPY, USD/CHF - "indirect" USD pairs)
- `@Result = DollarRatio / (Bid + @SpreadBid)` for buys; `DollarRatio / (Ask + @SpreadAsk)` for sells
- The denominator is the current price of the instrument, used to convert from quote currency (JPY, CHF) back to USD
- Spread is added/subtracted from the price

**Case 3: Cross pair** (neither currency is USD, e.g., GBP/JPY, EUR/CHF)
- Two sub-cases based on which USD cross-instrument exists in Trade.Instrument:
  - **Sub-case 3a**: If `USD/SellCurrency` exists (e.g., USD/JPY): `DollarRatio / (Bid + SpreadGroup_Bid)` using the USD/Sell cross instrument's price
  - **Sub-case 3b**: If `SellCurrency/USD` exists (e.g., CHF/USD): `DollarRatio * (Bid + SpreadGroup_Bid)` using the Sell/USD cross instrument's price
- Cross cases use SpreadGroup adjustment: `CAST(TGSG.Bid AS DECIMAL(16,8)) / POWER(10, TPVI.Precision)` added to Bid, where TGSG = Trade.GetSpreadGroup for the customer's SpreadGroupID + ProviderID + InstrumentID

**Fallback**: If no currency data found for the instrument, @Result remains 0.

**Final result**: `ROUND(@Result, @Occuracy)` where Occuracy = Trade.Provider.Occuracy for the given ProviderID.

### 2.2 XML Price Parsing

**What**: Prices are passed as XML (a snapshot of the live price feed) and parsed into an in-memory table variable.

**Rules**:
- `@PriceXML` format: `<Prices><Instrument @ID="{InstrumentID}" @RateAsk="{price}" @RateBid="{price}" /></Prices>`
- Parsed into `@PriceTable (ProviderID INT, InstrumentID INT, Bid dtPrice, Ask dtPrice)` using `.nodes('Prices/Instrument')`
- This allows a single XML snapshot to be used for multiple function calls in the same batch without repeated live table reads

### 2.3 Spread Adjustment

**What**: Customer spread is applied to the raw price before computing the pip value.

**Rules**:
- `@SpreadBid = CONVERT(DECIMAL(16,8), @pSpreadedPipBid) / POWER(10, @pPercision)` - converts raw pip spread to decimal
- `@SpreadAsk = CONVERT(DECIMAL(16,8), @pSpreadedPipAsk) / POWER(10, @pPercision)`
- If @CID IS NULL -> both spreads = 0 (no spread adjustment)
- Spread is added to the price denominator (Case 2) or intermediate conversion price (Case 3)

---

## 3. Data Overview

Execution blocked (EXECUTE permission not granted to McpUserRO for scalar functions). Based on formula:

| Instrument Type | Expected Result | Example |
|-----------------|-----------------|---------|
| EUR/USD (direct) | DollarRatio (e.g., $10 for 1 standard lot) | Sell=USD: result = DollarRatio directly |
| USD/JPY (indirect) | DollarRatio / ~150 (current JPY rate) | ~$0.067 per pip per unit |
| GBP/JPY (cross) | DollarRatio / ~150 with USD/JPY cross | Computed via USD/JPY intermediate |

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INTEGER | Customer ID. If NULL -> spread = 0. If set -> resolves SpreadGroupID for cross-pair spread adjustment. |
| 2 | @InstrumentID | INTEGER | Trading instrument. Used to look up BuyCurrencyID, SellCurrencyID, DollarRatio from Trade.Instrument. |
| 3 | @ProviderID | INTEGER | Liquidity provider. Used to look up Occuracy (rounding precision) from Trade.Provider and filter price table. |
| 4 | @IsBuy | INTEGER | Position direction: 1=buy (uses Bid in price lookups), 0=sell (uses Ask). |
| 5 | @pSpreadedPipBid | dtPrice | Raw spread in pips for the bid side. Divided by POWER(10, @pPercision) to get decimal spread. NULL treated as 0. |
| 6 | @pSpreadedPipAsk | dtPrice | Raw spread in pips for the ask side. NULL treated as 0. |
| 7 | @pPercision | TINYINT | Decimal precision for spread conversion. Typically the instrument's pip precision. NULL treated as 0. |
| 8 | @PriceXML | XML | XML snapshot of current prices in format: `<Prices><Instrument @ID="..." @RateAsk="..." @RateBid="..." /></Prices>`. Parsed into in-memory @PriceTable. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD value of one pip for the instrument. Returns 0 if instrument has no currency mapping or no matching prices in @PriceXML. Rounded to Trade.Provider.Occuracy decimal places. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID | Trade.Provider | Query (cross-schema) | Reads Occuracy for rounding precision |
| @InstrumentID | Trade.Instrument | Query (cross-schema) | Reads BuyCurrencyID, SellCurrencyID, DollarRatio |
| @InstrumentID | Dictionary.Currency | Query (cross-schema) | Reads Abbreviation for buy/sell currency 3-letter code |
| @CID | Customer.Customer | Query (cross-schema) | Reads SpreadGroupID for cross-pair spread adjustment |
| SpreadGroupID | Trade.GetSpreadGroup | Query (cross-schema) | Reads spread group bid for cross-pair adjustment |
| @InstrumentID | Trade.ProviderToInstrument | Query (cross-schema) | Reads Precision for spread/SpreadGroup conversion |
| @PriceXML | @PriceTable (in-memory) | XML parse | Price snapshot parsed from XML parameter |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| History.GetNetProfit | Function (#23 this batch) | ACTIVE - calls this function to compute pip USD value for each position's P&L calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetOnePipValueDollar (scalar function)
|--> Trade.Provider (cross-schema)
|--> Trade.Instrument (cross-schema)
|--> Dictionary.Currency (cross-schema)
|--> Customer.Customer (cross-schema)
|--> Trade.GetSpreadGroup (view, cross-schema)
+--> Trade.ProviderToInstrument (cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Provider | Table (cross-schema) | Occuracy (rounding precision) |
| Trade.Instrument | Table (cross-schema) | BuyCurrencyID, SellCurrencyID, DollarRatio |
| Dictionary.Currency | Table (cross-schema) | Currency abbreviation for USD case detection |
| Customer.Customer | Table (cross-schema) | SpreadGroupID for cross-pair spread calc (when @CID not NULL) |
| Trade.GetSpreadGroup | View (cross-schema) | Spread group bid for cross-pair spread adjustment |
| Trade.ProviderToInstrument | Table (cross-schema) | Precision for spread scaling in cross-pair adjustment |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| History.GetNetProfit | YES |

---

## 7. Technical Details

### 7.1 Variant Comparison

| Function | Price Source | Spread Params | @CID | Cross Pair Adjustment | Consumer |
|----------|-------------|---------------|------|-----------------------|---------|
| GetOnePipValueDollar | @PriceXML (snapshot) | Yes | Yes | SpreadGroup-adjusted | History.GetNetProfit |
| GetOnePipValueDollarForDealing | Trade.LastWeekPrices | Yes | Yes | SpreadGroup-adjusted | History.GetNetProfitForDealing |
| GetOnePipValueDollarForDealing_2 | Trade.LastWeekPrices | Yes | Yes | SpreadGroup-adjusted | None (duplicate) |
| GetOnePipValueDollarForDealing_old | Trade.LastWeekPrices | Yes | Yes | Simple @SpreadBid only | None (legacy) |
| GetOnePipValueDollarForDealing_org | Trade.LastWeekPrices | Yes | Yes | Simple @SpreadBid only | None (legacy) |
| GetOnePipValueDollarHedge | @PriceXML (snapshot) | No | No | Raw DollarRatio/Bid only | Dealing app (GRANT) |

---

## 8. Sample Queries

### 8.1 Compute one-pip USD value for EUR/USD

```sql
-- Get one-pip USD value for EUR/USD (instrument 1) with XML price snapshot
DECLARE @PriceXML XML = '<Prices><Instrument ID="1" RateAsk="110000" RateBid="109990" /></Prices>'
SELECT History.GetOnePipValueDollar(
    14866508,  -- @CID
    1,         -- @InstrumentID (EUR/USD)
    1,         -- @ProviderID
    1,         -- @IsBuy
    1,         -- @pSpreadedPipBid
    1,         -- @pSpreadedPipAsk
    4,         -- @pPercision
    @PriceXML  -- @PriceXML
) AS OnePipUSD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.2/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollar | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollar.sql*
