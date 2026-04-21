# EXW_dbo.EXW_UserCalculatedBalance — Column Lineage

**Object Type**: Table
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## Table Definition Summary

**DEPRECATED** — historical daily calculated balance per GCID×CryptoId×WalletId, frozen at 2023-12-31. SP_EXW_UserCalculatedBalance(@d date) exists but its entire body is commented out (NO-OP). Data was last written 2024-01-01. Table retains 1.27 billion rows covering 489,107 GCIDs across 1,462 dates (2019-12-31 to 2023-12-31).

The commented-out SP code is the canonical lineage reference. Balance = ReceivedAmount - SentAmount - XRP_reserve (0.0225 for CryptoId=4 only). Superseded by EXW_FinanceReportsBalancesNew (direct snapshot) and EXW_30DayBalanceExtract (rolling 30-day window).

HASH(GCID), CLUSTERED COLUMNSTORE INDEX.

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Confidence |
|---|--------|---------------|---------------|-----------|------------|
| 1 | GCID | EXW_dbo.EXW_DimUser | GCID | Via #wallets JOIN on CustomerWalletsView | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 2 | RealCID | EXW_dbo.EXW_DimUser | RealCID | Direct passthrough via #snap | Tier 1 — Customer.CustomerStatic |
| 3 | WalletId | EXW_Wallet.CustomerWalletsView | Id | JOIN on GCID | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 4 | CryptoId | EXW_Wallet.CustomerWalletsView | CryptoId | Direct passthrough | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 5 | CryptoName | EXW_Wallet.CryptoTypes | Name | JOIN on CryptoID | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 6 | SentAmount | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=1) | ROUND(SUM(Amount + EtoroFees + RelevantBlockchainFee), 8, 1) | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 7 | RecivedAmount | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=2) | ROUND(SUM(Amount), 8, 1) for all received transactions up to BalanceDate | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 8 | Balance | (computed) | — | RecivedAmount - SentAmount - (CASE WHEN CryptoId=4 THEN 0.0225 ELSE 0 END) | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 9 | BalanceUSD | (computed) | — | Balance × EXW_Wallet.EXW_PriceDaily.AvgPrice for CryptoId on BalanceDateId | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 10 | EtoroFees | EXW_dbo.External_WalletDB_Wallet_TransactionsView | EtoroFees (sent) | SUM(EtoroFees) for sent transactions up to BalanceDate | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 11 | BlockchainFee | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee (sent) | SUM(BlockchainFee) for sent transactions | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 12 | RelevantBlockchainFee | EXW_dbo.External_WalletDB_Wallet_TransactionsView | BlockchainFee (IsEtoroHandlingFee=0, sent) | SUM(BlockchainFee WHERE IsEtoroHandlingFee=0) — user-borne fee only | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 13 | LastRecivedOccurred | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Occurred (ActionTypeId=2) | MAX(Occurred) for all received transactions up to BalanceDate | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 14 | LastSentOccurred | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Occurred (ActionTypeId=1) | MAX(Occurred) for all sent transactions up to BalanceDate | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 15 | BalanceDate | (SP parameter) | — | @d — the balance snapshot date | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 16 | BalanceDateId | (SP parameter) | — | @d_i — YYYYMMDD integer of @d | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 17 | RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Via date-range snapshot JOIN on @d | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 18 | CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Via date-range snapshot JOIN on @d | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 19 | IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | Direct passthrough from #snap | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 20 | Country | DWH_dbo.Dim_Country | Name | JOIN on Fact_SnapshotCustomer.CountryID | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 21 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on Fact_SnapshotCustomer.RegulationID | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 22 | EOM | (computed) | — | CASE WHEN @d=last day of month THEN '1' ELSE '0' END — end-of-month flag | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 23 | UpdateDate | (computed) | — | GETDATE() at SP run time | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 24 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Direct passthrough from date-range snapshot | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 25 | VerificationLevelID | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | Direct passthrough from date-range snapshot | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 26 | PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Direct passthrough from date-range snapshot | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |
| 27 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID | Tier 2 — SP_EXW_UserCalculatedBalance (commented) |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.EXW_DimUser | Primary user scope | GCID, RealCID, IsTestAccount |
| EXW_Wallet.CustomerWalletsView | JOIN on GCID | WalletId, CryptoId scoping |
| DWH_dbo.Fact_SnapshotCustomer | JOIN on RealCID + date range | Country, Regulation, IsValidCustomer, VerificationLevelID, PlayerLevelID at BalanceDate |
| DWH_dbo.Dim_Range | JOIN on DateRangeID | Date-range resolution for snapshot |
| DWH_dbo.Dim_Date | JOIN on DateKey=@d_i | Date lookup |
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | All transactions up to BalanceDate | Sent/Received aggregations for balance computation |
| EXW_Wallet.CryptoTypes | LEFT JOIN on CryptoId | Crypto name |
| EXW_Wallet.EXW_PriceDaily | LEFT JOIN on CryptoId+DateKey | USD price at BalanceDate |
| DWH_dbo.Dim_Country | LEFT JOIN on CountryID | Country name |
| DWH_dbo.Dim_Regulation | LEFT JOIN on RegulationID | Regulation name |
| DWH_dbo.Dim_PlayerLevel | LEFT JOIN on PlayerLevelID | Club (player level name) |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this table. Documentation is for knowledge purposes only.
