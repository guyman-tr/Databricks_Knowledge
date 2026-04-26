# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025

> 49.3M-row daily stock/ETF settlement report — the 2025 replacement for BI_DB_Finance_Non_US_Settlement_New_2023 — tracking end-of-day positions aggregated by instrument, regulation, hedge server, and close-price metrics across 32 exchanges, from Dec 2024 to present (~146K rows/day). Loaded by SP_Finance_Non_US_Settlement_2025 via daily DELETE+INSERT. Extends the 2023 version with 15 new columns: IsValidCustomer, LiquidityAccount details (ID/Name/ProviderName), close-price P&L/rates (Close_PnLInDollars, Close/Current CalculationRate/ConversionRate/NOP), TotalEquityClosePrice, and TotalStockMarginLoan. Provider mapping upgraded from hardcoded temp table to dynamic sources (Karen's Dealing mapping + etoro GetHedgeServerAccountMapping).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Finance_Non_US_Settlement_2025 (BI_DB_PositionPnL + Dim_Instrument + Dim_Position + Fact_SnapshotCustomer + Fact_CurrencyPriceWithSplit + Karen's LP mapping + etoro LA mapping + exchange calendar) |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT per DateID |
| **Synapse Distribution** | HASH(ISINCode) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Guy Manova (2023-08-07), major rewrite by Inessa Kontorovich (2025-01-28) |
| **Change History** | 2025-01-28 Inessa K: replaces SP_2023 — adds IsValid, LP/LA, omnibus netting source; 2025-02-17 Inessa: fixed partition by logic in mapping; 2025-03-04 Inessa: adjustment for same hedge multi-LA; 2025-09-10 Guy M: new close price metrics; 2025-09-18 Guy M: midnight price anomaly handling; 2025-10-27 Inessa K: replace DUCO with direct netting table; 2026-02-11 Markos Chris: add StockMarginLoan to equity |

---

## 1. Business Meaning

This table is the 2025-generation daily finance settlement report for stocks (InstrumentTypeID=5) and ETFs (InstrumentTypeID=6), replacing the simpler BI_DB_Finance_Non_US_Settlement_New_2023. Each row represents one instrument × regulation × hedge server × close-price-rate combination for a given date, with aggregated end-of-day units, equity, NOP, pricing, close-price metrics, and liquidity account attribution.

**Key enhancements over the 2023 version**:
- **Liquidity Account resolution**: Provider is no longer a hardcoded temp table. It uses a 3-tier COALESCE: (1) Karen's Fivetran mapping file per instrument per hedge server, (2) one-LA-per-hedge server fallback, (3) one-Provider-per-hedge fallback. LiquidityAccountID, LiquidityAccountName, and LiquidityProviderName are included for bank-level reconciliation.
- **Close-price metrics**: Close_PnLInDollars, Close_CalculationRate, Close_ConversionRate, Close_PriceType, Close_NOP — enabling comparison between close-price P&L and current-price P&L.
- **Stock margin loan**: TotalStockMarginLoan computed for leveraged settled positions (SettlementTypeID=5 AND Leverage<>1).
- **IsValidCustomer**: From Fact_SnapshotCustomer, for Duco/omnibus reconciliation requiring valid customer filter.
- **Additional grouping**: Rows are grouped by Close_CalculationRate, Close_ConversionRate, Close_PriceType, CurrentCalculationRate, CurrentConversionRate — finer granularity than 2023.

**Data shape**: 49.3M rows spanning Dec 2024 to Apr 2026, ~146K rows/day across 32 exchanges. The SP also populates BI_DB_Finance_eToro_vs_Positions as a second output (omnibus netting reconciliation).

**ETL pattern**: SP_Finance_Non_US_Settlement_2025 runs daily via SB_Daily at Priority 0. DELETE+INSERT on @dateID. T+1 settlement for NYSE/Nasdaq/Toronto Stock Exchange, T+2 for all others.

---

## 2. Business Logic

### 2.1 Settlement Date Calculation (T+1 vs T+2)

**What**: Same logic as the 2023 version — different settlement cycles by exchange jurisdiction.
**Columns Involved**: Exchange, SettlementDate, SettleCloseTime, SettleCloseTimeUTC
**Rules**:
- NYSE, Nasdaq, Toronto Stock Exchange: T+1 (next open trading day)
- All other exchanges: T+2 (second open trading day)
- Open days from External_bronze_calendardb_market_mergeddailyschedules WHERE IsOpen=1

### 2.2 Liquidity Account Provider Resolution (3-Tier COALESCE)

**What**: Resolves HedgeServerID + InstrumentID to a named liquidity provider using multiple mapping sources.
**Columns Involved**: Provider, LiquidityAccountID, LiquidityAccountName, LiquidityProviderName, HedgeServerID
**Rules**:
1. **Tier 1 — Instrument-level mapping** (#mapping): JOIN on InstrumentID + HedgeServerID from Karen's Fivetran mapping + etoro GetHedgeServerAccountMapping. Used when hedge server has multiple LAs (CountLAPerHedge > 1).
2. **Tier 2 — One-LA-per-hedge fallback** (#mappingoneLA): When a hedge server has exactly one LA (CountLAPerHedge = 1), the single LA applies to all instruments.
3. **Tier 3 — One-Provider-per-hedge** (#mappingonehedge): When a hedge server has only one distinct Provider across all LAs and the LA-level mapping has no data.
- Provider names: CASE-based normalization from liquidity_provider/LiquidityAccountName text. Values: BNYMellon, Apex, IB, JPM, Saxo, IG, VisionTraffix, UBS, Marex, Gdax, GS, DLT, COINBASE, eToroX, JP, NA.
- ~11% of rows still have NULL/empty LiquidityAccountID after all 3 tiers.

### 2.3 Close Price Metrics

**What**: Close-price P&L and rates for settlement reconciliation — comparing close-price valuation vs current-price valuation.
**Columns Involved**: Close_PnLInDollars, Close_CalculationRate, Close_ConversionRate, Close_PriceType, Close_NOP, CurrentCalculationRate, CurrentConversionRate, Current_NOP, Current_PnLInDollars, TotalEquityClosePrice
**Rules**:
- Close_PnLInDollars: SUM from BI_DB_PositionPnL.Close_PnLInDollars — P&L at close price
- Current_PnLInDollars: SUM from BI_DB_PositionPnL.PositionPnL (aliased) — P&L at current price
- TotalEquityClosePrice: SUM(Amount + Close_PnLInDollars) — equity valued at close price
- Close_PriceType: 1=EOD close, 2=current (most common at 83%), 3=other
- Close_NOP / Current_NOP: Directional exposure at close vs current rates

### 2.4 Stock Margin Loan Computation

**What**: Computes margin loan amount for leveraged settled (real asset) positions.
**Columns Involved**: TotalStockMarginLoan
**Rules**:
- Only applies when SettlementTypeID = 5 (settled) AND Leverage <> 1 (leveraged)
- Formula: InitForexRate × AmountInUnitsDecimal × CurrentConversionRate − Amount
- SUM aggregated. ISNULL defaulted to 0.
- 0.25% of rows have nonzero value. Added 2026-02-11 by Markos Chris.

### 2.5 Client Holdings Flag

**What**: Same as 2023 version — distinguishes instruments with/without client positions.
**Columns Involved**: ClientHoldings, EOD_Units
**Rules**:
- 'Client_Holdings' when EOD_Units IS NOT NULL, 'No_Client_Holdings' when NULL (3.1%)

### 2.6 IsValidCustomer Filter

**What**: Adds customer validity flag for Duco/omnibus comparison alignment.
**Columns Involved**: IsValidCustomer
**Rules**:
- 1 = valid customer (79.5%), 0 = invalid (17.4%), NULL = No_Client_Holdings rows (3.1%)
- Required because Duco/omnibus data uses IsValidCustomer=1 filter — without this flag, client-side totals cannot be compared to omnibus-side

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **HASH(ISINCode)** distribution — queries filtering on ISINCode benefit from data locality.
- **CLUSTERED INDEX on DateID** — always include DateID in WHERE for efficient seeks.
- For cross-ISIN queries, expect data movement (shuffles).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily settlement by provider/LA | `WHERE DateID = @dateID AND ClientHoldings = 'Client_Holdings' GROUP BY Provider, LiquidityAccountName` |
| Close vs current P&L comparison | `WHERE DateID = @dateID` — compare SUM(Close_PnLInDollars) vs SUM(Current_PnLInDollars) |
| Margin loan exposure | `WHERE DateID = @dateID AND TotalStockMarginLoan <> 0` |
| Valid customer settlement | `WHERE DateID = @dateID AND IsValidCustomer = 1 AND IsSettled = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument attributes |
| BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 | DateID, InstrumentID, Regulation, HedgeServerID | Compare against legacy 2023 report |
| BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions | DateID, InstrumentID, HedgeServerID, LiquidityAccountID | Omnibus reconciliation companion |

### 3.4 Gotchas

- **No_Client_Holdings rows**: ~3.1% of daily rows have NULL for all position-derived columns (EOD_Units, Regulation, HedgeServerID, IsValidCustomer, etc.). Always filter `ClientHoldings = 'Client_Holdings'` for analysis.
- **Finer granularity than 2023**: The 2025 table groups by Close_CalculationRate, Close_ConversionRate, Close_PriceType, CurrentCalculationRate, CurrentConversionRate — rows are NOT 1:1 comparable with the 2023 table.
- **~146K rows/day vs ~120K**: More rows than 2023 due to the finer grouping and LP/LA resolution adding additional dimensions.
- **Provider = blank ≠ NULL**: Blank Provider comes from unmapped hedge servers. NULL Provider only for No_Client_Holdings rows.
- **TotalStockMarginLoan mostly zero**: Only 0.25% of rows have nonzero values (leveraged settled positions with SettlementTypeID=5).
- **SettleCloseTime real timestamps in 2025**: Unlike the 2023 version where all values were 9999-12-31, the 2025 version has real close times (e.g., 2026-04-13 19:50:00).
- **SP also populates BI_DB_Finance_eToro_vs_Positions**: This SP writes to TWO tables — rerunning it affects both.

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
| 1 | DateID | int | YES | Snapshot date as YYYYMMDD integer. Clustered index key. Computed via DateToDateID(@date). Always filter on this column. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. Input parameter @dt. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 3 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — Trade.Instrument) |
| 4 | InstrumentName | varchar(100) | YES | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). Rename: Dim_Instrument.Name → InstrumentName. (Tier 1 — Trade.Instrument) |
| 5 | InstrumentDisplayName | varchar(200) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 6 | ISINCode | varchar(50) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. HASH distribution key. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 7 | CUSIP | varchar(50) | YES | Committee on Uniform Securities Identification Procedures number — 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 8 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation via Fact_SnapshotCustomer.RegulationID. Text values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, FinCEN+FINRA, etc. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2025 via Dim_Regulation.Name) |
| 9 | EOD_Units | float | YES | Total end-of-day units/shares held for this grouping. SUM(AmountInUnitsDecimal) from BI_DB_PositionPnL. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 10 | EOD_Equity_USD | float | YES | Total end-of-day equity in USD. SUM(Amount + PositionPnL). Includes invested amount plus unrealized P&L at current prices. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 11 | EOD_NOP_USD | float | YES | Total net open position in USD. SUM(NOP). Represents directional exposure at current prices. NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 12 | EOD_PriceUSD_Spreaded | float | YES | End-of-day instrument price in USD including spread. MAX(BidSpreaded × USD_ConversionRate). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 13 | EOD_PriceUSD_Unspreaded | float | YES | End-of-day instrument price in USD without spread. MAX(Bid × USD_ConversionRate). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 14 | EOD_OrigCurr_BidSpreaded | float | YES | End-of-day bid price in original instrument currency including spread. MAX(BidSpreaded). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 15 | EOD_OrigCurr_BidUnspreaded | float | YES | End-of-day bid price in original instrument currency without spread. MAX(Bid). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 16 | USD_ConversionRate | float | YES | USD conversion rate for the instrument's sell currency. From Dim_GetSpreadedPriceUSDConversionRate, most recent rate as of day before @date. 1.0 for USD-denominated instruments. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 17 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. Grouping key. NULL for No_Client_Holdings rows. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 18 | Provider | varchar(50) | YES | Liquidity provider name resolved via 3-tier COALESCE: (1) Karen's Fivetran mapping per instrument/hedge, (2) one-LA-per-hedge fallback, (3) one-Provider-per-hedge fallback. Values: Apex, JPM, BNYMellon, Saxo, IB, IG, VisionTraffix, UBS, Marex, Gdax, GS, DLT, COINBASE, eToroX, JP, NA. Blank when no mapping found. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 19 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. From Dim_Position via BI_DB_PositionPnL. NULL for No_Client_Holdings rows. (Tier 1 — Trade.PositionTbl) |
| 20 | ClientHoldings | varchar(50) | YES | Derived flag: 'Client_Holdings' when EOD_Units IS NOT NULL, 'No_Client_Holdings' when NULL. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 21 | ISINCountryParsed | varchar(3) | YES | ISO 3166-1 alpha-2 country code from first 2 characters of ISINCode. LEFT(ISINCode, 2). NULL when ISINCode is NULL. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 22 | IsTradableAtQueryDate | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. Rename: Dim_Instrument.Tradable → IsTradableAtQueryDate. (Tier 2 — SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 23 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD snapshot. NULL for No_Client_Holdings rows. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 24 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. From Dim_Position. NULL for No_Client_Holdings rows. (Tier 5 — Expert Review) |
| 25 | Exchange | varchar(50) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). Determines T+1 vs T+2 settlement logic. NULL for instruments without metadata. (Tier 3 — live data, etoro_Trade_InstrumentMetaData) |
| 26 | SettlementDate | date | YES | Projected settlement date. T+1 for NYSE/Nasdaq/Toronto Stock Exchange, T+2 for all other exchanges. Derived via CROSS APPLY against exchange calendar. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 27 | SettleCloseTime | datetime | YES | Close time of the settlement date trading session from exchange calendar. Real timestamps in 2025 version (unlike 2023's 9999-12-31 sentinel). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 28 | SettleCloseTimeUTC | datetime | YES | UTC-normalized close time of the settlement date trading session from exchange calendar. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 29 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted. Set to GETDATE() at INSERT time. NOT NULL constraint. (Tier 5 — ETL metadata) |
| 30 | IsValidCustomer | int | YES | 1 if the customer passes validity checks (not demo, not invalid). From Fact_SnapshotCustomer. Added for Duco/omnibus comparison alignment (Duco uses IsValidCustomer=1). NULL for No_Client_Holdings rows. (Tier 2 — SP_Finance_Non_US_Settlement_2025 via Fact_SnapshotCustomer) |
| 31 | LiquidityAccountID | nvarchar(64) | YES | Liquidity account identifier resolved from Karen's Fivetran mapping (External_Fivetran_dealing_active_hs_mappings) or etoro_Hedge_GetHedgeServerAccountMapping. 2-tier ISNULL. NULL/empty for ~11% of rows where no mapping exists. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 32 | LiquidityAccountName | nvarchar(1200) | YES | Human-readable name for the liquidity account. Resolved from mapping or etoro_Trade_LiquidityAccounts. Examples: 'EMSX JPM Execution (CBH)', 'EMSX JPM Execution (OMS Pricing Project)'. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 33 | LiquidityProviderName | nvarchar(1200) | YES | Name of the liquidity provider from the etoro mapping. More specific than Provider (which is a normalized CASE-based classification). NULL when only Karen's mapping is available. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 34 | Close_PnLInDollars | decimal(38,6) | YES | Profit/loss in USD valued at the close price. SUM aggregation from BI_DB_PositionPnL.Close_PnLInDollars. Compare with Current_PnLInDollars for close-vs-current reconciliation. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 35 | Close_CalculationRate | decimal(16,8) | YES | The instrument calculation rate used for close-price P&L computation. Grouping key — not aggregated. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 36 | Close_ConversionRate | decimal(26,17) | YES | The currency conversion rate used for close-price P&L computation. Grouping key. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 37 | Close_PriceType | int | YES | Type of price used for close valuation. 1=EOD close, 2=current price (83% of rows), 3=other. NULL for No_Client_Holdings rows. Grouping key. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 38 | CurrentCalculationRate | decimal(16,8) | YES | The instrument calculation rate for current-price valuation. Grouping key. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 39 | CurrentConversionRate | decimal(26,17) | YES | The currency conversion rate for current-price valuation. Grouping key. Also used in TotalStockMarginLoan computation. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 40 | Close_NOP | numeric(18,8) | YES | Net open position in USD valued at the close price. SUM aggregation. Compare with Current_NOP. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 41 | Current_NOP | numeric(18,8) | YES | Net open position in USD valued at the current price. SUM aggregation. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 42 | TotalEquityClosePrice | numeric(18,8) | YES | Total equity valued at the close price. SUM(Amount + Close_PnLInDollars). Compare with EOD_Equity_USD (current-price equity). (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 43 | Current_PnLInDollars | numeric(18,8) | YES | Profit/loss in USD at the current price. SUM of BI_DB_PositionPnL.PositionPnL (aliased as Current_PnLInDollars in the SP). Compare with Close_PnLInDollars. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |
| 44 | TotalStockMarginLoan | decimal(20,4) | YES | Margin loan amount for leveraged settled positions. CASE WHEN SettlementTypeID=5 AND Leverage<>1 THEN InitForexRate × AmountInUnitsDecimal × CurrentConversionRate − Amount END. SUM aggregated, ISNULL defaulted to 0. Nonzero for ~0.25% of rows. Added 2026-02-11 by Markos Chris. (Tier 2 — SP_Finance_Non_US_Settlement_2025) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Rename |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough |
| IsDiscounted | DWH_dbo.Dim_Position | IsDiscounted | Passthrough |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough |
| Provider | Karen's mapping + etoro LA mapping | COALESCE | 3-tier resolution |
| LiquidityAccountID | Karen's mapping + etoro LA mapping | ISNULL | 2-tier resolution |
| Close_PnLInDollars | BI_DB_dbo.BI_DB_PositionPnL | Close_PnLInDollars | SUM |
| TotalStockMarginLoan | Computed | SettlementTypeID, Leverage, InitForexRate, AmountInUnitsDecimal, CurrentConversionRate, Amount | CASE + SUM |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position-level PnL, Close metrics)
  + DWH_dbo.Dim_Instrument (filter InstrumentTypeID IN (5,6))
  + DWH_dbo.Dim_Position (IsDiscounted, IsSettled, SettlementTypeID, Leverage, InitForexRate)
  + DWH_dbo.Fact_SnapshotCustomer (SCD: Regulation, IsValidCustomer, IsCreditReportValidCB)
    + DWH_dbo.Dim_Range (SCD date range)
    + DWH_dbo.Dim_Regulation / Dim_Country / Dim_PlayerLevel (lookups)
  + DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_GetSpreadedPriceUSDConversionRate (pricing)
  + Dealing_staging.External_Fivetran_dealing_active_hs_mappings (Karen's LP → bank mapping)
  + CopyFromLake.etoro_Hedge_GetHedgeServerAccountMapping (instrument → LA mapping)
  + Dealing_staging.etoro_Trade_LiquidityAccounts (LA name lookup)
  + External_bronze_calendardb_market_mergeddailyschedules (exchange calendar)
    |-- SP_Finance_Non_US_Settlement_2025 @dt (DELETE+INSERT, SB_Daily P0) ---|
    v
  BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 (49.3M rows, ~146K/day)
    |-- also writes ---|
    v
  BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions (omnibus netting reconciliation)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| HedgeServerID | DWH_dbo.Dim_Position (source) | Hedge server assignment |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name (text) |
| IsCreditReportValidCB, IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | Customer validity flags |
| LiquidityAccountID | Dealing_staging.etoro_Trade_LiquidityAccounts | LA name resolution |
| Provider mapping | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Karen's LP mapping |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions | Companion table — populated by the same SP for omnibus reconciliation |
| BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 | Predecessor report — same instrument/regulation/hedge server grain with fewer columns |

---

## 7. Sample Queries

### 7.1 Close vs Current P&L Comparison by Provider

```sql
SELECT
    Provider,
    SUM(Close_PnLInDollars) AS ClosePnL,
    SUM(Current_PnLInDollars) AS CurrentPnL,
    SUM(Current_PnLInDollars) - SUM(Close_PnLInDollars) AS PnLDiff
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2025]
WHERE DateID = 20260411
  AND ClientHoldings = 'Client_Holdings'
GROUP BY Provider
ORDER BY ABS(SUM(Current_PnLInDollars) - SUM(Close_PnLInDollars)) DESC
```

### 7.2 Margin Loan Exposure by Exchange

```sql
SELECT
    Exchange,
    COUNT(*) AS Positions,
    SUM(TotalStockMarginLoan) AS TotalMarginLoan
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2025]
WHERE DateID = 20260411
  AND TotalStockMarginLoan <> 0
GROUP BY Exchange
ORDER BY TotalMarginLoan DESC
```

### 7.3 Liquidity Account Coverage Analysis

```sql
SELECT
    CASE WHEN LiquidityAccountID IS NULL OR LiquidityAccountID = '' THEN 'Unmapped'
         ELSE 'Mapped' END AS MappingStatus,
    COUNT(*) AS RowCount,
    SUM(EOD_Equity_USD) AS TotalEquity
FROM [BI_DB_dbo].[BI_DB_Finance_Non_US_Settlement_New_2025]
WHERE DateID = 20260411
  AND ClientHoldings = 'Client_Holdings'
GROUP BY CASE WHEN LiquidityAccountID IS NULL OR LiquidityAccountID = '' THEN 'Unmapped'
              ELSE 'Mapped' END
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 4 T1, 35 T2, 1 T3, 0 T4, 2 T5 | Elements: 44/44, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 | Type: Table | Production Source: SP_Finance_Non_US_Settlement_2025*
