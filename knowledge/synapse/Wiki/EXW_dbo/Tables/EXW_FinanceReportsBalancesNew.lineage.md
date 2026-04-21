---
object: EXW_dbo.EXW_FinanceReportsBalancesNew
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_FinanceReportsBalancesNew

## ETL Chain

```
WalletBalancesReportDB.Wallet.FinanceReportRecords (source — wallet reconciliation records)
  + EXW_Wallet.CustomerWalletsView (scope filter — active wallet users, Gcid > 0)
  + DWH_dbo.Fact_SnapshotCustomer (user attributes — RealCID, RegulationID, CountryID, etc.)
  + EXW_dbo.EXW_DimUser (IsTestAccount flag)
  + EXW_dbo.EXW_UserSettingsWalletAllowance (UserWalletAllowance, SelectedValue)
  + EXW_Wallet.EXW_PriceDaily (daily avg crypto-to-USD price)
  + EXW_Wallet.CryptoTypes (CryptoName lookup)
  + DWH_dbo.Dim_Regulation (Regulation name lookup)
  + DWH_dbo.Dim_Country (Country name lookup)
  + DWH_dbo.Dim_PlayerLevel (Club name lookup)
  + DWH_dbo.Dim_PlayerStatus (PlayerStatus name lookup)
  + EXW_dbo.EXW_CompensationClosingCountries (AML compensation check)
  + EXW_dbo.EXW_WalletEntity (WalletEntity lookup by GCID + DateID)
  + EXW_Wallet.WalletPool + BI_DB_dbo.External_WalletDB_Wallet_WalletPoolAttributes (XRP Reserved amount)
    |
    | SP_EXW_FinanceReportsBalancesNew @d DATE
    | DELETE by BalanceDateID + INSERT (daily incremental)
    v
EXW_dbo.EXW_FinanceReportsBalancesNew
    |
    | consumed by:
    +-- SP_EXW_DimUser_Enriched → EXW_DimUser_Enriched.TotalBalanceUSD
    +-- SP_EXW_30DayBalanceExtract → EXW_30DayBalanceExtract
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | GCID | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | Gcid | Passthrough via FinanceReportRecords; scope filtered by CustomerWalletsView (Gcid > 0) |
| 2 | RealCID | T1 | Customer.CustomerStatic (via DWH_dbo.Fact_SnapshotCustomer relay) | CID | Passthrough — same attribute as Customer.CustomerStatic.CID, relayed via Fact_SnapshotCustomer JOIN on GCID |
| 3 | WalletID | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | WalletId | Passthrough |
| 4 | PublicAddress | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | Address | Renamed: Address → PublicAddress |
| 5 | CryptoID | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | CryptoId | Passthrough |
| 6 | CryptoName | T2 | EXW_Wallet.CryptoTypes | Name | Lookup by CryptoID |
| 7 | BalanceDate | T2 | SP parameter | @d | Date input parameter |
| 8 | BalanceDateID | T2 | ETL-computed | — | CAST(CONVERT(VARCHAR(8), @d, 112) AS INT) — YYYYMMDD int |
| 9 | Price_Date | T2 | EXW_Wallet.EXW_PriceDaily | FullDate | Latest available price date for CryptoID |
| 10 | Rate | T2 | EXW_Wallet.EXW_PriceDaily | AvgPrice | Daily average crypto-to-USD price |
| 11 | ReportID | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | ReportId | Passthrough — identifies the reconciliation run |
| 12 | TotalReceive | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | TotalReceive | Passthrough |
| 13 | TotalSend | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | TotalSend | Passthrough |
| 14 | WalletDBBalance | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | BloxBalance | Renamed: BloxBalance → WalletDBBalance |
| 15 | ComputedAmount | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | ComputedAmount | Passthrough |
| 16 | ProviderValue | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | BitgoValue | Renamed: BitgoValue → ProviderValue |
| 17 | WalletTrackerValue | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | BloxValue | Renamed: BloxValue → WalletTrackerValue |
| 18 | LevelId | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | LevelId | Passthrough |
| 19 | ReportOccurred | T1 | WalletBalancesReportDB.Wallet.FinanceReportRecords | Created (aliased as Occurred) | Renamed: Created → ReportOccurred |
| 20 | Balance | T2 | ETL-computed | LevelId, WalletDBBalance, ProviderValue, WalletTrackerValue | CASE: NULL → WalletDBBalance; LevelId IS NOT NULL AND BitgoValue NULL AND BloxValue NOT NULL → BloxValue; LevelId IS NOT NULL AND both NULL → WalletDBBalance; ELSE → BitgoValue |
| 21 | BalanceUSD | T2 | ETL-computed | Balance, Rate | Balance × EXW_PriceDaily.AvgPrice |
| 22 | RegulationID | T2 | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Passthrough via snapshot JOIN |
| 23 | Regulation | T2 | DWH_dbo.Dim_Regulation | Name | Lookup by RegulationID (DWHRegulationID) |
| 24 | CountryID | T2 | DWH_dbo.Fact_SnapshotCustomer | CountryID | Passthrough via snapshot JOIN |
| 25 | Country | T2 | DWH_dbo.Dim_Country | Name | Lookup by CountryID |
| 26 | IsTestAccount | T2 | EXW_dbo.EXW_DimUser | IsTestAccount | LEFT JOIN on GCID |
| 27 | IsValidCustomer | T2 | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough via snapshot JOIN |
| 28 | VerificationLevelID | T2 | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | Passthrough via snapshot JOIN |
| 29 | PlayerLevelID | T2 | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Passthrough via snapshot JOIN |
| 30 | Club | T2 | DWH_dbo.Dim_PlayerLevel | Name | Lookup by PlayerLevelID |
| 31 | ComplianceClosureEvent | T2 | ETL-computed | — | Hardcoded to 0 in SP (column reserved but not populated) |
| 32 | AMLClosureEvent | T2 | ETL-computed | PlayerStatusID, SelectedValue, TotalBalance, EXW_CompensationClosingCountries | 4-condition CASE: blocked+not-allowed / not-allowed+zero-balance / not-allowed+zero-USD / compensated+not-allowed |
| 33 | UserWalletAllowance | T2 | EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance | LEFT JOIN on GCID |
| 34 | UpdateDate | T2 | ETL-computed | — | GETDATE() at insert time |
| 35 | WalletEntity | T2 | EXW_dbo.EXW_WalletEntity | WalletEntity | LEFT JOIN on GCID + BalanceDateID |
| 36 | PlayerStatus | T2 | DWH_dbo.Dim_PlayerStatus | Name | Lookup by PlayerStatusID |
| 37 | Reserved | T2 | EXW_Wallet.WalletPool + BI_DB_dbo.External_WalletDB_Wallet_WalletPoolAttributes | ReservedAmount | XRP wallets only: LEFT JOIN on WalletId; ISNULL(ReservedAmount, 0) |

## Tier Summary

- **Tier 1**: 14 columns (GCID, RealCID, WalletID, PublicAddress, CryptoID, ReportID, TotalReceive, TotalSend, WalletDBBalance, ComputedAmount, ProviderValue, WalletTrackerValue, LevelId, ReportOccurred) — passthrough/renamed from WalletBalancesReportDB.Wallet.FinanceReportRecords (13) + RealCID from Customer.CustomerStatic via Fact_SnapshotCustomer relay
- **Tier 2**: 23 columns — ETL-computed, lookup-enriched, or sourced from non-wiki sources
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_FinanceReportsBalancesNew
- **UC Target**: `_Not_Migrated` (no UC mapping found — finance reconciliation snapshot, Synapse-only)
