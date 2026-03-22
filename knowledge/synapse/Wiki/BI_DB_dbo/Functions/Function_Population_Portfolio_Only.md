# Function_Population_Portfolio_Only

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 20 (T1: 0, T2: 20) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Identifies customers who qualify as **portfolio-only** under the DDR terminology framework: they hold open positions (or positive options buying power) in the date range but are **not** active traders in that same window. Flags break out manual vs copy, instrument families (CFD, crypto, stocks, ETF), copy-fund mirrors, and US options exposure from Apex buy-power data.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Position | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Mirror | DWH_dbo |
| External_Sodreconciliation_apex_EXT981_BuyPowerSummary | BI_DB_dbo |
| External_USABroker_Apex_Options | BI_DB_dbo |
| Dim_Customer | DWH_dbo |
| Function_Population_Active_Traders | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Dim_Position.CID, Dim_Customer.RealCID | COALESCE(position holder CID, options AUM RealCID) | T2 |
| 2 | Portfolio_Only | — | Literal 1 | T2 |
| 3 | Portfolio_Only_Manual | Dim_Position | MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END) | T2 |
| 4 | Portfolio_Only_CFD_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END) | T2 |
| 5 | Portfolio_Only_CryptoCFD_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 6 | Portfolio_Only_CryptoReal_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 7 | Portfolio_Only_StocksCFD_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 8 | Portfolio_Only_StocksReal_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 9 | Portfolio_Only_ETFCFD_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 10 | Portfolio_Only_ETFReal_Manual | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 11 | Portfolio_Only_Copy | Dim_Position | MAX(CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END) | T2 |
| 12 | Portfolio_Only_CFD_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END) | T2 |
| 13 | Portfolio_Only_CryptoCFD_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 14 | Portfolio_Only_CryptoReal_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 15 | Portfolio_Only_StocksCFD_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 16 | Portfolio_Only_StocksReal_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 17 | Portfolio_Only_ETFCFD_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END) | T2 |
| 18 | Portfolio_Only_ETFReal_Copy | Dim_Position, Dim_Instrument | MAX(CASE WHEN MirrorID > 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END) | T2 |
| 19 | Portfolio_Only_CopyFund | Dim_Position, Dim_Mirror | MAX(CASE WHEN MirrorID > 0 AND IsCopyFund = 1 THEN 1 ELSE 0 END); IsCopyFund from Dim_Mirror.MirrorTypeID = 4 | T2 |
| 20 | Portfolio_Only_Options | External_Sodreconciliation_apex_EXT981_BuyPowerSummary | MAX(CASE WHEN PositionMarketValue > 0 THEN 1 ELSE 0 END) | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-10-22 | Guy M | Added options AUM; noted function is single-date oriented elsewhere. |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
