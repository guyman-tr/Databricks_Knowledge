# Review-needed sidecar — `v_revenue_stakingfee`

Generated: 2026-05-18
Wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_stakingfee.md`

## UNVERIFIED columns

| Column | Reason |
|--------|--------|
| `StakingMonthID` | transform='unknown' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'—'; no upstream wiki match AND no source-code expression found. |
| `Date` | transform='unknown' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'—'; no upstream wiki match AND no source-code expression found. |
| `DateID` | transform='unknown' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'—'; no upstream wiki match AND no source-code expression found. |
| `StakingMonth` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'StakingMonth'; no upstream wiki match AND no source-code expression found. |
| `StakingYear` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'StakingYear'; no upstream wiki match AND no source-code expression found. |
| `InstrumentID` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'InstrumentID'; no upstream wiki match AND no source-code expression found. |
| `CID` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'CID'; no upstream wiki match AND no source-code expression found. |
| `IsEligible` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'IsEligible'; no upstream wiki match AND no source-code expression found. |
| `NonEligible_PrimaryReason` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'NonEligible_PrimaryReason'; no upstream wiki match AND no source-code expression found. |
| `EtoroUSDDistributed` | transform='rename' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'Etoro_Amount_USD'; no upstream wiki match AND no source-code expression found. |
| `AirDropDateID` | transform='unknown' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'—'; no upstream wiki match AND no source-code expression found. |
| `ActualCompensationType` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'ActualCompensationType'; no upstream wiki match AND no source-code expression found. |
| `ClubCategory` | transform='passthrough' src='main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results'.'ClubCategory'; no upstream wiki match AND no source-code expression found. |
| `IsValidCustomer` | transform='join_enriched' src='main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked'.'IsValidCustomer'; no upstream wiki match AND no source-code expression found. |

## Tier 4 candidates

_None._

## Cross-check mismatches

_None._

## Open questions

_None._
