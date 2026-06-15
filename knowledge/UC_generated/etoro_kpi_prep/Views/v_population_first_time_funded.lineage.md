# Column Lineage: main.etoro_kpi_prep.v_population_first_time_funded

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_first_time_funded` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_first_time_funded.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_first_time_funded.json` (rows: 18, mismatches: 18) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.etoro_kpi_prep.v_globalftdplatform` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_globalftdplatform.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.etoro_kpi_prep.v_mimo_allplatforms` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_mimo_allplatforms.md` |
| `main.etoro_kpi_prep.v_revenue_optionsplatform` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_optionsplatform.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.etoro_kpi_prep.v_globalftdplatform   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.dim_position   (JOIN)
  + main.etoro_kpi_prep.v_revenue_optionsplatform   (JOIN)
  + main.etoro_kpi_prep.v_mimo_allplatforms   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_first_time_funded   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | f.RealCID |
| 2 | `FTDPlatformID` | `—` | `FTDPlatformID` | `join_enriched` | — | f.FTDPlatformID /* FTD */ |
| 3 | `FTDPlatform` | `—` | `FTDPlatform` | `join_enriched` | — | f.FTDPlatform |
| 4 | `FTDDateID` | `—` | `FTDDateID` | `join_enriched` | — | f.FTDDateID |
| 5 | `FTDDate` | `—` | `FTDDate` | `join_enriched` | — | f.FTDDate |
| 6 | `FTDTime` | `—` | `FTDTime` | `join_enriched` | — | f.FTDTime |
| 7 | `FirstTradeDateID` | `—` | `FirstTradeDateID` | `join_enriched` | — | t.FirstTradeDateID /* Trades & Activities */ |
| 8 | `FirstTradeDate` | `—` | `FirstTradeDate` | `join_enriched` | — | t.FirstTradeDate |
| 9 | `FirstTradeTime` | `—` | `FirstTradeTime` | `join_enriched` | — | t.FirstTradeTime |
| 10 | `FirstIOBDateID` | `—` | `FirstIOBDateID` | `join_enriched` | — | iob.FirstIOBDateID |
| 11 | `FirstIOBDate` | `—` | `FirstIOBDate` | `join_enriched` | — | iob.FirstIOBDate |
| 12 | `FirstIOBTime` | `—` | `FirstIOBTime` | `join_enriched` | — | iob.FirstIOBTime |
| 13 | `FirstOptionsTradeDateID` | `—` | `FirstOptionsTradeDateID` | `join_enriched` | — | ot.FirstOptionsTradeDateID |
| 14 | `FirstOptionsTradeDate` | `—` | `FirstOptionsTradeDate` | `join_enriched` | — | ot.FirstOptionsTradeDate |
| 15 | `FirstVerifiedDateID` | `—` | `FirstVerifiedDateID` | `join_enriched` | — | v.FirstVerifiedDateID /* Verification */ |
| 16 | `FirstVerifiedDate` | `—` | `FirstVerifiedDate` | `join_enriched` | — | v.FirstVerifiedDate |
| 17 | `FirstFundedDateID` | `—` | `—` | `unknown` | — | GREATEST(f.FTDDateID, v.FirstVerifiedDateID, COALESCE(LEAST(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID), COALESCE(t. |
| 18 | `FirstFundedDate` | `—` | `—` | `unknown` | — | TO_DATE(CAST(GREATEST(f.FTDDateID, v.FirstVerifiedDateID, COALESCE(LEAST(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID) |

## Cross-check vs system.access.column_lineage

- Total target columns: **18**
- OK: **0**, WARN: **0**, ERROR: **18**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RealCID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `FTDPlatformID` | — | `main.etoro_kpi_prep.v_globalftdplatform.ftdplatformid` | ERROR |
| `FTDPlatform` | — | `main.etoro_kpi_prep.v_globalftdplatform.name` | ERROR |
| `FTDDateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `FTDDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `FTDTime` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `FirstTradeDateID` | — | `main.dwh.dim_position.opendateid` | ERROR |
| `FirstTradeDate` | — | `main.dwh.dim_position.opendateid` | ERROR |
| `FirstTradeTime` | — | `main.dwh.dim_position.openoccurred` | ERROR |
| `FirstIOBDateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred` | ERROR |
| `FirstIOBDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred` | ERROR |
| `FirstIOBTime` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred` | ERROR |
| `FirstOptionsTradeDateID` | — | `main.etoro_kpi_prep.v_revenue_optionsplatform.firsttradedateid` | ERROR |
| `FirstOptionsTradeDate` | — | `main.etoro_kpi_prep.v_revenue_optionsplatform.firsttradedate` | ERROR |
| `FirstVerifiedDateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.fromdateid` | ERROR |
| `FirstVerifiedDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.fromdateid` | ERROR |
| `FirstFundedDateID` | — | `main.dwh.dim_position.opendateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.fromdateid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.firsttradedateid` | ERROR |
| `FirstFundedDate` | — | `main.dwh.dim_position.opendateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.fromdateid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.firsttradedateid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **16**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `INNER INNER` — INNER JOIN Verification AS v ON f.RealCID = v.RealCID
- `LEFT JOIN` — LEFT JOIN Trade AS t ON f.RealCID = t.RealCID
- `LEFT JOIN` — LEFT JOIN First_IOB AS iob ON f.RealCID = iob.RealCID
- `LEFT JOIN` — LEFT JOIN OptionsTrade AS ot ON f.RealCID = ot.RealCID
- `LEFT JOIN` — LEFT JOIN main.etoro_kpi_prep.v_globalftdplatform AS ftd ON ftd.FTDPlatformID = dc.FTDPlatformID
