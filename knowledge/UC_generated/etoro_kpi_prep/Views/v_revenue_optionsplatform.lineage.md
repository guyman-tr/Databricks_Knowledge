# Column Lineage: main.etoro_kpi_prep.v_revenue_optionsplatform

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_optionsplatform` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_optionsplatform.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_optionsplatform.json` (rows: 26, mismatches: 10) |
| **Primary upstream** | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1047_RevenueReports.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |

## Lineage Chain

```
main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports   ←── primary upstream
  + main.general.bronze_usabroker_apex_options   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_optionsplatform   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(rev.TradeDate, 'yyyyMMdd') AS INT) AS DateID |
| 2 | `Date` | `—` | `TradeDate` | `cast` | — | cast to DATE — CAST(rev.TradeDate AS DATE) AS Date |
| 3 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RealCID |
| 4 | `ActionTypeID` | `—` | `—` | `case` | — | CASE WHEN rev.Side = 'B' THEN 1 WHEN rev.Side = 'S' THEN 4 END AS ActionTypeID |
| 5 | `ActionType` | `—` | `—` | `case` | — | CASE WHEN rev.Side = 'B' THEN 'ManualPositionOpen' WHEN rev.Side = 'S' THEN 'ManualPositionClose' END AS ActionType |
| 6 | `InstrumentTypeID` | `—` | `—` | `case` | — | CASE WHEN rev.InstrumentType = 'Option' THEN 9 WHEN rev.InstrumentType = 'Equity' THEN 5 END AS InstrumentTypeID |
| 7 | `IsSettled` | `—` | `—` | `literal` | — | literal `1` — 1 AS IsSettled |
| 8 | `IsCopy` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsCopy |
| 9 | `Metric` | `—` | `—` | `literal` | — | literal `'Options_PFOF'` — 'Options_PFOF' AS Metric |
| 10 | `Amount` | `—` | `—` | `aggregate` | — | SUM(ABS(rev.CustomerPFOFPayback)) AS Amount |
| 11 | `CountTransactions` | `—` | `—` | `aggregate` | — | COUNT(rev.OrderID) AS CountTransactions |
| 12 | `IncludedInTotalRevenue` | `—` | `—` | `literal` | — | literal `1` — 1 AS IncludedInTotalRevenue |
| 13 | `CountAsActiveTrade` | `—` | `—` | `case` | — | CASE WHEN rev.Side = 'B' THEN 1 ELSE 0 END AS CountAsActiveTrade |
| 14 | `UpdateDate` | `—` | `—` | `literal` | — | literal `CURRENT_TIMESTAMP()` — CURRENT_TIMESTAMP() AS UpdateDate |
| 15 | `IsBuy` | `—` | `—` | `literal` | — | literal `1` — 1 AS IsBuy |
| 16 | `IsLeveraged` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsLeveraged |
| 17 | `IsFuture` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsFuture |
| 18 | `IsCopyFund` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsCopyFund |
| 19 | `IsOpenedFromIBAN` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsOpenedFromIBAN |
| 20 | `IsClosedToIBAN` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsClosedToIBAN |
| 21 | `IsRecurring` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsRecurring |
| 22 | `IsAirDrop` | `—` | `—` | `literal` | — | literal `0` — 0 AS IsAirDrop |
| 23 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsValidCustomer` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsValidCustomer |
| 24 | `IsCreditReportValidCB` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsCreditReportValidCB` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsCreditReportValidCB |
| 25 | `FirstTradeDate` | `—` | `TradeDate` | `cast` | — | cast to DATE — CAST(ft.TradeDate AS DATE) AS FirstTradeDate |
| 26 | `FirstTradeDateID` | `—` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(ft.TradeDate AS DATE), 'yyyyMMdd') AS INT) AS FirstTradeDateID |

## Cross-check vs system.access.column_lineage

- Total target columns: **26**
- OK: **16**, WARN: **0**, ERROR: **10**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.tradedate` | ERROR |
| `Date` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.tradedate` | ERROR |
| `ActionTypeID` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.side` | ERROR |
| `ActionType` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.side` | ERROR |
| `InstrumentTypeID` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.instrumenttype` | ERROR |
| `Amount` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.customerpfofpayback` | ERROR |
| `CountTransactions` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.orderid` | ERROR |
| `CountAsActiveTrade` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.side` | ERROR |
| `FirstTradeDate` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.tradedate` | ERROR |
| `FirstTradeDateID` | — | `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports.tradedate` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **22**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN FIRSTTRADE AS ft ON rev.ClearingAccount = ft.ClearingAccount
- `LEFT JOIN` — LEFT JOIN main.general.bronze_usabroker_apex_options AS op ON rev.ClearingAccount = op.OptionsApexID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON op.GCID = dc.GCID
