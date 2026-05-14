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
| 1 | DateID | Dim_Instrument_Snapshot.DateID | Direct | T1 |
| 2 | InstrumentID | etig.InstrumentID | Direct | T1 |
| 3 | InstrumentTypeID | isn.InstrumentTypeID | Direct | T1 |
| 4 | InstrumentType | isn.InstrumentType | Direct | T1 |
| 5 | Name | isn.Name | Direct | T1 |
| 6 | IsFuture | isn.IsFuture | Direct | T1 |
| 7 | IsSQF | DWH_staging.etoro_Trade_InstrumentGroups | `CASE WHEN adj.InstrumentID IS NOT NULL THEN 1 ELSE 0 END` **WHERE** `GroupID = 59`, joined on `dis.DateID >= adj.DateID` (adj carries `@dateInt` as DateID) | T2 |
| 8 | IsTicketFeePercentInstrument | Dim_Instrument, Fact_CurrencyPriceWithSplit | `CASE WHEN pws.Bid = pws.BidSpreaded AND di.InstrumentTypeID = 10 THEN 1 ELSE 0 END` **WHERE** `pws` joined on `di.InstrumentID` and `dis.DateID = pws.OccurredDateID` | T2 |
| 9 | DWHInstrumentID | isn.DWHInstrumentID | Direct | T1 |
| 10 | StatusID | isn.StatusID | Direct | T1 |
| 11 | BuyCurrencyID | isn.BuyCurrencyID | Direct | T1 |
| 12 | SellCurrencyID | isn.SellCurrencyID | Direct | T1 |
| 13 | BuyCurrency | isn.BuyCurrency | Direct | T1 |
| 14 | SellCurrency | isn.SellCurrency | Direct | T1 |
| 15 | TradeRange | isn.TradeRange | Direct | T1 |
| 16 | DollarRatio | isn.DollarRatio | Direct | T1 |
| 17 | PipDifferenceThreshold | isn.PipDifferenceThreshold | Direct | T1 |
| 18 | IsMajorID | isn.IsMajorID | Direct | T1 |
| 19 | IsMajor | isn.IsMajor | Direct | T1 |
| 20 | UpdateDate | isn.UpdateDate | Direct | T1 |
| 21 | InsertDate | isn.InsertDate | Direct | T1 |
| 22 | InstrumentDisplayName | isn.InstrumentDisplayName | Direct | T1 |
| 23 | Industry | isn.Industry | Direct | T1 |
| 24 | CompanyInfo | isn.CompanyInfo | Direct | T1 |
| 25 | Exchange | isn.Exchange | Direct | T1 |
| 26 | ISINCode | isn.ISINCode | Direct | T1 |
| 27 | ISINCountryCode | isn.ISINCountryCode | Direct | T1 |
| 28 | Tradable | isn.Tradable | Direct | T1 |
| 29 | Symbol | isn.Symbol | Direct | T1 |
| 30 | ReceivedOnPriceServer | isn.ReceivedOnPriceServer | Direct | T1 |
| 31 | BonusCreditUsePercent | isn.BonusCreditUsePercent | Direct | T1 |
| 32 | SymbolFull | isn.SymbolFull | Direct | T1 |
| 33 | CUSIP | isn.CUSIP | Direct | T1 |
| 34 | Precision | isn.Precision | Direct | T1 |
| 35 | AllowBuy | isn.AllowBuy | Direct | T1 |
| 36 | AllowSell | isn.AllowSell | Direct | T1 |
| 37 | AssetClass | isn.AssetClass | Direct | T1 |
| 38 | IndustryGroup | isn.IndustryGroup | Direct | T1 |
| 39 | ADV_Last3Months | isn.ADV_Last3Months | Direct | T1 |
| 40 | MKTcap | isn.MKTcap | Direct | T1 |
| 41 | SharesOutStanding | isn.SharesOutStanding | Direct | T1 |
| 42 | VisibleInternallyOnly | isn.VisibleInternallyOnly | Direct | T1 |
| 43 | PlatformSector | isn.PlatformSector | Direct | T1 |
| 44 | PlatformIndustry | isn.PlatformIndustry | Direct | T1 |
| 45 | Multiplier | isn.Multiplier | Direct | T1 |
| 46 | ProviderID | isn.ProviderID | Direct | T1 |
| 47 | ProviderMarginPerLot | isn.ProviderMarginPerLot | Direct | T1 |
| 48 | eToroMarginPerLot | isn.eToroMarginPerLot | Direct | T1 |
| 49 | SettlementTime | isn.SettlementTime | Direct | T1 |
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
