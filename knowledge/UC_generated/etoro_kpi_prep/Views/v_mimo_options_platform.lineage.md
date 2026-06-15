# Column Lineage: main.etoro_kpi_prep.v_mimo_options_platform

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_options_platform` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_mimo_options_platform.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_mimo_options_platform.json` (rows: 14, mismatches: 11) |
| **Primary upstream** | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT869_CashActivity.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |

## Lineage Chain

```
main.finance.bronze_sodreconciliation_apex_ext869_cashactivity   ←── primary upstream
  + main.general.bronze_usabroker_apex_options   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_mimo_options_platform   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `OfficeCode` | `—` | `OfficeCode` | `join_enriched` | — | mr.OfficeCode |
| 2 | `RegisteredRepCode` | `—` | `RegisteredRepCode` | `join_enriched` | — | mr.RegisteredRepCode |
| 3 | `AccountNumber` | `—` | `AccountNumber` | `join_enriched` | — | mr.AccountNumber |
| 4 | `DateID` | `—` | `DateID` | `join_enriched` | — | mr.DateID |
| 5 | `Date` | `—` | `Date` | `join_enriched` | — | mr.Date |
| 6 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dc.RealCID |
| 7 | `MIMOAction` | `—` | `—` | `case` | — | CASE WHEN mr.PayTypeCode = 'C' THEN 'Deposit' WHEN mr.PayTypeCode = 'D' THEN 'Withdraw' END AS MIMOAction |
| 8 | `AmountUSD` | `—` | `AmountUSD` | `join_enriched` | — | mr.AmountUSD |
| 9 | `IsFTD` | `—` | `—` | `case` | — | CASE WHEN NOT f.TransactionID IS NULL THEN 1 ELSE 0 END AS IsFTD |
| 10 | `IsInternalTransfer` | `—` | `IsInternalTransfer` | `join_enriched` | — | mr.IsInternalTransfer |
| 11 | `TransactionID` | `—` | `TransactionID` | `join_enriched` | — | mr.TransactionID |
| 12 | `IsGlobalFTD` | `—` | `—` | `coalesce` | — | COALESCE(f.IsGlobalFTD, 0) AS IsGlobalFTD |
| 13 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsValidCustomer` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsValidCustomer |
| 14 | `IsCreditReportValidCB` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsCreditReportValidCB` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsCreditReportValidCB |

## Cross-check vs system.access.column_lineage

- Total target columns: **14**
- OK: **3**, WARN: **0**, ERROR: **11**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `OfficeCode` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.officecode` | ERROR |
| `RegisteredRepCode` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.registeredrepcode` | ERROR |
| `AccountNumber` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.accountnumber` | ERROR |
| `DateID` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.processdate` | ERROR |
| `Date` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.processdate` | ERROR |
| `MIMOAction` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.paytypecode` | ERROR |
| `AmountUSD` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.amount` | ERROR |
| `IsFTD` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.acatscontrolnumber` | ERROR |
| `IsInternalTransfer` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.terminalid` | ERROR |
| `TransactionID` | — | `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity.acatscontrolnumber` | ERROR |
| `IsGlobalFTD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **13**

## Joins (detected)

- `INNER JOIN` — JOIN main.general.bronze_usabroker_apex_options AS op ON mr.AccountNumber = op.OptionsApexID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON op.GCID = dc.GCID
- `LEFT JOIN` — LEFT JOIN FinalFTD AS f ON f.AccountNumber = mr.AccountNumber AND f.Date = mr.Date AND f.TransactionID = mr.TransactionID
- `INNER JOIN` — JOIN main.general.bronze_usabroker_apex_options AS op ON ca.AccountNumber = op.OptionsApexID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON op.GCID = dc.GCID
- `LEFT JOIN` — LEFT JOIN (SELECT RealCID, CAST(FirstDepositDate AS DATE) AS DCFTDDate, FirstDepositAmount AS DCFTDAmount FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked WHERE FirstDepositDate >= '2025-09-01' AND FTDPlatformID = '2') AS dc_ft
- `INNER JOIN` — JOIN FINRAONLY_ftd_date AS fd ON mr.AccountNumber = fd.AccountNumber AND mr.Date = fd.FTDDate
- `INNER JOIN` — JOIN (SELECT AccountNumber, RealCID FROM FINRAONLY_FTD_records GROUP BY AccountNumber, RealCID HAVING COUNT(*) = 1) AS s ON f.AccountNumber = s.AccountNumber
- `LEFT JOIN` — LEFT JOIN GLOBAL_FTD AS gftd ON rns.RealCID = gftd.RealCID AND gftd.IsGlobalFTD = 1
