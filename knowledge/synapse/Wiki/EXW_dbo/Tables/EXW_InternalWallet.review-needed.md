# EXW_dbo.EXW_InternalWallet — Review Needed

**Generated**: 2026-04-20 | **Batch**: 8 | **Object**: #6 of 6

## Tier 2 Items (Require Confirmation — SP Found)

| # | Column | Question | Current Assumption |
|---|--------|----------|-------------------|
| RN-001 | UpdateDate | Column name is "UpdateDate" but the source is CustomerWalletsView.Occurred (= WalletAssets.Occurred = when the crypto asset was first added to the wallet). Is this the intended meaning, or is it when the SP last refreshed? | Assumed: wallet asset creation timestamp (from Occurred), NOT ETL run time. Rename in SP is misleading. |
| RN-002 | Gcid | What is the significance of Gcid < 0 (negative) vs Gcid = 0? Are there known negative GCID values in this table? | Assumed: Gcid=0 = omnibus/system wallets; Gcid<0 = internal service accounts. Exact negative values not verified. |
| RN-003 | InternalType | LEFT JOIN to WalletDB_Dictionary_WalletTypes — can InternalType ever be NULL for active internal wallets? | Assumed: NULL possible if WalletTypeId not in dictionary; expected non-NULL for all known types (1,2,3,4,6,7) |
| RN-004 | ALL | SP has no scheduling parameter. How often is SP_EXW_InternalWallet triggered? Daily? On-demand? By ADF pipeline? | Assumed: periodic refresh (daily or on-demand); schedule not visible in SSDT |
| RN-005 | ALL | Row count: how many internal wallets exist? CustomerWalletsView has 1.76M rows (all IsActive=1), but Gcid≤0 subset is unknown. | Assumed: tens to hundreds of rows (one per crypto per wallet type, for active internal wallets only) |

## Cross-Object Consistency

- `InternalWalletTypeId = 7` (StakingRefund) + `CryptoId = 2` (ETH): this row's `Address` should match the staking pool address `0xCB2A66540680c344bab5f818d68c3e4B9D57363B` referenced in WalletDB.Staking.StakingTransactions — verify if this address appears in EXW_InternalWallet.
- `CryptoId` distribution: should align with CryptoId values used in EXW_dbo Staking tables (primarily CryptoId=2 for ETH staking).
- `Status` = 0 for all active internal wallets — verify that no internal wallets in this table have Status=5 (pending).

## SP Behavior Notes

- **Author history**: SP changed log shows "synapse migration" (2024-02-21 Ben Einav) and "Dictionary replace" (2024-03-21 Inessa + Guy Manova). The dictionary join (CopyFromLake.WalletDB_Dictionary_WalletTypes) was added in the March change — previously may have hardcoded or computed InternalType differently.
- **No parameters**: SP is parameterless — always refreshes the full table regardless of date. Not idempotent in the sense of replace-by-date; just fully replaces.
- **CCI impact**: TRUNCATE + INSERT into CCI table may rebuild columnstore segments on each run. For a small table (< 1,000 rows), this is negligible.

## T1 Upstream Fidelity Check

| Column | Upstream Description (CustomerWalletsView) | Wiki Description | MATCH? |
|--------|-------------------------------------------|------------------|--------|
| Id | "The wallet's universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system — referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups." | "The wallet's universal business key (from WalletDB.Wallet.Wallets.WalletId via CustomerWalletsView). Referenced by SentTransactions, ReceivedTransactions, Conversions, and all wallet transaction lookups across the WalletDB system." | YES — verbatim base; DWH scope note added |
| Gcid | "Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets." | "Global Customer ID of the internal wallet owner. Always ≤ 0 in this table: Gcid=0 = omnibus/system wallets; Gcid < 0 = internal service account wallets." | YES — verbatim base; WHERE Gcid <= 0 constraint added |
| CryptoId | "The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern." | "The cryptocurrency asset associated with this internal wallet. FK to Wallet.CryptoTypes.CryptoID (174 assets: 12 native coins + 162 ERC-20 tokens). HASH distribution key." | YES — verbatim base; asset count from CryptoTypes wiki added |
| Address | "Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58." | "Blockchain public address of this internal wallet, cast to nvarchar(1000). Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x. For ETH staking (type 7), this is the staking pool address." | YES — verbatim base; CAST and staking pool reference added |
| BlockchainProviderWalletId | "External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider." | "External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the blockchain custody provider for operational wallets." | YES — verbatim base |
| Status | "Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation). Computed in view: CASE WHEN w.IsActivated=1 THEN 0 ELSE 5 END." | "Wallet activation status: 0=Created/Active (wallet fully operational, blockchain address confirmed), 5=Pending activation (awaiting blockchain confirmation). Computed in CustomerWalletsView: CASE WHEN IsActivated=1 THEN 0 ELSE 5 END." | YES — verbatim base |
