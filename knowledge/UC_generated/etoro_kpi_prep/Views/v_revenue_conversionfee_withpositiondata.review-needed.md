# Review-needed sidecar — `v_revenue_conversionfee_withpositiondata`

Generated: 2026-05-18
Wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_conversionfee_withpositiondata.md`

## UNVERIFIED columns

| Column | Reason |
|--------|--------|
| `TransactionID` | transform='unknown' src='main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee'.'—'; no upstream wiki match AND no source-code expression found. |
| `IsSettled` | transform='join_enriched' src='main.dwh.dim_position'.'IsSettled'; no upstream wiki match AND no source-code expression found. |
| `IsBuy` | transform='join_enriched' src='main.dwh.dim_position'.'IsBuy'; no upstream wiki match AND no source-code expression found. |
| `Leverage` | transform='join_enriched' src='main.dwh.dim_position'.'Leverage'; no upstream wiki match AND no source-code expression found. |
| `IsAirDrop` | transform='join_enriched' src='main.dwh.dim_position'.'IsAirDrop'; no upstream wiki match AND no source-code expression found. |
| `IsValidCustomer` | transform='join_enriched' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked'.'IsValidCustomer'; no upstream wiki match AND no source-code expression found. |

## Tier 4 candidates

_None._

## Cross-check mismatches

_None._

## Open questions

_None._
