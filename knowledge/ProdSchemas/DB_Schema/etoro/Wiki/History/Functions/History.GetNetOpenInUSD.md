# History.GetNetOpenInUSD

> Scalar function that computes the notional open value in USD for a given instrument position at a historical date - the "History" counterpart to Internal.GetNetOpenInUSD, adding a @HistoryDate parameter to look up prices from the historical Price server archive rather than current live prices.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetNetOpenInUSD(@InstrumentID INTEGER, @OpenedUnits INTEGER, @HistoryDate DATETIME) RETURNS MONEY` |
| **Purpose** | Historical notional USD value calculation for hedge and execution volume reporting |

---

## 1. Business Meaning

`History.GetNetOpenInUSD` computes the USD-denominated notional value of a position, given the instrument, the number of units held (positive = long/buy, negative = short/sell), and a historical date. It is the historical-price variant of `Internal.GetNetOpenInUSD` (which uses current live prices from Trade.CurrencyPrice); this function instead looks up prices from `dbo.HistoryCurrencyPrice` (a synonym pointing to `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice]`) at the specified date.

The core business purpose is: **for a closed or archived position, what was its USD notional value at a specific point in time?** This is needed for execution volume reporting and hedge analytics. The primary active consumer is `Internal.GetExecutionVolumeInUSD`, which calls this function to sum notional USD volumes across historical positions and hedges using the price at position open (InitForexRate).

**Counterpart relationship**: `Internal.GetNetOpenInUSD(@InstrumentID, @OpenedUnits)` uses live Trade.CurrencyPrice and is called from Hedge procedures for real-time calculations. `History.GetNetOpenInUSD(@InstrumentID, @OpenedUnits, @HistoryDate)` uses historical prices and is called for analytical queries over closed positions. The `Hedge.*` stored procedures that once called `History.GetNetOpenInUSD` have all had those calls commented out (replaced with 0) as of 2020, leaving `Internal.GetExecutionVolumeInUSD` as the primary active consumer.

---

## 2. Business Logic

### 2.1 Notional USD Value Formula

**What**: Computes `@OpenedUnits * Unit * UnitMargin * FX_rate_to_USD` where the FX rate comes from historical price data.

**Columns/Parameters Involved**: `@InstrumentID`, `@OpenedUnits`, `@HistoryDate`, `Trade.ProviderToInstrument.Unit`, `Trade.ProviderToInstrument.UnitMargin`, `Trade.GetInstrumentMappingToUSDInstrument.IsSellCurrency`, `dbo.HistoryCurrencyPrice.Ask/Bid`

**Rules**:
- Step 1: `@OpenedUnits * PTI.Unit * PTI.UnitMargin` = base notional in instrument denomination
- Step 2: Multiply by FX rate to convert to USD, sourced from `dbo.HistoryCurrencyPrice` at the USD-conversion instrument (`GI.USDInstrumentID`) where `@HistoryDate BETWEEN HCP.ValidFrom AND HCP.ValidTo`
- FX rate direction logic:
  - If `IsSellCurrency = 0` (price denominated in USD): divide by Ask (for longs) or Bid (for shorts): `1/Ask` or `1/Bid`
  - If `IsSellCurrency = 1` (price denominated in foreign currency): multiply by Ask (for longs) or Bid (for shorts)
- Major currency correction: `CASE WHEN TI.IsMajor = 1 AND GI.IsSellCurrency = 1 THEN -1 ELSE 1 END` - negates the result for major currency instruments where the sell-currency direction applies
- Falls back to `@OpenedUnits * PTI.Unit * PTI.UnitMargin` (FX rate = 1) if `Trade.GetInstrumentMappingToUSDInstrument` returns no mapping for the instrument
- Returns 0 if NULL (ISNULL(@Result, 0))

### 2.2 Historical vs Live Price Distinction

**What**: The key difference from Internal.GetNetOpenInUSD is the price source.

**Rules**:
- `Internal.GetNetOpenInUSD` joins `Trade.CurrencyPrice` (live prices) - no date parameter
- `History.GetNetOpenInUSD` joins `dbo.HistoryCurrencyPrice` (= `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice]`) filtered by `@HistoryDate BETWEEN ValidFrom AND ValidTo`
- Callers pass the position's `InitForexRate` timestamp as `@HistoryDate` to get the price at execution time
- If the Price server has no record for the date/instrument combination, @@ROWCOUNT = 0 triggers the fallback (rate = 1)

### 2.3 Direction Logic (IsSellCurrency Flag)

**What**: Determines whether to multiply or divide by the FX rate depending on the instrument's quote convention.

**Rules**:
- `IsSellCurrency = 0`: The instrument's rate is expressed as "X units of foreign per 1 USD" -> to get USD value, divide by the rate: `1/Ask` (long) or `1/Bid` (short)
- `IsSellCurrency = 1`: The instrument's rate is expressed as "X USD per 1 unit of foreign" -> to get USD value, multiply by the rate: `Ask` (long) or `Bid` (short)
- The `TI.IsMajor = 1 AND IsSellCurrency = 1` negation handles major currency pairs where the calculation direction is reversed relative to USD

---

## 3. Data Overview

Direct execution blocked (dbo.HistoryCurrencyPrice routes to `[AO-PRICE-LSN-ROR]` Price server; EXECUTE permission not granted to McpUserRO for scalar functions). Based on the formula:

| @InstrumentID | @OpenedUnits | @HistoryDate | Expected Result | Meaning |
|---|---|---|---|---|
| 1 (EUR/USD) | 100 | 2024-01-01 | ~$100 * unit * unitMargin * EUR/USD_rate | EUR/USD long 100 units notional at 2024-01-01 |
| 1 (EUR/USD) | -100 | 2024-01-01 | ~negative value | EUR/USD short 100 units |
| (unmapped) | 100 | any | 100 * unit * unitMargin | Fallback - rate assumed 1 |

---

## 4. Elements

### Parameters

| # | Parameter | Type | Direction | Description |
|---|-----------|------|-----------|-------------|
| 1 | @InstrumentID | INTEGER | IN | The trading instrument. Used to JOIN Trade.ProviderToInstrument and Trade.GetInstrumentMappingToUSDInstrument for unit and FX mapping. |
| 2 | @OpenedUnits | INTEGER | IN | Number of units in the position. Positive = long/buy, negative = short/sell. Used both in the calculation and to determine Ask vs Bid rate direction. |
| 3 | @HistoryDate | DATETIME | IN | Historical date for price lookup. Filters dbo.HistoryCurrencyPrice WHERE @HistoryDate BETWEEN ValidFrom AND ValidTo. Callers typically pass the position's InitForexRate or OpenOccurred timestamp. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD-denominated notional value of the position at @HistoryDate. Positive for longs (after major-currency sign correction), negative or positive for shorts depending on instrument type. Returns 0 if instrument has no USD mapping and no provider-to-instrument row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | JOIN (cross-schema) | Source of Unit and UnitMargin for base notional calculation |
| @InstrumentID | Trade.GetInstrumentMappingToUSDInstrument | JOIN (cross-schema) | Resolves USDInstrumentID and IsSellCurrency for FX conversion |
| GI.InstrumentID | Trade.Instrument | JOIN (cross-schema) | Source of IsMajor flag for major-currency sign correction |
| GI.USDInstrumentID + @HistoryDate | dbo.HistoryCurrencyPrice | JOIN (Price server synonym) | Historical Ask/Bid prices for FX rate. dbo.HistoryCurrencyPrice = [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice] |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetExecutionVolumeInUSD | Function | ACTIVE - calls History.GetNetOpenInUSD to sum notional USD volume across Trade.Position, History.Position, Trade.Hedge, History.Hedge using InitForexRate as @HistoryDate |
| Hedge.GetRealizedCustomersData | Stored Procedure | COMMENTED OUT (as of 2020) - replaced with 0 in ExecutionVolumeInUSD calculation |
| Hedge.GetUnrealizedCustomersData | Stored Procedure | COMMENTED OUT (2020) - replaced with 0 |
| Hedge.AddAccountPositionsFromNetting | Stored Procedure | COMMENTED OUT (2020, pini) - replaced with Internal.GetNetOpenInUSD equivalent |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetNetOpenInUSD (scalar function)
|--> Trade.ProviderToInstrument (table, cross-schema)
|--> Trade.GetInstrumentMappingToUSDInstrument (view/table, cross-schema)
|--> Trade.Instrument (table, cross-schema)
+--> dbo.HistoryCurrencyPrice (synonym -> [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPrice])
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table (cross-schema) | JOIN for Unit and UnitMargin - base notional components |
| Trade.GetInstrumentMappingToUSDInstrument | View/Function (cross-schema) | JOIN for USDInstrumentID and IsSellCurrency - FX mapping |
| Trade.Instrument | Table (cross-schema) | JOIN for IsMajor flag - major currency sign correction |
| dbo.HistoryCurrencyPrice | Synonym (Price server) | JOIN for Ask/Bid at @HistoryDate BETWEEN ValidFrom AND ValidTo |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| Internal.GetExecutionVolumeInUSD | YES - active consumer |
| Hedge.GetRealizedCustomersData | NO - commented out |
| Hedge.GetUnrealizedCustomersData | NO - commented out |
| Hedge.AddAccountPositionsFromNetting | NO - commented out |

---

## 7. Technical Details

### 7.1 Performance Notes

- Scalar UDF called row-by-row from Internal.GetExecutionVolumeInUSD across potentially large position/hedge datasets - this is a classic "scalar UDF performance anti-pattern" in SQL Server.
- Each call hits `Trade.ProviderToInstrument`, `Trade.GetInstrumentMappingToUSDInstrument`, `Trade.Instrument`, and the Price server synonym - multiple cross-schema lookups per call.
- `dbo.HistoryCurrencyPrice` is a linked-server synonym to the Price server - each call may cross a network boundary.

### 7.2 Companion Function

`Internal.GetNetOpenInUSD(@InstrumentID, @OpenedUnits)` - identical formula but uses live `Trade.CurrencyPrice` instead of historical prices and has no @HistoryDate parameter. Use for real-time position valuation; use `History.GetNetOpenInUSD` for historical/analytical position valuation.

---

## 8. Sample Queries

### 8.1 Compute notional USD value for a historical position

```sql
-- Compute the USD notional value for instrument 1 (EUR/USD),
-- 100 long units, at the position's historical open price date
DECLARE @InstrumentID INT = 1
DECLARE @Units INT = 100
DECLARE @PriceDate DATETIME = '2024-06-01 10:30:00'
SELECT History.GetNetOpenInUSD(@InstrumentID, @Units, @PriceDate) AS NotionalUSD
```

### 8.2 Aggregate historical execution volume in USD (as used by Internal.GetExecutionVolumeInUSD)

```sql
-- Sum of notional USD volumes for historical positions in a time window
SELECT SUM(ABS(History.GetNetOpenInUSD(InstrumentID, LotCountDecimal, InitForexRate))) AS TotalVolumeUSD
FROM History.Position WITH(NOLOCK)
WHERE InstrumentID = 1
  AND OpenOccurred BETWEEN '2024-01-01' AND '2024-12-31'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 found (1 active, 3 commented-out) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetNetOpenInUSD | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetNetOpenInUSD.sql*
