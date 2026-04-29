# Regen Harness Summary

_Generated from `manifest.csv` -- 25 objects._

## Headline

- **BETTER**: 15 / 25
- **EQUIVALENT**: 8 / 25
- **WORSE**: 2 / 25

- **Total claude cost (all attempts + judges + current-judges)**: $73.37 USD
- **Total tokens**: in=855  out=897,199

## Per-bucket breakdown

| Bucket | Total | BETTER | EQUIVALENT | WORSE | Other |
|---|---|---|---|---|---|
| dormant | 5 | 3 | 2 | 0 | 0 |
| good | 5 | 3 | 2 | 0 | 0 |
| median | 5 | 2 | 3 | 0 | 0 |
| random | 5 | 4 | 1 | 0 | 0 |
| slop | 5 | 3 | 0 | 2 | 0 |

## Per-schema breakdown

| Schema | Total | BETTER | EQUIVALENT | WORSE | Other |
|---|---|---|---|---|---|
| BI_DB_dbo | 5 | 3 | 1 | 1 | 0 |
| DWH_dbo | 5 | 3 | 2 | 0 | 0 |
| Dealing_dbo | 5 | 5 | 0 | 0 | 0 |
| EXW_dbo | 5 | 3 | 2 | 0 | 0 |
| eMoney_dbo | 5 | 1 | 3 | 1 | 0 |

## Per-object detail

| Schema | Object | Bucket | Q (self) | Q (judge cur) | Q (judge regen) | Slop before | Slop after | Verdict | Score delta |
|---|---|---|---|---|---|---|---|---|---|
| BI_DB_dbo | BI_DB_CIDFunnelFlow | good | 9.68 | 6.8 | 7.55 | 0 | 0 | BETTER | +0.75 |
| BI_DB_dbo | BI_DB_AB_Test | median | 7.50 | 8.85 | 9.15 | 0 | 0 | EQUIVALENT | +0.3 |
| BI_DB_dbo | BI_DB_AdvancedDeposit_Ext | slop | 7.00 | 7.75 | 6.6 | 47 | 0 | WORSE | -1.15 |
| BI_DB_dbo | BI_DB_AffData | dormant | 7.00 | 7.9 | 8.2 | 10 | 0 | BETTER | +0.3 |
| BI_DB_dbo | BI_DB_Failed_Verification_MA | random | 8.00 | 5.0 | 9.1 | 0 | 0 | BETTER | +4.1 |
| DWH_dbo | V_Liabilities | good | 9.20 | 5.3 | 8.75 | 0 | 0 | BETTER | +3.45 |
| DWH_dbo | Dim_ExecutionOperationType | median | 7.50 | 8.25 | 8.15 | 0 | 0 | EQUIVALENT | -0.1 |
| DWH_dbo | Fact_Deposit_Fees | slop | 7.40 | 6.6 | 8.95 | 14 | 0 | BETTER | +2.35 |
| DWH_dbo | Dim_ContactType | dormant | 4.50 | 8.1 | 8.5 | 1 | 0 | EQUIVALENT | +0.4 |
| DWH_dbo | Dim_AccountType | random | 8.00 | 5.65 | 8.55 | 0 | 0 | BETTER | +2.9 |
| Dealing_dbo | Dealing_Islamic_Daily_Administrative_Fee | good | 9.00 | 4.2 | 9.3 | 0 | 0 | BETTER | +5.1 |
| Dealing_dbo | Dealing_Apex_PnL | median | 7.50 | 6.15 | 9.0 | 1 | 1 | BETTER | +2.85 |
| Dealing_dbo | Dealing_SaxoRecon_FXnCommed_Trades | slop | - | 7.0 | 8.95 | 20 | 0 | BETTER | +1.95 |
| Dealing_dbo | Dealing_MarketMakerAllTradeEtoroX | dormant | 5.00 | 4.5 | 8.35 | 0 | 0 | BETTER | +3.85 |
| Dealing_dbo | Dealing_CME_Reporting | random | 8.00 | 4.3 | 8.65 | 0 | 0 | BETTER | +4.35 |
| eMoney_dbo | eMoney_Dictionary_TransactionType | good | 9.30 | 8.95 | 8.75 | 0 | 0 | EQUIVALENT | -0.2 |
| eMoney_dbo | eMoney_Client_Balance_Check_Exceptions_Gap | median | 8.50 | 8.85 | 9.1 | 0 | 0 | EQUIVALENT | +0.25 |
| eMoney_dbo | eMoney_Client_Balance_Check_Opening_Balance | slop | 8.50 | 8.85 | 8.35 | 0 | 0 | WORSE | -0.5 |
| eMoney_dbo | eMoney_Currency_Instrument_Mapping_Static | dormant | - | 7.05 | 8.55 | 0 | 0 | BETTER | +1.5 |
| eMoney_dbo | eMoney_Dictionary_AccountProgram | random | 9.10 | 9.25 | 9.05 | 0 | 0 | EQUIVALENT | -0.2 |
| EXW_dbo | EXW_FactTransactions | good | 9.40 | 9.6 | 9.3 | 0 | 0 | EQUIVALENT | -0.3 |
| EXW_dbo | EXW_Conversion_Allowed_Country | median | 7.50 | 4.5 | 9.5 | 0 | 0 | BETTER | +5.0 |
| EXW_dbo | EXW_Payment_Allowed_Country | slop | 7.50 | 5.1 | 7.9 | 0 | 0 | BETTER | +2.8 |
| EXW_dbo | EXW_ReportingBalances | dormant | 7.50 | 7.8 | 8.0 | 0 | 0 | EQUIVALENT | +0.2 |
| EXW_dbo | EXW_FactConversions | random | 8.40 | 7.65 | 9.35 | 0 | 0 | BETTER | +1.7 |

## Decision guidance

- **Mixed signal**: 15 BETTER vs 2 WORSE. Recommend running the slop-only subset (47 known-slop objects) before committing to a full re-run.
