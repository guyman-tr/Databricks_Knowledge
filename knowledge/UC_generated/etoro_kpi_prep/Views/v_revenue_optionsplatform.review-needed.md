# Review-needed sidecar — `v_revenue_optionsplatform`

Generated: 2026-05-18
Wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_optionsplatform.md`

## UNVERIFIED columns

| Column | Reason |
|--------|--------|
| `DateID` | transform='unknown' src='—'.'—'; no upstream wiki match AND no source-code expression found. |
| `Date` | transform='cast' src='—'.'TradeDate'; no upstream wiki match AND no source-code expression found. |
| `IsValidCustomer` | transform='join_enriched' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked'.'IsValidCustomer'; no upstream wiki match AND no source-code expression found. |
| `IsCreditReportValidCB` | transform='join_enriched' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked'.'IsCreditReportValidCB'; no upstream wiki match AND no source-code expression found. |
| `FirstTradeDate` | transform='cast' src='—'.'TradeDate'; no upstream wiki match AND no source-code expression found. |
| `FirstTradeDateID` | transform='unknown' src='—'.'—'; no upstream wiki match AND no source-code expression found. |

## Tier 4 candidates

_None._

## Cross-check mismatches

_None._

## Open questions

_None._
