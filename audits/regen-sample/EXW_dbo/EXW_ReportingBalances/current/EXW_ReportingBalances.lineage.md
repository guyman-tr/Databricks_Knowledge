---
object: EXW_dbo.EXW_ReportingBalances
type: Table
writer_sp: None found in SSDT — external ETL (Python/ADF or equivalent)
upstream_source: Unknown external ETL — likely WalletDB + EXW_WalletInventory + regulatory enrichment
lineage_generated: 2026-04-20
---

# Column Lineage — EXW_dbo.EXW_ReportingBalances

## ETL Chain

```
[External ETL — Python/ADF, not in SSDT repo]
  |-- Likely same pattern as EXW_EOMReportingBalances ---|
  v
EXW_dbo.EXW_ReportingBalances (empty — 0 rows as of 2026-04-20)
  |-- UC Target: _Not_Migrated ---|
```

## Column Lineage

| # | DWH Column | Source | Tier | Notes |
|---|-----------|--------|------|-------|
| 1 | ReportingDate | External ETL | Tier 4 | Month-end date (last day of reporting month); NOT NULL |
| 2 | [eToro Unique ID 1 GCID] | External ETL (WalletDB) | Tier 4 | Global Customer ID; HASH distribution key |
| 3 | [eToro Unique ID 2 CID] | External ETL (eToro platform) | Tier 4 | Legacy CID; NOT NULL |
| 4 | [eToro Wallet Identifier] | External ETL (WalletDB.Wallets) | Tier 4 | WalletID as uniqueidentifier |
| 5 | [Public Wallet Address] | External ETL (WalletDB) | Tier 4 | Blockchain address |
| 6 | [Cryptoasset] | External ETL (WalletDB) | Tier 4 | Crypto name (BTC, ETH, XRP, etc.) |
| 7 | [Opening Balance as of the 1st of Designated Month] | External ETL | Tier 4 | Crypto units at start of month |
| 8 | [Prior Month Closing Balance Date] | External ETL | Tier 4 | Closing date of prior month |
| 9 | [LTD Units Recieved] | External ETL | Tier 4 | Life-to-date received (note DDL typo) |
| 10 | [LTD Units Sent] | External ETL | Tier 4 | Life-to-date sent |
| 11 | [Closing Units Balance] | External ETL | Tier 4 | Closing balance in crypto units |
| 12 | [Closing Balance USD] | External ETL | Tier 4 | Closing balance in USD |
| 13 | [Reporting Balance] | External ETL | Tier 4 | Regulatory reporting balance |
| 14 | [Reporting Balance USD] | External ETL | Tier 4 | Reporting balance in USD |
| 15 | [DevReportBalancesTime] | External ETL | Tier 4 | Dev diagnostic timestamp |
| 16 | [DevReportBalance For 'KnownIssueWallets'] | External ETL | Tier 4 | Dev diagnostic balance |
| 17 | [DevReportBalanceUSD For 'KnownIssueWallets'] | External ETL | Tier 4 | Dev diagnostic balance USD |
| 18 | [ Closing Balance Date] | External ETL | Tier 4 | Closing date (leading space in col name) |
| 19 | [Country] | External ETL | Tier 4 | Customer country |
| 20 | [Regulation] | External ETL | Tier 4 | Customer regulatory jurisdiction |
| 21 | [Test accounting classifier] | External ETL | Tier 4 | Accounting test flag |
| 22 | [MTD Units Sent] | External ETL | Tier 4 | Month-to-date sent |
| 23 | [MTD Units Recieved] | External ETL | Tier 4 | Month-to-date received (DDL typo) |
| 24 | [MTD Units Total] | External ETL | Tier 4 | MTD net units |
| 25 | [MTD Balance Change] | External ETL | Tier 4 | MTD balance change in units |
| 26 | [MTD Balance Change -MTD Units Total Flag] | External ETL | Tier 4 | Flag comparing MTD balance change vs MTD units total |
| 27 | [MTD Balance Change -MTD Units Total] | External ETL | Tier 4 | Numeric difference |
| 28 | [Gap in USD -Estimation] | External ETL | Tier 4 | USD gap/discrepancy estimate |
| 29 | [TrackerBalance] | External ETL (WalletBalancesReportDB?) | Tier 4 | Third-party tracker balance |
| 30 | [TrackerBalanceUSD] | External ETL | Tier 4 | Tracker balance in USD |
| 31 | [Has Dif with TrackerBalance] | External ETL | Tier 4 | Y/N flag |
| 32 | [Dif with TrackerBalance] | External ETL | Tier 4 | Numeric difference |
| 33 | [KnownIssueWallet] | External ETL | Tier 4 | 0/1 flag; NOT NULL |
| 34 | [Most Recent Occured Date] | External ETL (WalletDB) | Tier 4 | Latest transaction date |
| 35 | [UserWalletAllowance] | External ETL (EXW_UserSettingsWalletAllowance) | Tier 4 | Allowed/NotAllowed status |
| 36 | [Closed Country AND Regulation] | External ETL | Tier 4 | Y/N; NOT NULL |
| 37 | [User was Compensated during Country Closure] | External ETL | Tier 4 | Y/N; NOT NULL |
| 38 | [Staking Units] | External ETL | Tier 4 | Staked crypto units |
| 39 | [Staking USD] | External ETL | Tier 4 | Staked crypto in USD |
| 40 | [UpdateDate] | External ETL | Tier 4 | ETL load timestamp |

## Notes

- 0 rows as of 2026-04-20 — table is an empty schema shell
- No SSDT SP found. EXW_EOMReportingBalances (same structure + 4 extra cols) had data through 2023-09-30
- All columns Tier 4 — no upstream production wiki available, no SP code to trace
