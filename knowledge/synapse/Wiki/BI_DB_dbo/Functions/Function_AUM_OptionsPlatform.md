# Function_AUM_OptionsPlatform

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | AUM |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 9 (T1: 2, T2: 7) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns one row per customer linked via **Apex options** (`External_USABroker_Apex_Options`) to **buy-power** rows in `External_Sodreconciliation_apex_EXT981_BuyPowerSummary` where `OfficeCode IN ('4GS','5GU')`, house accounts excluded, `ProcessDate` equals the **latest** snapshot `<= CONVERT(date, @sdateInt)`, and the customer’s `Fact_SnapshotCustomer` range (`Dim_Range`) covers that `ProcessDate` as `DateID`. **OptionsTotalEquity / CashEquity / PositionMarketValue** are only meaningful under those joins and filters—not raw feed totals. Optional `@OnlyValidCustomers = 1` keeps `IsValidCustomer = 1`. First-options dates come from the **first** `ProcessDate` row per `AccountNumber` in the buy-power CTE (`ROW_NUMBER … RN = 1`).

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | As-of date (YYYYMMDD integer); drives latest `ProcessDate` from buy-power feed |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| External_Sodreconciliation_apex_EXT981_BuyPowerSummary | BI_DB_dbo |
| External_USABroker_Apex_Options | BI_DB_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_SnapshotCustomer.RealCID | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 2 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 3 | DateID | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.ProcessDate | `CONVERT(nvarchar(8), ProcessDate, 112)` **WHERE** `ProcessDate = (SELECT MAX(ProcessDate) FROM … WHERE ProcessDate <= @sdateInt)` **AND** options join + snapshot `Dim_Range` window **AND** `OfficeCode IN ('4GS','5GU')` **AND** account not in house list | T2 |
| 4 | Date | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.ProcessDate | `CONVERT(date, ProcessDate)` under same snapshot/join/filter predicates as DateID | T2 |
| 5 | OptionsTotalEquity | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.TotalEquity | `CAST(TotalEquity AS DECIMAL(18,2))` **WHERE** same Apex options + buy-power snapshot filters as DateID (not unfiltered `Amount`-style semantics) | T2 |
| 6 | OptionsCashEquity | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.CashEquity | `CAST(CashEquity AS DECIMAL(18,2))` **WHERE** same filters as OptionsTotalEquity | T2 |
| 7 | OptionsPositionMarketValue | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.PositionMarketValue | `CAST(PositionMarketValue AS DECIMAL(18,2))` **WHERE** same filters as OptionsTotalEquity | T2 |
| 8 | FirstOptionsAUMDateID | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.ProcessDate | First buy-power row per `AccountNumber` (`ROW_NUMBER` over `ProcessDate`, `RN = 1`); then `CONVERT(nvarchar(8), ff.ProcessDate, 112)` joined to snapshot row | T2 |
| 9 | FirstOptionsAUMDate | External_Sodreconciliation_apex_EXT981_BuyPowerSummary.ProcessDate | `CAST(ff.ProcessDate AS date)` from same `FIRSTFUNDING` join as row 8 | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-11-27 | Guy M | Distinct options rows; full outer coalesce across three platforms |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
