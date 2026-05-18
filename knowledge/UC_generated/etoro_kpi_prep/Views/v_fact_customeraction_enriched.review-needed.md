# Review-needed sidecar — `v_fact_customeraction_enriched`

Generated: 2026-05-18
Wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md`

## UNVERIFIED columns

| Column | Reason |
|--------|--------|
| `MoveMoneyReasonID` | transform='passthrough' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction'.'MoveMoneyReasonID'; no upstream wiki match AND no source-code expression found. |
| `etr_y` | transform='passthrough' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction'.'etr_y'; no upstream wiki match AND no source-code expression found. |
| `etr_ym` | transform='passthrough' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction'.'etr_ym'; no upstream wiki match AND no source-code expression found. |
| `etr_ymd` | transform='passthrough' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction'.'etr_ymd'; no upstream wiki match AND no source-code expression found. |
| `OpenDateID` | transform='cast' src='main.dwh.dim_position'.'OpenDateID'; no upstream wiki match AND no source-code expression found. |
| `CloseDateID` | transform='cast' src='main.dwh.dim_position'.'CloseDateID'; no upstream wiki match AND no source-code expression found. |
| `VolumeOnOpen` | transform='unknown' src='—'.'—'; no upstream wiki match AND no source-code expression found. |
| `VolumeOnClose` | transform='unknown' src='—'.'—'; no upstream wiki match AND no source-code expression found. |

## Tier 4 candidates

_None._

## Cross-check mismatches

_None._

## Open questions

_None._
