# Function_Population_Active_Traders

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 15 (T1: 3, T2: 12) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Flags **DDR-style “active traders”** per customer per `DateID` inside `[@sdateInt, @edateInt]`. **TP leg:** **`Fact_CustomerAction`** with **`ActionTypeID IN (1, 39, 15, 17)`**, **`ISNULL(IsAirDrop,0) = 0`**, customer in **`Fact_SnapshotCustomer`** with **`IsValidCustomer = 1`**, **`DateID`** in range and inside snapshot **`Dim_Range`**. **Options leg:** **`Function_Revenue_OptionsPlatform(@sdateInt, @edateInt, 1)`** rows with **`ActionTypeID = 1`**, joined to **`Dim_Customer`** for `GCID`. Unioned rows drive **`MAX(CASE …)`** asset-class and copy flags.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Mirror | DWH_dbo |
| Function_Revenue_OptionsPlatform | BI_DB_dbo |
| Dim_Customer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | GCID | Fact_CustomerAction.GCID, Dim_Customer.GCID | Direct from union branches | T1 |
| 2 | RealCID | Fact_CustomerAction.RealCID, Function_Revenue_OptionsPlatform.RealCID | Direct | T1 |
| 3 | DateID | Fact_CustomerAction.DateID, Function_Revenue_OptionsPlatform.DateID | Direct | T2 |
| 4 | ActiveTraded | *(literal)* | `1` | T2 |
| 5 | ActiveTradedManual | Fact_CustomerAction, Function_Revenue_OptionsPlatform | `MAX(CASE WHEN MirrorID = 0 THEN 1 ELSE 0 END)` **over rows matching** TP filters **(ActionTypeID IN (1,39,15,17), IsAirDrop=0, valid customer, date range)** **union** options branch **(ActionTypeID = 1)** | T2 |
| 6 | ActiveTradedCFD | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (1,2,4) THEN 1 ELSE 0 END)` | T2 |
| 7 | ActiveTradedCryptoCFD | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 0 THEN 1 ELSE 0 END)` | T2 |
| 8 | ActiveTradedCryptoReal | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (10) AND IsSettled = 1 THEN 1 ELSE 0 END)` | T2 |
| 9 | ActiveTradedStocksCFD | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 0 THEN 1 ELSE 0 END)` | T2 |
| 10 | ActiveTradedStocksReal | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (5) AND IsSettled = 1 THEN 1 ELSE 0 END)` | T2 |
| 11 | ActiveTradedETFCFD | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 0 THEN 1 ELSE 0 END)` | T2 |
| 12 | ActiveTradedETFReal | Fact_CustomerAction, Dim_Instrument, options branch | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID = 0 AND InstrumentTypeID IN (6) AND IsSettled = 1 THEN 1 ELSE 0 END)` | T2 |
| 13 | ActiveTradedCopy | Fact_CustomerAction, Function_Revenue_OptionsPlatform | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15,17) THEN 1 ELSE 0 END)` — **open/close copy actions only on TP leg** (options use `MirrorID = 0`) | T2 |
| 14 | ActiveTradedCopyFund | Fact_CustomerAction, Dim_Mirror | Same eligible rowset as row 5; `MAX(CASE WHEN MirrorID > 0 AND ActionTypeID IN (15,17) AND IsCopyFund = 1 THEN 1 ELSE 0 END)` with **`IsCopyFund`** from `Dim_Mirror.MirrorTypeID = 4` | T2 |
| 15 | ActiveTradedOptions | Fact_CustomerAction, Function_Revenue_OptionsPlatform | Same eligible rowset as row 5; `MAX(CASE WHEN InstrumentTypeID = 9 THEN 1 ELSE 0 END)` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-10-22 | Guy M | Added options trading |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
