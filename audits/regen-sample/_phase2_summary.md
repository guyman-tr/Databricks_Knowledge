# Regen Harness Summary

_Generated from `_phase2_manifest.csv` -- 35 objects._

## Headline

- **BETTER**: 26 / 35
- **EQUIVALENT**: 8 / 35
- **WORSE**: 1 / 35

- **Total claude cost (all attempts + judges + current-judges)**: $110.85 USD
- **Total tokens**: in=728  out=984,917

## Per-bucket breakdown

| Bucket | Total | BETTER | EQUIVALENT | WORSE | Other |
|---|---|---|---|---|---|
| slop | 35 | 26 | 8 | 1 | 0 |

## Per-schema breakdown

| Schema | Total | BETTER | EQUIVALENT | WORSE | Other |
|---|---|---|---|---|---|
| BI_DB_dbo | 6 | 3 | 3 | 0 | 0 |
| DWH_dbo | 9 | 7 | 2 | 0 | 0 |
| Dealing_dbo | 20 | 16 | 3 | 1 | 0 |

## Per-object detail

| Schema | Object | Bucket | Q (self) | Q (judge cur) | Q (judge regen) | Slop before | Slop after | Verdict | Score delta |
|---|---|---|---|---|---|---|---|---|---|
| BI_DB_dbo | BI_DB_Adwords_Dictionary_AdGroup | slop | 8 | 8.25 | 8.95 | 1 | 1 | BETTER | +0.7 |
| BI_DB_dbo | BI_DB_Adwords_Keywords_Conv | slop | 8 | 8.75 | 8.95 | 1 | 1 | EQUIVALENT | +0.2 |
| BI_DB_dbo | BI_DB_Adwords_Keywords_Pref | slop | 8 | 8.75 | 8.85 | 1 | 1 | EQUIVALENT | +0.1 |
| BI_DB_dbo | BI_DB_Adwords_Search_Conv | slop | 8 | 8.75 | 8.45 | 2 | 0 | EQUIVALENT | -0.3 |
| BI_DB_dbo | BI_DB_CID_Daily_AcquisitionFunnel_VBT | slop | 9 | 6.3 | 9.4 | 1 | 0 | BETTER | +3.1 |
| BI_DB_dbo | BI_DB_CIDFirstDates | slop | 9.5 | 4.8 | 7.3 | 1 | 0 | BETTER | +2.5 |
| Dealing_dbo | Dealing_Apex_PnL | slop | 7.5 | 7.85 | 9.0 | 1 | 1 | BETTER | +1.15 |
| Dealing_dbo | Dealing_Apex_PnL_Daily | slop | 7.5 | 7.0 | 8.25 | 1 | 0 | BETTER | +1.25 |
| Dealing_dbo | Dealing_Apex_PnL_EE | slop | 7.5 | 8.15 | 8.25 | 1 | 0 | EQUIVALENT | +0.1 |
| Dealing_dbo | Dealing_Apex_PnL_EE_Daily | slop | 7.5 | 7.4 | 8.75 | 2 | 0 | BETTER | +1.35 |
| Dealing_dbo | Dealing_Boundary_Cost | slop | - | 4.25 | 6.95 | 1 | 0 | BETTER | +2.7 |
| Dealing_dbo | Dealing_CEPDailyAudit_Conditions | slop | 8 | 7.8 | 8.65 | 2 | 0 | BETTER | +0.85 |
| Dealing_dbo | Dealing_CEPDailyAudit_ConditionToCP | slop | 7.8 | 7.7 | 8.5 | 2 | 0 | BETTER | +0.8 |
| Dealing_dbo | Dealing_CEPDailyAudit_CP | slop | 8 | 7.8 | 8.9 | 2 | 0 | BETTER | +1.1 |
| Dealing_dbo | Dealing_CEPDailyAudit_CPToRule | slop | 8 | 8.0 | 8.6 | 2 | 0 | BETTER | +0.6 |
| Dealing_dbo | Dealing_CEPDailyAudit_ListCIDMapping | slop | 7.5 | 7.9 | 9.0 | 2 | 0 | BETTER | +1.1 |
| Dealing_dbo | Dealing_CEPDailyAudit_NameLists | slop | 7.5 | 7.8 | 8.85 | 2 | 0 | BETTER | +1.05 |
| Dealing_dbo | Dealing_CEPDailyAudit_Rules | slop | 8.5 | 7.3 | 8.9 | 2 | 0 | BETTER | +1.6 |
| Dealing_dbo | Dealing_CEPWeeklyAudit_Conditions | slop | 8 | 7.75 | 8.75 | 2 | 0 | BETTER | +1.0 |
| Dealing_dbo | Dealing_CEPWeeklyAudit_ConditionToCP | slop | 7.8 | 8.65 | 8.75 | 2 | 0 | EQUIVALENT | +0.1 |
| Dealing_dbo | Dealing_CEPWeeklyAudit_CP | slop | 8 | 8.05 | 8.7 | 2 | 0 | BETTER | +0.65 |
| Dealing_dbo | Dealing_CEPWeeklyAudit_CPToRule | slop | 7.8 | 8.35 | 8.35 | 2 | 0 | EQUIVALENT | +0.0 |
| Dealing_dbo | Dealing_CEPWeeklyAudit_ListCIDMapping | slop | 7.5 | 6.95 | 8.9 | 2 | 0 | BETTER | +1.95 |
| Dealing_dbo | Dealing_Execution_Slippage | slop | 8 | 7.9 | 6.8 | 1 | 1 | WORSE | -1.1 |
| Dealing_dbo | Dealing_HedgeCost | slop | - | 4.2 | 7.3 | 1 | 0 | BETTER | +3.1 |
| Dealing_dbo | Dealing_IGReconEODHolding | slop | 7.8 | 7.6 | 9.05 | 1 | 0 | BETTER | +1.45 |
| DWH_dbo | Dim_ActionType | slop | 7.7 | 8.1 | 8.85 | 1 | 0 | BETTER | +0.75 |
| DWH_dbo | Dim_CardType | slop | 7.9 | 6.45 | 8.35 | 1 | 0 | BETTER | +1.9 |
| DWH_dbo | Dim_CashoutReason | slop | 9 | 7.05 | 8.85 | 1 | 0 | BETTER | +1.8 |
| DWH_dbo | Dim_Channel | slop | 7.7 | 7.8 | 8.75 | 1 | 0 | BETTER | +0.95 |
| DWH_dbo | Dim_ContractType | slop | 6.8 | 8.2 | 8.45 | 1 | 0 | EQUIVALENT | +0.25 |
| DWH_dbo | Dim_HistorySplitRatio | slop | 8.2 | 5.15 | 9.5 | 1 | 0 | BETTER | +4.35 |
| DWH_dbo | Dim_Instrument | slop | 9.4 | 4.15 | 8.2 | 1 | 0 | BETTER | +4.05 |
| DWH_dbo | Dim_MoveMoneyReason | slop | 7.3 | 7.05 | 8.55 | 1 | 0 | BETTER | +1.5 |
| DWH_dbo | Fact_CurrencyPriceWithSplit | slop | 7.7 | 8.45 | 8.55 | 1 | 0 | EQUIVALENT | +0.1 |

## Decision guidance

- **Mixed signal**: 26 BETTER vs 1 WORSE. Recommend running the slop-only subset (47 known-slop objects) before committing to a full re-run.
