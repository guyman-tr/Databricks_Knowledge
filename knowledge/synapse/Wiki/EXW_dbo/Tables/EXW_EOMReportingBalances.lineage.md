---
object: EXW_dbo.EXW_EOMReportingBalances
type: Table
writer_sp: None found in SSDT — external ETL (Python/ADF or equivalent)
upstream_source: Unknown external ETL — likely WalletBalancesReportDB + WalletDB + eToro CRM
lineage_generated: 2026-04-20
---

# Column Lineage — EXW_dbo.EXW_EOMReportingBalances

## ETL Chain

```
[External ETL — Python/ADF, not in SSDT repo]
  Sources: WalletDB + WalletBalancesReportDB + eToro CRM (inferred)
  |-- Monthly end-of-month batch ---|
  v
EXW_dbo.EXW_EOMReportingBalances (25.4M rows, 2021-11-30 to 2023-09-30)
  |-- UC Target: _Not_Migrated ---|
  Last updated: 2023-10-15 (decommissioned after Sep-2023)
```

## Column Lineage

| # | DWH Column | Source | Tier | Notes |
|---|-----------|--------|------|-------|
| 1 | ReportingDate | External ETL | Tier 4 | EOM date (last day of month); NULL in DDL |
| 2 | ReportingDateID | External ETL | Tier 4 | YYYYMMDD int from ReportingDate |
| 3 | [eToro Unique ID 1 GCID] | External ETL (WalletDB) | Tier 4 | GCID; HASH key; NOT NULL |
| 4 | [eToro Unique ID 2 CID] | External ETL (eToro platform) | Tier 4 | CID; NOT NULL |
| 5 | [eToro Wallet Identifier] | External ETL (WalletDB.Wallets) | Tier 4 | UUID; NOT NULL |
| 6 | [Public Wallet Address] | External ETL (WalletDB) | Tier 4 | Blockchain address; nvarchar(max) |
| 7 | [Cryptoasset] | External ETL | Tier 4 | Crypto name |
| 8 | [Opening Balance as of the 1st of Designated Month] | External ETL | Tier 4 | Prior month closing = this month opening |
| 9 | [Prior Month Closing Balance Date] | External ETL | Tier 4 | Datetime of prior closing |
| 10 | [LTD Units Recieved] | External ETL | Tier 4 | Life-to-date received (DDL typo) |
| 11 | [LTD Units Sent] | External ETL | Tier 4 | Life-to-date sent |
| 12 | [Closing Units Balance] | External ETL | Tier 4 | Month-end balance in crypto units |
| 13 | [Closing Balance USD] | External ETL | Tier 4 | Month-end balance in USD |
| 14 | [Reporting Balance] | External ETL | Tier 4 | Regulatory balance (may differ from Closing for known-issue wallets) |
| 15 | [Reporting Balance USD] | External ETL | Tier 4 | Reporting balance in USD |
| 16 | [DevReportBalancesTime] | External ETL | Tier 4 | Dev diagnostic timestamp |
| 17 | [DevReportBalance For 'KnownIssueWallets'] | External ETL | Tier 4 | Corrected balance for known-issue wallets |
| 18 | [DevReportBalanceUSD For 'KnownIssueWallets'] | External ETL | Tier 4 | Corrected balance USD |
| 19 | [ Closing Balance Date] | External ETL | Tier 4 | Closing date (leading space in col name) |
| 20 | [Country] | External ETL (eToro CRM) | Tier 4 | Customer country |
| 21 | [Regulation] | External ETL (eToro CRM) | Tier 4 | Regulatory jurisdiction |
| 22 | [Test accounting classifier] | External ETL | Tier 4 | 0=production, non-zero=test |
| 23 | [MTD Units Sent] | External ETL | Tier 4 | Month-to-date sent |
| 24 | [MTD Units Recieved] | External ETL | Tier 4 | Month-to-date received (DDL typo) |
| 25 | [MTD Units Total] | External ETL | Tier 4 | MTD net units |
| 26 | [MTD Balance Change] | External ETL | Tier 4 | Closing minus Opening balance |
| 27 | [MTD Balance Change -MTD Units Total Flag] | External ETL | Tier 4 | 'Y'/'N'; NOT NULL |
| 28 | [MTD Balance Change -MTD Units Total] | External ETL | Tier 4 | Numeric gap |
| 29 | [Gap in USD -Estimation] | External ETL | Tier 4 | Reporting vs tracker gap in USD |
| 30 | [TrackerBalance] | External ETL (BitGo/Blox?) | Tier 4 | Third-party tracker balance |
| 31 | [TrackerBalanceUSD] | External ETL | Tier 4 | Tracker balance in USD |
| 32 | [Has Dif with TrackerBalance] | External ETL | Tier 4 | 'Y'/'N'; NOT NULL |
| 33 | [Dif with TrackerBalance] | External ETL | Tier 4 | Closing minus TrackerBalance |
| 34 | [KnownIssueWallet] | External ETL | Tier 4 | 0/1 flag; NULL in DDL |
| 35 | [Most Recent Occured Date] | External ETL (WalletDB) | Tier 4 | Latest transaction datetime |
| 36 | [UserWalletAllowance] | External ETL (EXW_UserSettingsWalletAllowance) | Tier 4 | Allowed/NotAllowed |
| 37 | [Closed Country AND Regulation] | External ETL | Tier 4 | 'Y'/'No' flag |
| 38 | [User was Compensated during Country Closure] | External ETL | Tier 4 | 'Y'/'No' flag |
| 39 | [Staking Units] | External ETL (Staking service) | Tier 4 | Staked units |
| 40 | [Staking USD] | External ETL | Tier 4 | Staked USD |
| 41 | [UpdateDate] | External ETL | Tier 4 | ETL run timestamp; NOT NULL |
| 42 | [IsValidCustomer] | External ETL (eToro CRM) | Tier 4 | Customer validity flag |
| 43 | [VerificationLevelID] | External ETL (eToro CRM) | Tier 4 | KYC verification tier |
| 44 | [PlayerLevelID] | External ETL (eToro CRM) | Tier 4 | Club tier ID |

## Notes

- 25.4M rows, 2021-11-30 to 2023-09-30 (23 monthly snapshots); decommissioned
- No SSDT SP — external ETL pipeline only
- All 44 columns Tier 4 — no SP code to trace, no upstream production wiki available
- EXW_ReportingBalances is the successor schema (40 cols, empty, without cols 2/42/43/44)
