# Function_Revenue_OptionsPlatform

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | — |
| **Output Columns** | 26 (T1: 5, T2: 21) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Aggregates US options/equity PFOF (payment for order flow) payback from Apex reconciliation revenue reports per customer and trade date, shaped like other revenue metrics (action types, instrument type, transaction counts). Maps clearing accounts to internal customers via the US broker options bridge table and excludes designated house accounts. The **`Amount`** column is `SUM(ABS(CustomerPFOFPayback))` only over rows whose `TradeDate` falls between the parameter dates and whose `ClearingAccount` is not in the excluded house list.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| External_USABroker_Apex_Options | BI_DB_dbo |
| Sodreconciliation_apex_EXT1047_RevenueReports | BI_DB_dbo |
| Dim_Customer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate | CONVERT(NVARCHAR(8), TradeDate, 112) | T2 |
| 2 | Date | Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate | CONVERT(DATE, TradeDate) | T2 |
| 3 | RealCID | Dim_Customer.RealCID | Direct | T1 |
| 4 | ActionTypeID | Sodreconciliation_apex_EXT1047_RevenueReports.Side | CASE WHEN Side = 'B' THEN 1 WHEN Side = 'S' THEN 4 END | T2 |
| 5 | ActionType | Sodreconciliation_apex_EXT1047_RevenueReports.Side | CASE WHEN Side = 'B' THEN 'ManualPositionOpen' WHEN Side = 'S' THEN 'ManualPositionClose' END | T2 |
| 6 | InstrumentTypeID | Sodreconciliation_apex_EXT1047_RevenueReports.InstrumentType | CASE WHEN InstrumentType = 'Option' THEN 9 WHEN InstrumentType = 'Equity' THEN 5 END | T2 |
| 7 | IsSettled | — | 1 | T2 |
| 8 | IsCopy | — | 0 | T2 |
| 9 | Metric | — | 'Options_PFOF' | T2 |
| 10 | Amount | Sodreconciliation_apex_EXT1047_RevenueReports.CustomerPFOFPayback | SUM(ABS(CustomerPFOFPayback)) WHERE ClearingAccount NOT IN (excluded house accounts) AND TradeDate BETWEEN CONVERT(DATE, CONVERT(VARCHAR(8), @sdateInt), 112) AND CONVERT(DATE, CONVERT(VARCHAR(8), @edateInt), 112) (GROUP BY trade date, customer, side, instrument type, etc.) | T2 |
| 11 | CountTransactions | Sodreconciliation_apex_EXT1047_RevenueReports.OrderID | COUNT(OrderID) | T2 |
| 12 | IncludedInTotalRevenue | — | 1 | T2 |
| 13 | CountAsActiveTrade | Sodreconciliation_apex_EXT1047_RevenueReports.Side | CASE WHEN Side = 'B' THEN 1 ELSE 0 END | T2 |
| 14 | UpdateDate | — | GETDATE() | T2 |
| 15 | IsBuy | — | 1 | T2 |
| 16 | IsLeveraged | — | 0 | T2 |
| 17 | IsFuture | — | 0 | T2 |
| 18 | IsCopyFund | — | 0 | T2 |
| 19 | IsOpenedFromIBAN | — | 0 | T2 |
| 20 | IsClosedToIBAN | — | 0 | T2 |
| 21 | IsRucurring | — | 0 | T2 |
| 22 | IsAirDrop | — | 0 | T2 |
| 23 | IsValidCustomer | Dim_Customer.IsValidCustomer | Direct | T2 |
| 24 | IsCreditReportValidCB | Dim_Customer.IsCreditReportValidCB | Direct | T2 |
| 25 | FirstTradeDate | Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate | First row per ClearingAccount (ROW_NUMBER partition) | T2 |
| 26 | FirstTradeDateID | Sodreconciliation_apex_EXT1047_RevenueReports.TradeDate | CAST(FORMAT(CAST(TradeDate AS DATE),'yyyyMMdd') AS INT) on first trade | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
