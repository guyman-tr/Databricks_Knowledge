# Function_Instrument_Snapshot_Enriched

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Instrument |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 50 (T1: 46, T2: 4) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

dim instrument and dim instrument snapshot are not sufficient for rapid changes which are sometimes coming from Google Sheets etc.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @dateInt | INT | Date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Instrument | DWH_dbo |
| Dim_Instrument_Snapshot | DWH_dbo |
| Fact_CurrencyPriceWithSplit | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | Dim_Instrument_Snapshot.DateID | Snapshot date in yyyymmdd integer format -- represents "yesterday" relative to the ETL run date. The daily snapshot for business date 20260310 is loaded by the ETL run on 2026-03-11. FK to DWH_dbo.Dim_Date (DateID). Part of the natural composite key (DateID + InstrumentID). (Tier 2 -SP_Dim_Instrument_Snapshot) (via Dim_Instrument_Snapshot) | T2 |
| 2 | InstrumentID | etig.InstrumentID | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 3 | InstrumentTypeID | isn.InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 4 | InstrumentType | isn.InstrumentType | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T2 |
| 5 | Name | isn.Name | Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + '/' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels. (via Dim_Instrument) | T1 |
| 6 | IsFuture | isn.IsFuture | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 7 | IsSQF | DWH_staging.etoro_Trade_InstrumentGroups | `CASE WHEN adj.InstrumentID IS NOT NULL THEN 1 ELSE 0 END` **WHERE** `GroupID = 59`, joined on `dis.DateID >= adj.DateID` (adj carries `@dateInt` as DateID) | T2 |
| 8 | IsTicketFeePercentInstrument | Dim_Instrument, Fact_CurrencyPriceWithSplit | `CASE WHEN pws.Bid = pws.BidSpreaded AND di.InstrumentTypeID = 10 THEN 1 ELSE 0 END` **WHERE** `pws` joined on `di.InstrumentID` and `dis.DateID = pws.OccurredDateID` | T2 |
| 9 | DWHInstrumentID | isn.DWHInstrumentID | Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 10 | StatusID | isn.StatusID | Hardcoded to 1 for all data rows; NULL for sentinel row (InstrumentID=0). (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 11 | BuyCurrencyID | isn.BuyCurrencyID | Buy-side currency abbreviation. For forex: base currency code; for stocks: the asset code (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument (Tier 1 - Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 12 | SellCurrencyID | isn.SellCurrencyID | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 13 | BuyCurrency | isn.BuyCurrency | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 — Dictionary.Currency) (via Dim_Instrument) | T1 |
| 14 | SellCurrency | isn.SellCurrency | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) (via Dim_Instrument) | T1 |
| 15 | TradeRange | isn.TradeRange | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 16 | DollarRatio | isn.DollarRatio | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 17 | PipDifferenceThreshold | isn.PipDifferenceThreshold | Max pip difference for price validation. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 18 | IsMajorID | isn.IsMajorID | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 19 | IsMajor | isn.IsMajor | ETL-computed label from IsMajorID: 'Yes' when IsMajor=1, 'No' otherwise. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 20 | UpdateDate | isn.UpdateDate | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 21 | InsertDate | isn.InsertDate | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 22 | InstrumentDisplayName | isn.InstrumentDisplayName | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 23 | Industry | isn.Industry | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 24 | CompanyInfo | isn.CompanyInfo | Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 25 | Exchange | isn.Exchange | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 26 | ISINCode | isn.ISINCode | International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 27 | ISINCountryCode | isn.ISINCountryCode | Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 28 | Tradable | isn.Tradable | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 29 | Symbol | isn.Symbol | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 30 | ReceivedOnPriceServer | isn.ReceivedOnPriceServer | Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T1 |
| 31 | BonusCreditUsePercent | isn.BonusCreditUsePercent | Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 32 | SymbolFull | isn.SymbolFull | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument) | T1 |
| 33 | CUSIP | isn.CUSIP | CUSIP code sourced from Trade.InstrumentCusip (not InstrumentMetaData). Committee on Uniform Securities Identification Procedures identifier for US/Canada securities. NULL for forex, crypto, and many non-US instruments. (via Dim_Instrument) | T1 |
| 34 | Precision | isn.Precision | Decimal places for price display and rounding. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 35 | AllowBuy | isn.AllowBuy | 1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 36 | AllowSell | isn.AllowSell | 1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 37 | AssetClass | isn.AssetClass | Asset class classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. NULL for 13,557 of 15,707 rows. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) (via Dim_Instrument) | T1 |
| 38 | IndustryGroup | isn.IndustryGroup | Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) (via Dim_Instrument) | T1 |
| 39 | ADV_Last3Months | isn.ADV_Last3Months | Average daily trading volume over the last 3 months (TTM). From Rankings.StockInfo.InstrumentData MetadataID=8557. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) (via Dim_Instrument) | T1 |
| 40 | MKTcap | isn.MKTcap | Market capitalization. ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — uses stock market cap when available, falls back to crypto market cap. From Rankings.StockInfo MetadataID=8735/9315. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) (via Dim_Instrument) | T1 |
| 41 | SharesOutStanding | isn.SharesOutStanding | Current shares outstanding (annual). From Rankings.StockInfo.InstrumentData MetadataID=8444. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) (via Dim_Instrument) | T1 |
| 42 | VisibleInternallyOnly | isn.VisibleInternallyOnly | 1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 43 | PlatformSector | isn.PlatformSector | Platform-level sector classification from Rankings.StockInfo MetadataID=8436 (StrVal pivot). E.g., "Electronic Technology", "Technology Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) (via Dim_Instrument) | T1 |
| 44 | PlatformIndustry | isn.PlatformIndustry | Platform-level industry classification from Rankings.StockInfo MetadataID=8280 (StrVal pivot). E.g., "Telecommunications Equipment", "Internet Software Or Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) (via Dim_Instrument) | T1 |
| 45 | Multiplier | isn.Multiplier | Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). (Tier 1 — Trade.FuturesMetaData) (via Dim_Instrument) | T1 |
| 46 | ProviderID | isn.ProviderID | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tribe). From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 47 | ProviderMarginPerLot | isn.ProviderMarginPerLot | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. (Tier 1 — Trade.FuturesInstrumentsInitialMarginByProviderMapping) (via Dim_Instrument) | T1 |
| 48 | eToroMarginPerLot | isn.eToroMarginPerLot | Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) (via Dim_Instrument) | T1 |
| 49 | SettlementTime | isn.SettlementTime | Time-of-day settlement from Trade.FuturesMetaData, reformatted in SP_Dim_Instrument via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00') and cast to TIME. Primarily relevant for futures instruments. NULL for non-futures. (via Dim_Instrument) | T1 |
| 50 | Is_245_Instrument | Dim_Instrument (RTH CTEs) | `CASE WHEN COALESCE(eht.InstrumentID, rthi.InstrumentID) IS NOT NULL THEN 1 ELSE 0 END` — **eht** = `rth_instruments_regular` (Nasdaq/NYSE + ISIN/CUSIP match to RTH base); **rthi** = base RTH tradable set (`Exchange = 'Regular Trading Hours - RTH'`, `Tradable = 1`, `CompanyInfo NOT LIKE '%Dormant%'`) | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-07-07 | Guy M | Adj/Fivetran date parsing |
| 2025-10-20 | Guy M | Group 59 dictionary / staging |
| 2025-12-14 | Guy M | Is_245 indicator |
| 2025-12-25 | Guy M | Include regular ticker alongside RTH-only row |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
> **IsSQF business semantic (Tier 5 user expert 2026-05-14):** `IsSQF = 1` flags instruments that are **SpotQuotedFutures** — smaller-contract-size variants of eToro RealFutures, traded on the **CME (Chicago Mercantile Exchange)**. The technical predicate (`Trade.InstrumentGroups.GroupID = 59`) is correct; the business meaning is the product classification, NOT "Sustainable & Quality-Focused" (legacy fabricated narrative across DDR wikis until 2026-05-14) and NOT "Small Quantity Fee pricing model" (another fabricated narrative seen in Client_Balance_* wikis).
