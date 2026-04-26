# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023

> 106.1M-row daily stock/ETF settlement report tracking end-of-day positions aggregated by instrument, regulation, and hedge server across 32 exchanges — from Jan 2023 to present (~120K rows/day). Loaded by SP_Finance_Non_US_Settlement_2023 via daily DELETE+INSERT on DateID. Covers T+1 settlement for US/Canadian exchanges (NYSE, Nasdaq, Toronto Stock Exchange) and T+2 for all other exchanges. Sources position data from BI_DB_PositionPnL enriched with Dim_Instrument, Dim_Position, Fact_SnapshotCustomer, and exchange calendar schedules.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Finance_Non_US_Settlement_2023 (BI_DB_PositionPnL + Dim_Instrument + Dim_Position + Fact_SnapshotCustomer + Fact_CurrencyPriceWithSplit + exchange calendar) |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT per DateID |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Guy Manova (2023-08-07) |
| **Change History** | 2024-02-05 Adi Meidan: Hedge Server rename 9=JPM, 120=APEX; 2024-05-31 Bradley Roberts: T+2→T+1 for US/Canadian stocks; 2025-01-29 Inessa: fixed >= in last cross join |

---

## 1. Business Meaning

This table is a daily finance settlement report for stocks (InstrumentTypeID=5) and ETFs (InstrumentTypeID=6). Each row represents one instrument × regulation × hedge server combination for a given date, containing aggregated end-of-day units, equity in USD, net open position (NOP) in USD, and EOD pricing (spreaded and unspreaded, in both USD and original currency).

The report supports the finance team's settlement reconciliation by computing the next settlement date based on exchange calendars — T+1 for US/Canadian exchanges (NYSE, Nasdaq, Toronto Stock Exchange, changed from T+2 in May 2024) and T+2 for all other exchanges. Settlement dates are derived by finding the next open trading day(s) after the position date using the External_bronze_calendardb_market_mergeddailyschedules exchange calendar.

**Data shape**: 106.1M rows spanning Jan 2023 to Apr 2026, with ~120K rows per date across 32 exchanges. Rows where the instrument has no client positions appear with NULL EOD_Units and are flagged as 'No_Client_Holdings' (3.7% of daily rows).

**ETL pattern**: SP_Finance_Non_US_Settlement_2023 runs daily via SB_Daily at Priority 0. It DELETEs existing rows for @dateID and INSERTs the new aggregated data. The SP builds several temp tables:
1. `#hedgeServers` — hardcoded HedgeServerID → Provider name mapping (24 entries)
2. `#ExchangeCalendar` / `#CalendarDeduped` — exchange open/close schedules
3. `#usdConversion` / `#prices` — EOD pricing from Fact_CurrencyPriceWithSplit with USD conversion
4. `#oneDayPnL` / `#relPos2` — position-level data enriched with customer/regulation/country
5. `#final` — aggregated instrument × regulation × hedge server
6. `#T1_US_Stocks` (T+1) / `#T1Open` + `#T2Open` (T+2) — settlement date calculation

---

## 2. Business Logic

### 2.1 Settlement Date Calculation (T+1 vs T+2)

**What**: Different exchanges follow different settlement cycles based on exchange jurisdiction.
**Columns Involved**: Exchange, SettlementDate, SettleCloseTime, SettleCloseTimeUTC
**Rules**:
- US/Canadian exchanges (NYSE, Nasdaq, Toronto Stock Exchange): T+1 settlement — next open trading day after position date
- All other exchanges (LSE, Euronext Paris, FRA, etc.): T+2 settlement — second open trading day after position date
- Changed from universal T+2 to T+1 for US/CA on 2024-05-31 (Bradley Roberts, SR-229104 context)
- Open days determined by External_bronze_calendardb_market_mergeddailyschedules WHERE IsOpen=1
- SettleCloseTime values of 9999-12-31 23:59:59.997 indicate no explicit close time in calendar

### 2.2 Hedge Server Provider Mapping

**What**: Hardcoded mapping from HedgeServerID to liquidity provider name.
**Columns Involved**: HedgeServerID, Provider
**Rules**:
- 24 HedgeServerID values mapped: JPM (2, 9), Apex (3, 11, 102, 112, 120), BNYMellon (110, 124, 130), IB (121, 126), Saxo (122, 125, 128, 225), IG (7, 101, 111, 123), FXCM (24), VisionTraffix (129), Unknown (20, 25, 5000)
- Unmapped HedgeServerIDs (e.g., 35, 500) produce blank Provider (~18.7% of daily rows)
- No_Client_Holdings rows (NULL HedgeServerID) have NULL Provider

### 2.3 Client Holdings Flag

**What**: Distinguishes instruments with active client positions from instruments with only pricing data.
**Columns Involved**: ClientHoldings, EOD_Units
**Rules**:
- `Client_Holdings` when EOD_Units is NOT NULL (96.3% of daily rows)
- `No_Client_Holdings` when EOD_Units IS NULL (3.7%) — instrument exists in Dim_Instrument but has no open positions for this date/regulation/hedge server combination
- Generated via FULL OUTER JOIN between position aggregation and Dim_Instrument, so all InstrumentTypeID 5/6 instruments appear even without positions

### 2.4 ISIN Country Parsing

**What**: Extracts country code from ISINCode for geographic classification.
**Columns Involved**: ISINCountryParsed, ISINCode
**Rules**:
- LEFT(ISINCode, 2) — ISO 3166-1 alpha-2 country code
- US dominates at 59%, then GB (5.5%), IE (4.6%), DE (3.3%), FR (3.2%)
- NULL when ISINCode is NULL

### 2.5 Position Aggregation

**What**: Positions are aggregated from individual position level to instrument × regulation × hedge server granularity.
**Columns Involved**: EOD_Units, EOD_Equity_USD, EOD_NOP_USD
**Rules**:
- EOD_Units = SUM(AmountInUnitsDecimal) from BI_DB_PositionPnL
- EOD_Equity_USD = SUM(Amount + PositionPnL) — total open equity in USD
- EOD_NOP_USD = SUM(NOP) — net open position in USD
- Group by: InstrumentID, Regulation, HedgeServerID, IsDiscounted, IsCreditReportValidCB, IsSettled, Exchange, CUSIP, ISINCode

### 2.6 EOD Pricing

**What**: End-of-day pricing captured from Fact_CurrencyPriceWithSplit with USD conversion.
**Columns Involved**: EOD_PriceUSD_Spreaded, EOD_PriceUSD_Unspreaded, EOD_OrigCurr_BidSpreaded, EOD_OrigCurr_BidUnspreaded, USD_ConversionRate
**Rules**:
- USD prices = original currency bid × USD_ConversionRate
- USD_ConversionRate sourced from Dim_GetSpreadedPriceUSDConversionRate for the day before @date
- For USD-denominated instruments, USD_ConversionRate = 1.0
- MAX used since pricing is at instrument level, not position level

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution — no co-location benefit. Queries always scan all distributions.
- **CLUSTERED INDEX on DateID** — always include DateID in WHERE clause for efficient seeks.
- For date-range queries, use `DateID BETWEEN 20260101 AND 20260401` (int comparison, fast on clustered index).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily settlement exposure by exchange | `WHERE DateID = @dateID GROUP BY Exchange` |
| Provider-level position summary | `WHERE DateID = @dateID AND ClientHoldings = 'Client_Holdings' GROUP BY Provider` |
| Non-US ISIN instrument exposure | `WHERE DateID = @dateID AND ISINCountryParsed <> 'US'` |
| Unsettled position monitoring | `WHERE DateID = @dateID AND IsSettled = 0 AND ClientHoldings = 'Client_Holdings'` |
| Settlement date lookup for an instrument | `WHERE DateID = @dateID AND InstrumentID = @id` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument attributes (already denormalized for key fields) |
| BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 | DateID, InstrumentID, Regulation, HedgeServerID | Sibling report with additional columns (2025 version) |

### 3.4 Gotchas

- **No_Client_Holdings rows**: 3.7% of daily rows have NULL EOD_Units/EOD_Equity_USD/EOD_NOP_USD/HedgeServerID/Regulation/IsDiscounted/IsSettled/IsCreditReportValidCB. Always filter `ClientHoldings = 'Client_Holdings'` for position analysis.
- **Provider blanks**: ~18.7% of Client_Holdings rows have blank (not NULL) Provider due to unmapped HedgeServerIDs in the hardcoded temp table. These are real positions but with unknown providers.
- **SettleCloseTime sentinel**: Values of `9999-12-31 23:59:59.997` indicate the exchange calendar has no explicit close time — do not interpret as a real timestamp.
- **CUSIP NULL for non-US**: 32% of rows have NULL CUSIP — expected for non-US/Canadian instruments.
- **Regulation is a NAME, not an ID**: The Regulation column contains the text name (CySEC, FCA, etc.), not the RegulationID integer. Use Dim_Regulation for ID-based joins.
- **Despite the name "Non_US"**: The table actually contains ALL stocks/ETFs including US instruments (US ISINs = 59%). The name is a legacy artifact from the original report design.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki — description copied verbatim from documented production source |
| Tier 2 | SP code — description derived from ETL stored procedure logic |
| Tier 3 | Live data — description inferred from data sampling and distribution analysis |
| Tier 4 | Inferred — best available knowledge, limited confidence |
| Tier 5 | Expert Review — assigned by subject matter expert or pipeline operator |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Snapshot date as YYYYMMDD integer. Clustered index key. Computed via DateToDateID(@date). Always filter on this column. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. Input parameter @dt passed to the SP. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 3 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — Trade.Instrument) |
| 4 | InstrumentName | varchar(100) | YES | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Rename: Dim_Instrument.Name → InstrumentName. (Tier 1 — Trade.Instrument) |
| 5 | InstrumentDisplayName | varchar(200) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 6 | ISINCode | varchar(50) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 7 | CUSIP | varchar(50) | YES | Committee on Uniform Securities Identification Procedures number — 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 8 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Text values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, ASIC, etc. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2023 via Dim_Regulation.Name) |
| 9 | EOD_Units | float | YES | Total end-of-day units/shares held for this instrument × regulation × hedge server combination. SUM(AmountInUnitsDecimal) from BI_DB_PositionPnL. NULL for No_Client_Holdings rows (instrument exists but no positions). (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 10 | EOD_Equity_USD | float | YES | Total end-of-day equity in USD. SUM(Amount + PositionPnL) from BI_DB_PositionPnL — includes both invested amount and unrealized P&L. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 11 | EOD_NOP_USD | float | YES | Total net open position in USD. SUM(NOP) from BI_DB_PositionPnL. Represents directional exposure. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 12 | EOD_PriceUSD_Spreaded | float | YES | End-of-day instrument price in USD including spread. MAX(BidSpreaded × USD_ConversionRate) from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 13 | EOD_PriceUSD_Unspreaded | float | YES | End-of-day instrument price in USD without spread. MAX(Bid × USD_ConversionRate) from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 14 | EOD_OrigCurr_BidSpreaded | float | YES | End-of-day bid price in original instrument currency including spread. MAX(BidSpreaded) from Fact_CurrencyPriceWithSplit. For USD instruments, equals EOD_PriceUSD_Spreaded. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 15 | EOD_OrigCurr_BidUnspreaded | float | YES | End-of-day bid price in original instrument currency without spread. MAX(Bid) from Fact_CurrencyPriceWithSplit. For USD instruments, equals EOD_PriceUSD_Unspreaded. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 16 | USD_ConversionRate | float | YES | USD conversion rate for the instrument's sell currency. From Dim_GetSpreadedPriceUSDConversionRate, most recent rate as of the day before @date. 1.0 for USD-denominated instruments. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 17 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. Grouping key — all positions for the same instrument/regulation/hedge server are aggregated. NULL for No_Client_Holdings rows. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 18 | Provider | varchar(50) | YES | Liquidity provider name resolved from hardcoded #hedgeServers temp table. Values: Apex, JPM, BNYMellon, IB, IG, Saxo, FXCM, VisionTraffix, Unknown. Blank (not NULL) when HedgeServerID is not in the mapping. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 19 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. From Dim_Position via BI_DB_PositionPnL. NULL for No_Client_Holdings rows. (Tier 1 — Trade.PositionTbl) |
| 20 | ClientHoldings | varchar(50) | YES | Derived flag: 'Client_Holdings' when EOD_Units IS NOT NULL, 'No_Client_Holdings' when EOD_Units IS NULL. Indicates whether the instrument has any open positions for this regulation/hedge server/date combination. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 21 | ISINCountryParsed | varchar(3) | YES | ISO 3166-1 alpha-2 country code extracted from the first 2 characters of ISINCode. LEFT(ISINCode, 2). US=59%, GB=5.5%, IE=4.6%, DE=3.3%, FR=3.2%. NULL when ISINCode is NULL. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 22 | IsTradableAtQueryDate | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. Rename: Dim_Instrument.Tradable → IsTradableAtQueryDate. (Tier 2 — SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 23 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD snapshot. NULL for No_Client_Holdings rows. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 24 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. From Dim_Position. NULL for No_Client_Holdings rows. (Tier 5 — Expert Review) |
| 25 | Exchange | varchar(50) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). Determines T+1 vs T+2 settlement logic. 32 distinct exchanges. NULL for instruments without metadata entries or No_Client_Holdings rows. (Tier 3 — live data, etoro_Trade_InstrumentMetaData) |
| 26 | SettlementDate | date | YES | Projected settlement date. T+1 for NYSE/Nasdaq/Toronto Stock Exchange (next open trading day), T+2 for all other exchanges (second open trading day). Derived via CROSS APPLY against exchange calendar. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 27 | SettleCloseTime | datetime | YES | Close time of the settlement date trading session from exchange calendar. Value 9999-12-31 23:59:59.997 = no explicit close time in calendar. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 28 | SettleCloseTimeUTC | datetime | YES | UTC-normalized close time of the settlement date trading session from exchange calendar. Value 9999-12-31 23:59:59.997 = no explicit close time in calendar. (Tier 2 — SP_Finance_Non_US_Settlement_2023) |
| 29 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough (FULL OUTER JOIN) |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Rename |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough |
| CUSIP | DWH_dbo.Dim_Instrument | CUSIP | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Fact_SnapshotCustomer.RegulationID |
| EOD_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM aggregation |
| EOD_Equity_USD | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM |
| EOD_NOP_USD | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM |
| EOD_PriceUSD_Spreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded × USD_ConversionRate | MAX |
| EOD_PriceUSD_Unspreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid × USD_ConversionRate | MAX |
| EOD_OrigCurr_BidSpreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded | MAX |
| EOD_OrigCurr_BidUnspreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | MAX |
| USD_ConversionRate | DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | USD_ConversionRate | MAX (most recent) |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough |
| Provider | Hardcoded #hedgeServers | Provider | Lookup |
| IsDiscounted | DWH_dbo.Dim_Position | IsDiscounted | Passthrough |
| ClientHoldings | Computed | — | CASE on EOD_Units NULL |
| ISINCountryParsed | DWH_dbo.Dim_Instrument | ISINCode | LEFT(ISINCode, 2) |
| IsTradableAtQueryDate | DWH_dbo.Dim_Instrument | Tradable | Rename |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Passthrough |
| SettlementDate | Exchange Calendar | Date | T+1 or T+2 CROSS APPLY |
| SettleCloseTime | Exchange Calendar | CloseTime | Passthrough |
| SettleCloseTimeUTC | Exchange Calendar | CloseTimeUTC | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (daily position PnL snapshot, ~500M+ rows)
  + DWH_dbo.Dim_Instrument (instrument reference, filter InstrumentTypeID IN (5,6))
  + DWH_dbo.Dim_Position (IsDiscounted, IsSettled, HedgeServerID)
  + DWH_dbo.Fact_SnapshotCustomer (SCD snapshot: RegulationID, CountryID, PlayerLevelID, IsCreditReportValidCB)
    + DWH_dbo.Dim_Range (SCD date range resolution)
    + DWH_dbo.Dim_Regulation (RegulationID → Name)
    + DWH_dbo.Dim_Country (CountryID → Name)
    + DWH_dbo.Dim_PlayerLevel (PlayerLevelID → Name)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (EOD bid prices by InstrumentID)
  + DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate (SellCurrencyID → USD rate)
  + External_bronze_calendardb_market_mergeddailyschedules (exchange open/close calendar)
    + DWH_dbo.Dim_ExchangeInfo (ExchangeID → ExchangeDescription)
  + Hardcoded #hedgeServers (24 entries: HedgeServerID → Provider name)
    |-- SP_Finance_Non_US_Settlement_2023 @dt (DELETE @dateID + INSERT, SB_Daily P0) ---|
    v
  BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 (106.1M rows, ~120K/day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension — full instrument attributes |
| HedgeServerID | DWH_dbo.Dim_Position (source) | Hedge server assignment from position |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name (text, not ID) |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | Customer credit report validity flag |
| IsSettled, IsDiscounted | DWH_dbo.Dim_Position | Position settlement and discount flags |
| EOD_Units, EOD_Equity_USD, EOD_NOP_USD | BI_DB_dbo.BI_DB_PositionPnL | Aggregated position metrics |
| SettlementDate | External_bronze_calendardb_market_mergeddailyschedules | Exchange calendar for settlement dates |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 | Sibling table — same report structure with additional columns for 2025 version |
| BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions | Related settlement reconciliation report sharing common writer SP family |

---

## 7. Sample Queries

### 7.1 Daily Settlement Exposure by Exchange

```sql
SELECT
    Exchange,
    COUNT(*) AS InstrumentCount,
    SUM(EOD_Units) AS TotalUnits,
    SUM(EOD_Equity_USD) AS TotalEquityUSD,
    SUM(EOD_NOP_USD) AS TotalNOP_USD
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2023]
WHERE DateID = 20260412
  AND ClientHoldings = 'Client_Holdings'
GROUP BY Exchange
ORDER BY TotalEquityUSD DESC
```

### 7.2 Provider-Level Position Summary with Settlement

```sql
SELECT
    Provider,
    Regulation,
    SettlementDate,
    COUNT(DISTINCT InstrumentID) AS Instruments,
    SUM(EOD_Equity_USD) AS TotalEquityUSD
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2023]
WHERE DateID = 20260412
  AND ClientHoldings = 'Client_Holdings'
GROUP BY Provider, Regulation, SettlementDate
ORDER BY Provider, TotalEquityUSD DESC
```

### 7.3 Non-US Instrument Exposure Trend

```sql
SELECT
    DateID,
    ISINCountryParsed,
    SUM(EOD_Equity_USD) AS TotalEquityUSD,
    SUM(EOD_NOP_USD) AS TotalNOP_USD
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2023]
WHERE DateID >= 20260401
  AND ISINCountryParsed <> 'US'
  AND ClientHoldings = 'Client_Holdings'
GROUP BY DateID, ISINCountryParsed
ORDER BY DateID, TotalEquityUSD DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 4 T1, 19 T2, 1 T3, 0 T4, 2 T5 | Elements: 29/29, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 | Type: Table | Production Source: SP_Finance_Non_US_Settlement_2023*
