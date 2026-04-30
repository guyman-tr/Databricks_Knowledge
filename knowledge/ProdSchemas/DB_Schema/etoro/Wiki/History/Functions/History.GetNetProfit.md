# History.GetNetProfit

> Scalar function that computes the USD P&L for a single position using an XML price snapshot - the core P&L formula: (current price - open price) in pips * lot count * one-pip USD value / lot size.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetNetProfit(@PositionID bigint, @PriceXML XML, @ProviderID int) RETURNS MONEY` |
| **Author** | Bonnie (17/11/2021 - changed positionID to bigint) |
| **Purpose** | Per-position P&L calculation using XML price snapshot |

---

## 1. Business Meaning

`History.GetNetProfit` computes the net profit in USD for a single position (`@PositionID`) at a given set of prices passed as `@PriceXML`. It is the P&L computation engine used by `History.GetCustomersUnrealizedData` to sum unrealized P&L across a customer's portfolio.

The function queries BOTH `History.Position` and `Trade.Position` via a UNION to find the position regardless of whether it is still open (Trade.Position) or has been archived (History.Position). This makes it suitable for computing P&L on any position in any state.

The core formula (derived from standard pip-based forex P&L):
1. **Pip count**: Current price minus open price, in pips (multiplied by POWER(10, Precision))
2. **Lot multiplier**: LotCountDecimal
3. **One-pip USD value**: `History.GetOnePipValueDollar(...)` / (Benchmark per unit)
4. **Result**: `PipCount * LotCount * OnePipValuePerUnit`

The spread-adjusted price is used for pip counting: for buy positions, the current price is `Bid + SpreadedPipBid/10^Precision`; for sell positions, `Ask + SpreadedPipAsk/10^Precision`.

---

## 2. Business Logic

### 2.1 P&L Formula

**What**: Full forex pip-based P&L calculation in USD.

**Columns/Parameters Involved**: `@PositionID`, `@PriceXML`, `InitForexRate`, `SpreadedPipBid/Ask`, `LotCountDecimal`, `AmountInUnitsDecimal`

**Step 1 - Pip Count**:
```
CASE IsBuy
  WHEN 1: (TCRP.Bid + SpreadedPipBid/10^Precision) - InitForexRate  [long: current bid minus open price]
  ELSE:   InitForexRate - (TCRP.Ask + SpreadedPipAsk/10^Precision)  [short: open price minus current ask]
END * POWER(10, Precision)
```

**Step 2 - Lot Multiplier**: `LotCountDecimal`

**Step 3 - One-Pip Value Per Unit**:
```
History.GetOnePipValueDollar(CID, InstrumentID, ProviderID, IsBuy, SpreadedPipBid, SpreadedPipAsk, Precision, @PriceXML)
/ (Benchmark / (AmountInUnitsDecimal / LotCountDecimal))
```
- `Benchmark / (AmountInUnitsDecimal / LotCount)` = lot size for this position
- Dividing the pip value by lot size normalizes it to per-unit

**Result**: `PipCount * LotCount * OnePipValuePerUnit`

### 2.2 XML Price Parsing

**What**: Prices are parsed from @PriceXML into an in-memory table.

**Rules**:
- Same format as `History.GetOnePipValueDollar`: `<Prices><Instrument @ID="..." @RateAsk="..." @RateBid="..." /></Prices>`
- The same XML is also passed to `History.GetOnePipValueDollar` inside the formula

### 2.3 Position Lookup (History + Trade UNION)

**What**: Finds the position in either the archive or live tables.

**Rules**:
- `SELECT 10 cols FROM History.Position WHERE PositionID = @PositionID`
- UNION
- `SELECT same 10 cols FROM Trade.Position WHERE PositionID = @PositionID`
- Result should always be 0 or 1 rows (PositionID is unique across both tables in practice)

---

## 3. Data Overview

Execution blocked (EXECUTE permission not granted for scalar functions; History.Position routes to EtoroArchive). Based on the formula, returns a MONEY value representing the USD P&L for the position at the given @PriceXML prices.

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @PositionID | bigint | The position to compute P&L for. Searched in both History.Position (archived) and Trade.Position (live). |
| 2 | @PriceXML | XML | Current prices as XML snapshot. Format: `<Prices><Instrument @ID="..." @RateAsk="..." @RateBid="..." /></Prices>`. Used for both pip-count price lookup and for the GetOnePipValueDollar call. |
| 3 | @ProviderID | int | Provider ID for price table filtering and pip value calculation. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD P&L for the position at the given prices. Positive = profit, negative = loss. NULL if position not found in either table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | History.Position | Query (EtoroArchive) | Retrieves position details for archived positions |
| @PositionID | Trade.Position | Query (cross-schema) | Retrieves position details for live positions |
| InstrumentID + ProviderID | Trade.ProviderToInstrument | Query (cross-schema) | Retrieves Precision and Benchmark for lot size calculation |
| (all) | History.GetOnePipValueDollar | Function call | Computes one-pip USD value for the position |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| History.GetCustomersUnrealizedData | Stored Procedure | ACTIVE - sums `History.GetNetProfit(PositionID, @PriceXML, @ProviderID)` across all customer positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetNetProfit (scalar function)
|--> History.Position (view -> EtoroArchive)
|--> Trade.Position (table, cross-schema)
|--> Trade.ProviderToInstrument (table, cross-schema)
+--> History.GetOnePipValueDollar (scalar function)
        |--> Trade.Provider, Trade.Instrument, Dictionary.Currency
        |--> Customer.Customer, Trade.GetSpreadGroup, Trade.ProviderToInstrument
```

---

## 7. Technical Details

### 7.1 Companion Function Comparison

| Function | Price Source | Params | Consumers |
|----------|-------------|--------|-----------|
| GetNetProfit | @PriceXML (snapshot) | PositionID, PriceXML, ProviderID | History.GetCustomersUnrealizedData |
| GetNetProfitForDealing | Trade.LastWeekPrices | PositionID only | Trade.DealingMasterQuery |

The "ForDealing" variant is simpler (1 param) and uses last-week prices, making it suitable for bulk queries in DealingMasterQuery where passing XML per-row is impractical.

### 7.2 Performance Warning

Calling this scalar function per-row across thousands of positions (as `History.GetCustomersUnrealizedData` does) creates a known SQL Server scalar UDF performance problem. Each call executes multiple sub-queries against EtoroArchive (History.Position), Trade.Position, Trade.ProviderToInstrument, and the entire `GetOnePipValueDollar` call chain.

---

## 8. Sample Queries

### 8.1 Get P&L for a specific position

```sql
DECLARE @PriceXML XML = '<Prices><Instrument ID="1" RateAsk="110000" RateBid="109990" /></Prices>'
SELECT History.GetNetProfit(123456789, @PriceXML, 1) AS PositionPnL
```

### 8.2 Pattern used by History.GetCustomersUnrealizedData

```sql
-- Sum unrealized P&L across customer positions
DECLARE @PriceXML XML = '...'
DECLARE @ProviderID INT = 1
SELECT
    ISNULL(SUM(History.GetNetProfit(PositionID, @PriceXML, @ProviderID)), 0) AS CustomersUnrealizedPNL
FROM Trade.Position
WHERE CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.2/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - EtoroArchive blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetNetProfit | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetNetProfit.sql*
