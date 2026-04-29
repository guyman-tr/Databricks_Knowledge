# BI_DB_dbo.BI_DB_CashRiskMatrix

> Daily cash-risk scenario matrix: for every open CFD position per customer, captures the instrument's bid/ask prices and 49 price-shock scenarios (±1% through ±100%, plus ±200%/±300%/±400%/±900%) showing the net open position in units that would remain within the customer's stop/limit bounds if the market moved by each shock amount — used by the Risk desk to assess net exposure at hypothetical price moves.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (open CFD positions) + DWH_dbo.Fact_CurrencyPriceWithSplit (prices) + DWH_dbo.V_Liabilities (TotalCash) via SP_CashRiskMatrix |
| **Refresh** | Daily (SP_CashRiskMatrix(@Date) — DELETE for @Date + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Not yet registered_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |

---

## 1. Business Meaning

`BI_DB_CashRiskMatrix` is the Risk desk's daily exposure-stress table. For every open, non-settled CFD position held by a valid customer, it records:

1. **The position context**: which instrument, which customer (CID), in which regulation/region, at what leverage, and whether it is long (IsBuy=1) or short (IsBuy=0).
2. **The current market prices**: Bid and Ask on the reporting date, plus a USD `ConversionRate` to normalize cross-currency instruments.
3. **The NOP column** (`UnitsNOP`): the customer's signed net open position in instrument units at the current price, where buy positions are positive and sell positions are negative: `(2×IsBuy−1) × AmountInUnitsDecimal`.
4. **49 scenario columns** (`UnitsNOP+1%` → `UnitsNOP+900%` and `UnitsNOP-1%` → `UnitsNOP-100%`): for each price-shock percentage, the sum of units that would be "in the money" against the customer's stop/limit — i.e., units whose limit order (for buys) or stop order (for sells) would have triggered, or units whose stop order (for buys) or limit order (for sells) would have triggered in adverse-move scenarios.
5. **TotalCash**: the customer's total cash balance from `V_Liabilities` on the same date, providing balance context alongside the position exposure.

**Key filters applied by the ETL**:
- Only open positions as of @Date: `OpenDateID <= @DateID AND (CloseDateID = 0 OR CloseDateID > @DateID)`
- Only non-settled (CFD) positions: `IsSettled = 0`
- Only valid customers: `Dim_Customer.IsValidCustomer = 1`
- Only instruments with `InstrumentID < 100000` (excludes internal/test instruments)

Rows are grouped by `(Date, CID, HedgeServerID, InstrumentID, InstrumentName, InstrumentType, IsBuy, Leverage, Regulation, Region, Bid, Ask, ConversionRate)` — one row per unique combination of customer + instrument + direction + leverage + price context on a given date. Multiple positions in the same group are summed.

**Production data (as of 2025-10-05)**: ~2.4M rows per day across 5 instrument types: ETF (1.2M), Stocks (1.0M), Currencies (76K), Commodities (74K), Indices (59K). Leverage distribution: ~74% at 1×, ~15% at 2×. TotalCash ranges from −$327K to $6.5M (avg ~$4,370).

---

## 2. Business Logic

### 2.1 ConversionRate Computation

**What**: Normalizes each instrument's price to USD using Bid/Ask cross-rates, enabling risk aggregation across multi-currency instruments.

**Columns Involved**: `ConversionRate`, `Bid`, `Ask`, `InstrumentID`

**Rules** (from SP_CashRiskMatrix `#Prices` construction):
- If `SellCurrencyID = 1` (instrument already quoted in USD): `ConversionRate = 1`
- If `BuyCurrencyID = 1` (USD is the base): `ConversionRate = 1 / (Bid if IsBuy=1 else Ask)`
- If neither currency is USD but a bridge instrument exists with `SellCurrencyID` as base and USD as quote: `ConversionRate = Conversion_Bid (if IsBuy=1) or Conversion_Ask`
- Otherwise (bridge instrument with USD as sell): `ConversionRate = 1 / (Conversion_Bid or Conversion_Ask)`
- NULL (208 rows in production) when no price record could be matched for the instrument on @DateID

### 2.2 Signed UnitsNOP

**What**: Net open position in instrument units, signed by direction.

**Formula**: `(2 × IsBuy − 1) × AmountInUnitsDecimal`
- IsBuy=1 (long): `UnitsNOP = +AmountInUnitsDecimal`
- IsBuy=0 (short): `UnitsNOP = −AmountInUnitsDecimal`

When multiple positions exist for the same (CID, InstrumentID, IsBuy, Leverage, HedgeServerID, price-context) group, the `UnitsNOP` values are SUM-aggregated.

### 2.3 Price-Scenario Columns (49 columns)

**What**: For each price shock level N%, the column `UnitsNOP+N%` contains the sum of `UnitsNOP` for positions whose **take-profit (LimitRate) or stop-loss (StopRate) would be triggered** at that price.

**Upside shock columns** (`UnitsNOP+1%` through `UnitsNOP+900%`):
- **Buy positions** (IsBuy=1): `CASE WHEN LimitRate >= Bid×(1+N%) THEN UnitsNOP ELSE 0 END`
  — "how many units does this customer have whose take-profit is at or above the shocked bid price?"
- **Sell positions** (IsBuy=0): `CASE WHEN StopRate >= Ask×(1+N%) THEN UnitsNOP ELSE 0 END`
  — "how many units does this customer have whose stop-loss is triggered at the shocked ask price?"
- Special case: For buy positions with `LimitRate = 0`, the ETL substitutes `LimitRate = 99999999` so it never prematurely truncates upside exposure.

**Downside shock columns** (`UnitsNOP-1%` through `UnitsNOP-100%`):
- **Buy positions** (IsBuy=1): `CASE WHEN StopRate <= Bid×(1−N%) THEN UnitsNOP ELSE 0 END`
  — "how many units does this customer have whose stop-loss is triggered at the shocked-down bid price?"
- **Sell positions** (IsBuy=0): `CASE WHEN LimitRate <= Ask×(1−N%) THEN UnitsNOP ELSE 0 END`
  — "how many units does this customer have whose take-profit is triggered at the shocked-down ask price?"

All scenario columns are then SUM-aggregated within the GROUP BY.

### 2.4 TotalCash Source

**What**: The customer's cash balance on the reporting date, from V_Liabilities.

**Formula**: `AVG(vl.TotalCash)` — LEFT JOIN V_Liabilities on `CID + DateID=@DateID`. `AVG` is used here because the #Stage table has one row per position (multiple per CID), so V_Liabilities.TotalCash is the same value repeated; AVG collapses it back to the single customer-day value. TotalCash = 0 for customers with no V_Liabilities row on @DateID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution means rows are spread evenly across distributions without a hash key. This is appropriate because the table has no dominant single-column lookup pattern and no co-location requirement. **CLUSTERED INDEX on Date** supports efficient date-range scans and per-date deletes during the nightly refresh.

Always filter by `[Date]` in any query to leverage the clustered index and avoid scanning all historical data. The table is very large (~2.4M rows/day × many months of history).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Exposure for a specific date | `WHERE [Date] = '2025-10-05'` — clustered index seek |
| Customer-level aggregate NOP | `WHERE [Date] = @d AND CID = @cid`, `SUM(UnitsNOP * Bid * ConversionRate)` for USD NOP |
| Regulation-level stress at +10% | `GROUP BY Regulation`, `SUM([UnitsNOP+10%] * Bid * ConversionRate)` |
| Instruments with no price coverage | `WHERE Bid IS NULL AND [Date] = @d` (~208 rows/day) |
| Long vs short NOP by instrument type | `GROUP BY InstrumentType, IsBuy`, `SUM(UnitsNOP)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON BI_DB_CashRiskMatrix.InstrumentID = di.InstrumentID` | Resolve full instrument metadata (ISIN, exchange, asset class) |
| DWH_dbo.Dim_Customer | `ON BI_DB_CashRiskMatrix.CID = dc.RealCID` | Customer demographics, country, verification level |
| DWH_dbo.V_Liabilities | `ON CID AND CAST([Date] AS INT in YYYYMMDD) = DateID` | Full balance breakdown alongside NOP |
| DWH_dbo.Dim_Regulation | `ON Regulation = dr.Name` | Regulation ID for joining to other reg-keyed tables |

### 3.4 Gotchas

- **NULL Bid/Ask/ConversionRate**: 208 rows per day where the instrument had no price in `Fact_CurrencyPriceWithSplit` on that date. These rows still contain valid `UnitsNOP` from positions — exclude or handle separately in USD-value calculations.
- **TotalCash is customer-level, not position-level**: All rows for the same CID on the same date share the same TotalCash value. Do not SUM TotalCash across rows for the same CID — use `MAX(TotalCash)` or group at CID level first.
- **ROUND_ROBIN distribution**: Joins on CID or InstrumentID will not be co-located. For large analytical queries joining this table to other tables, expect data movement.
- **InstrumentID < 100000 filter**: Applied at ETL time. Instruments with IDs ≥ 100,000 (internal/test) are excluded from this table.
- **IsSettled=0 filter**: Only CFD positions are included. Real-asset positions (stocks, crypto) held as settled positions are excluded.
- **IsValidCustomer=1 filter**: Customers with PlayerLevelID=4 (Popular Investors), LabelID IN (26,30), or CountryID=250 are excluded.
- **LimitRate=0 for buys**: The SP substitutes `99999999` for LimitRate when it is 0 and IsBuy=1, so upside scenarios always return UnitsNOP for unlimited-upside positions. A value of `UnitsNOP+1% = UnitsNOP+900%` (all equal) indicates a position with no take-profit set.
- **Scenario columns = 0 vs NULL**: Scenario columns are never NULL — they are either `UnitsNOP` (triggered) or `0` (not triggered), always decimal(16,8). When the scenario column equals `UnitsNOP`, the stop/limit is already within that shock range.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` |
| ★★★☆☆ | Tier 2 | `(Tier 2 — SP_CashRiskMatrix)` |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — live data / DDL structure)` |

#### Core Identity & Context (11 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for which the snapshot was computed. Corresponds to the SP parameter @Date. One nightly run per date; DELETE+INSERT pattern ensures exactly one set of rows per date. Clustered index key. (Tier 2 — SP_CashRiskMatrix) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 3 | TotalCash | money | YES | Customer's total cash balance from V_Liabilities on the same date. `AVG(vl.TotalCash)` — collapses to the single per-customer cash value. Range: −$327K to $6.5M (avg ~$4,370) in production. NULL for customers with no V_Liabilities row on @DateID. (Tier 2 — SP_CashRiskMatrix, sourced from DWH_dbo.V_Liabilities.TotalCash) |
| 4 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 5 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 6 | InstrumentName | varchar(50) | YES | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument via DWH_dbo.Dim_Instrument.Name) |
| 7 | InstrumentType | varchar(50) | YES | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentType via SP_Dim_Instrument) |
| 8 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 9 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 10 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — Dictionary.Regulation via DWH_dbo.Dim_Regulation.Name) |
| 11 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 1 — DWH_dbo.Dim_Country.Region via SP_Dictionaries_Country_DL_To_Synapse) |

#### Price Reference (3 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Bid | decimal(16,6) | YES | Raw bid price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 1 — DWH_dbo.Fact_CurrencyPriceWithSplit.Bid via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse). NULL for ~208 rows/day where no price record exists. |
| 13 | Ask | decimal(16,6) | YES | Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 1 — DWH_dbo.Fact_CurrencyPriceWithSplit.Ask via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse). NULL where no price record exists. |
| 14 | ConversionRate | decimal(16,6) | YES | ETL-computed USD conversion rate for this position direction. Logic: if SellCurrencyID=1 → 1.0; if BuyCurrencyID=1 → 1/Bid(IsBuy=1) or 1/Ask(IsBuy=0); if cross-rate via bridge instrument with Conversion_SellCurrencyID=1 → Conversion_Bid or Conversion_Ask; else → 1/Conversion_Bid-or-Ask. NULL where no price could be resolved. Multiply Bid × ConversionRate to get USD value per unit. (Tier 2 — SP_CashRiskMatrix) |

#### Net Open Position — Current (1 column)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 15 | UnitsNOP | decimal(16,8) | YES | Signed net open position in instrument units for this customer/instrument/direction/leverage group. Formula: `SUM((2×IsBuy−1) × AmountInUnitsDecimal)`. Positive for long positions, negative for short. Multiply by Bid × ConversionRate to get approximate USD notional exposure. (Tier 2 — SP_CashRiskMatrix) |

#### Price-Shock Upside Scenarios — 24 columns

Each column represents the sum of units within the group whose stop/limit would trigger at the shocked price. For buy positions: `SUM(CASE WHEN LimitRate >= Bid×(1+N%) THEN UnitsNOP ELSE 0 END)`. For sell positions: `SUM(CASE WHEN StopRate >= Ask×(1+N%) THEN UnitsNOP ELSE 0 END)`.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 16 | UnitsNOP+1% | decimal(16,8) | YES | Units within stop/limit bounds at +1% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 17 | UnitsNOP+2% | decimal(16,8) | YES | Units within stop/limit bounds at +2% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 18 | UnitsNOP+3% | decimal(16,8) | YES | Units within stop/limit bounds at +3% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 19 | UnitsNOP+4% | decimal(16,8) | YES | Units within stop/limit bounds at +4% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 20 | UnitsNOP+5% | decimal(16,8) | YES | Units within stop/limit bounds at +5% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 21 | UnitsNOP+6% | decimal(16,8) | YES | Units within stop/limit bounds at +6% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 22 | UnitsNOP+7% | decimal(16,8) | YES | Units within stop/limit bounds at +7% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 23 | UnitsNOP+8% | decimal(16,8) | YES | Units within stop/limit bounds at +8% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 24 | UnitsNOP+9% | decimal(16,8) | YES | Units within stop/limit bounds at +9% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 25 | UnitsNOP+10% | decimal(16,8) | YES | Units within stop/limit bounds at +10% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 26 | UnitsNOP+15% | decimal(16,8) | YES | Units within stop/limit bounds at +15% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 27 | UnitsNOP+20% | decimal(16,8) | YES | Units within stop/limit bounds at +20% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 28 | UnitsNOP+25% | decimal(16,8) | YES | Units within stop/limit bounds at +25% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 29 | UnitsNOP+30% | decimal(16,8) | YES | Units within stop/limit bounds at +30% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 30 | UnitsNOP+40% | decimal(16,8) | YES | Units within stop/limit bounds at +40% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 31 | UnitsNOP+50% | decimal(16,8) | YES | Units within stop/limit bounds at +50% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 32 | UnitsNOP+60% | decimal(16,8) | YES | Units within stop/limit bounds at +60% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 33 | UnitsNOP+70% | decimal(16,8) | YES | Units within stop/limit bounds at +70% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 34 | UnitsNOP+80% | decimal(16,8) | YES | Units within stop/limit bounds at +80% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 35 | UnitsNOP+90% | decimal(16,8) | YES | Units within stop/limit bounds at +90% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 36 | UnitsNOP+100% | decimal(16,8) | YES | Units within stop/limit bounds at +100% price shock (price doubles). (Tier 2 — SP_CashRiskMatrix) |
| 37 | UnitsNOP+200% | decimal(16,8) | YES | Units within stop/limit bounds at +200% price shock (price triples). (Tier 2 — SP_CashRiskMatrix) |
| 38 | UnitsNOP+300% | decimal(16,8) | YES | Units within stop/limit bounds at +300% price shock (price quadruples). (Tier 2 — SP_CashRiskMatrix) |
| 39 | UnitsNOP+400% | decimal(16,8) | YES | Units within stop/limit bounds at +400% price shock (price = 5× current). (Tier 2 — SP_CashRiskMatrix) |
| 40 | UnitsNOP+900% | decimal(16,8) | YES | Units within stop/limit bounds at +900% price shock (price = 10× current). Used for extreme-tail crypto stress tests. (Tier 2 — SP_CashRiskMatrix) |

#### Price-Shock Downside Scenarios — 24 columns

For buy positions: `SUM(CASE WHEN StopRate <= Bid×(1-N%) THEN UnitsNOP ELSE 0 END)`. For sell positions: `SUM(CASE WHEN LimitRate <= Ask×(1-N%) THEN UnitsNOP ELSE 0 END)`.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 41 | UnitsNOP-1% | decimal(16,8) | YES | Units within stop/limit bounds at −1% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 42 | UnitsNOP-2% | decimal(16,8) | YES | Units within stop/limit bounds at −2% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 43 | UnitsNOP-3% | decimal(16,8) | YES | Units within stop/limit bounds at −3% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 44 | UnitsNOP-4% | decimal(16,8) | YES | Units within stop/limit bounds at −4% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 45 | UnitsNOP-5% | decimal(16,8) | YES | Units within stop/limit bounds at −5% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 46 | UnitsNOP-6% | decimal(16,8) | YES | Units within stop/limit bounds at −6% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 47 | UnitsNOP-7% | decimal(16,8) | YES | Units within stop/limit bounds at −7% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 48 | UnitsNOP-8% | decimal(16,8) | YES | Units within stop/limit bounds at −8% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 49 | UnitsNOP-9% | decimal(16,8) | YES | Units within stop/limit bounds at −9% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 50 | UnitsNOP-10% | decimal(16,8) | YES | Units within stop/limit bounds at −10% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 51 | UnitsNOP-15% | decimal(16,8) | YES | Units within stop/limit bounds at −15% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 52 | UnitsNOP-20% | decimal(16,8) | YES | Units within stop/limit bounds at −20% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 53 | UnitsNOP-25% | decimal(16,8) | YES | Units within stop/limit bounds at −25% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 54 | UnitsNOP-30% | decimal(16,8) | YES | Units within stop/limit bounds at −30% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 55 | UnitsNOP-40% | decimal(16,8) | YES | Units within stop/limit bounds at −40% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 56 | UnitsNOP-50% | decimal(16,8) | YES | Units within stop/limit bounds at −50% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 57 | UnitsNOP-60% | decimal(16,8) | YES | Units within stop/limit bounds at −60% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 58 | UnitsNOP-70% | decimal(16,8) | YES | Units within stop/limit bounds at −70% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 59 | UnitsNOP-80% | decimal(16,8) | YES | Units within stop/limit bounds at −80% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 60 | UnitsNOP-90% | decimal(16,8) | YES | Units within stop/limit bounds at −90% price shock. (Tier 2 — SP_CashRiskMatrix) |
| 61 | UnitsNOP-99% | decimal(16,8) | YES | Units within stop/limit bounds at −99% price shock (near-zero price). (Tier 2 — SP_CashRiskMatrix) |
| 62 | UnitsNOP-100% | decimal(16,8) | YES | Units within stop/limit bounds at −100% price shock (zero price — instrument value wiped). (Tier 2 — SP_CashRiskMatrix) |

#### Housekeeping (1 column)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 63 | UpdateDate | datetime | YES | ETL load timestamp. Set to `GETDATE()` at SP_CashRiskMatrix execution time. Not a business date — use `Date` for the reporting date. (Tier 2 — SP_CashRiskMatrix) |

---

## 5. Lineage

### 5.1 Production Sources

| BI_DB Column | Synapse Source | Source Column | Transform |
|-------------|----------------|---------------|-----------|
| Date | SP_CashRiskMatrix @Date | — | Constant from SP parameter |
| CID | DWH_dbo.Dim_Position | CID | Passthrough (GROUP BY) |
| TotalCash | DWH_dbo.V_Liabilities | TotalCash | AVG (collapses multi-position join) |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough (GROUP BY) |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough (GROUP BY) |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough via #Prices |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough via #Prices |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Passthrough (GROUP BY) |
| Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough (GROUP BY) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough rename (`dr.Name Regulation`) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough (`dc1.Region`) |
| Bid | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | Passthrough via #Prices |
| Ask | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask | Passthrough via #Prices |
| ConversionRate | SP_CashRiskMatrix | Bid/Ask + Conversion_Bid/Ask | CASE on BuyCurrencyID/SellCurrencyID via Dim_Instrument cross-currency join |
| UnitsNOP | SP_CashRiskMatrix | Dim_Position.AmountInUnitsDecimal, IsBuy | `SUM((2×IsBuy−1)×AmountInUnitsDecimal)` |
| UnitsNOP+N% (×24) | SP_CashRiskMatrix | UnitsNOP, LimitRate/StopRate, Bid/Ask scenarios | CASE on LimitRate/StopRate vs shocked Bid/Ask; SUM aggregated |
| UnitsNOP-N% (×22) | SP_CashRiskMatrix | UnitsNOP, StopRate/LimitRate, Bid/Ask scenarios | CASE on StopRate/LimitRate vs shocked Bid/Ask; SUM aggregated |
| UpdateDate | SP_CashRiskMatrix | — | GETDATE() |

### 5.2 ETL Pipeline

| Step | Object | Description |
|------|--------|-------------|
| Price source | DWH_dbo.Fact_CurrencyPriceWithSplit | Daily bid/ask for InstrumentID < 100000 on @DateID |
| Instrument metadata | DWH_dbo.Dim_Instrument | Name, InstrumentType, BuyCurrencyID, SellCurrencyID; self-joined for cross-currency bridge |
| Open positions | DWH_dbo.Dim_Position | Open CFD positions as of @Date (IsSettled=0, valid customers) |
| Customer filter | DWH_dbo.Dim_Customer | IsValidCustomer=1; provides RegulationID, CountryID |
| Regulation name | DWH_dbo.Dim_Regulation | ID → Name |
| Region label | DWH_dbo.Dim_Country | CountryID → Region |
| Cash balance | DWH_dbo.V_Liabilities | TotalCash per CID on @DateID |
| ETL | BI_DB_dbo.SP_CashRiskMatrix(@Date) | Builds #Prices → #Positions → #Stage → #Final; DELETE+INSERT |
| Target | BI_DB_dbo.BI_DB_CashRiskMatrix | Daily snapshot, ~2.4M rows/day |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer identity, regulation, country |
| InstrumentID | DWH_dbo.Dim_Instrument | Full instrument metadata (ISIN, exchange, asset class) |
| HedgeServerID | DWH_dbo.Dim_Position | Hedge server reference (indirect via Dim_Position) |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction name |
| Region | DWH_dbo.Dim_Country | Marketing region label |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Risk desk reporting queries | Date + CID | Daily exposure stress reports |
| SP_BI_DB_CashRiskMatrix (caller) | — | Scheduled daily orchestration of SP_CashRiskMatrix |

---

## 7. Sample Queries

### 7.1 Customer-level USD NOP for a date

```sql
SELECT
    CID,
    Regulation,
    Region,
    InstrumentType,
    SUM(UnitsNOP * Bid * ConversionRate) AS USDNop,
    MAX(TotalCash) AS TotalCash
FROM BI_DB_dbo.BI_DB_CashRiskMatrix
WHERE [Date] = '2025-10-05'
  AND Bid IS NOT NULL
GROUP BY CID, Regulation, Region, InstrumentType
ORDER BY ABS(SUM(UnitsNOP * Bid * ConversionRate)) DESC;
```

### 7.2 Regulation-level stress at +10% price shock

```sql
SELECT
    Regulation,
    InstrumentType,
    SUM([UnitsNOP+10%] * Bid * ConversionRate) AS USDNopAt10PctUp,
    SUM(UnitsNOP * Bid * ConversionRate) AS USDNopCurrent
FROM BI_DB_dbo.BI_DB_CashRiskMatrix
WHERE [Date] = '2025-10-05'
  AND Bid IS NOT NULL
GROUP BY Regulation, InstrumentType
ORDER BY ABS(SUM([UnitsNOP+10%] * Bid * ConversionRate)) DESC;
```

### 7.3 Instruments with no price coverage (NULL Bid)

```sql
SELECT
    [Date],
    InstrumentID,
    InstrumentName,
    InstrumentType,
    COUNT(*) AS affected_rows,
    SUM(ABS(UnitsNOP)) AS total_abs_units
FROM BI_DB_dbo.BI_DB_CashRiskMatrix
WHERE [Date] = '2025-10-05'
  AND Bid IS NULL
GROUP BY [Date], InstrumentID, InstrumentName, InstrumentType
ORDER BY total_abs_units DESC;
```

### 7.4 Leverage distribution for a date

```sql
SELECT
    Leverage,
    COUNT(*) AS row_count,
    SUM(ABS(UnitsNOP * Bid * ConversionRate)) AS abs_usd_nop
FROM BI_DB_dbo.BI_DB_CashRiskMatrix
WHERE [Date] = '2025-10-05'
  AND Bid IS NOT NULL
GROUP BY Leverage
ORDER BY Leverage;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 Jira/Confluence search deferred).

---

*Generated: 2026-04-28 | Regen Harness Attempt 1*
*Tiers: 11 T1, 51 T2, 0 T3, 0 T4 | Elements: 63/63 documented*
*Object: BI_DB_dbo.BI_DB_CashRiskMatrix | Type: Table | Production Source: DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit + DWH_dbo.V_Liabilities via SP_CashRiskMatrix*
