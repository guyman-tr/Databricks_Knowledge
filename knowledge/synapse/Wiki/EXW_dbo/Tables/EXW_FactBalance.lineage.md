# EXW_dbo.EXW_FactBalance — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_FactBalance |
| **Writer SP** | EXW_dbo.SP_EXW_FactBalance |
| **ETL Type** | Daily snapshot replace — DELETE WHERE FullDateID = @d_i, then INSERT from WalletDB balance source |
| **Primary Source** | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances (balance snapshot per wallet per date) |
| **Scope Filter** | EXW_Wallet.CustomerWalletsView (Wallet user + crypto scope) |
| **Enrichment Sources** | EXW_Wallet.CryptoTypes (crypto metadata), EXW_Wallet.EXW_PriceDaily (USD price), EXW_dbo.EXW_DimUser (RealCID) |
| **Refresh Pattern** | Daily; FullDate range: 2018-07-12 to 2026-04-11 |
| **Row Count** | 2,372,510,113 |
| **UC Target** | _Not_Migrated (to be verified) |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | FullDate | Computed | — | — | @d parameter (the reporting snapshot date); passed directly into INSERT | Tier 2 — SP_EXW_FactBalance |
| 2 | FullDateID | Computed | — | — | CAST(CONVERT(VARCHAR(8), @d, 112) AS INT); YYYYMMDD integer date key | Tier 2 — SP_EXW_FactBalance |
| 3 | GCID | Passthrough | EXW_Wallet.CustomerWalletsView | Gcid | Direct passthrough; scope filter defining Wallet users; HASH distribution key | Tier 2 — SP_EXW_FactBalance |
| 4 | RealCID | Join-derived | EXW_dbo.EXW_DimUser | RealCID | LEFT JOIN on F.Gcid = DU.GCID; unqualified [RealCID] resolves to DU.RealCID; NULL when GCID not in EXW_DimUser | Tier 1 — Customer.CustomerStatic (via EXW_DimUser) |
| 5 | CryptoId | Passthrough | EXW_Wallet.CustomerWalletsView | CryptoId | Direct passthrough; FK to CryptoTypes | Tier 2 — SP_EXW_FactBalance |
| 6 | CryptoName | Join-derived | EXW_Wallet.CryptoTypes | Name | JOIN on CW.CryptoId = CT.CryptoID; denormalized crypto asset name | Tier 2 — SP_EXW_FactBalance |
| 7 | InstrumentID | Join-derived | EXW_Wallet.CryptoTypes | InstrumentId | JOIN on CW.CryptoId = CT.CryptoID; FK to DWH instrument dimension; NULL for cryptos without instrument mapping | Tier 2 — SP_EXW_FactBalance |
| 8 | WalletID | Passthrough | EXW_Wallet.CustomerWalletsView | Id | Aliased as WalletID; unique wallet identifier (uniqueidentifier) | Tier 2 — SP_EXW_FactBalance |
| 9 | Balance | Computed | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Balance | ISNULL(Balance, 0); native crypto unit balance as of FullDate; 0 when no balance record for wallet+date | Tier 2 — SP_EXW_FactBalance |
| 10 | BalanceUSD | Computed | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances + EXW_Wallet.EXW_PriceDaily | Balance, AvgPrice | ISNULL(Balance * AvgPrice, 0); USD equivalent; zero when no price found (LEFT JOIN on FullDate + InstrumentID/CryptoId) | Tier 2 — SP_EXW_FactBalance |
| 11 | UpdateDate | Computed | — | — | GETDATE() at INSERT | Tier 2 — SP_EXW_FactBalance |
| 12 | BlockchainCryptoId | Join-derived | EXW_Wallet.CryptoTypes | BlockchainCryptoId | JOIN on CT.BlockchainCryptoId = CT1.CryptoID; parent blockchain crypto ID | Tier 2 — SP_EXW_FactBalance |
| 13 | BlockchainCryptoName | Join-derived | EXW_Wallet.CryptoTypes | Name (blockchain alias) | Self-join on BlockchainCryptoId; parent blockchain name (e.g., ETH, LTC, BTC) | Tier 2 — SP_EXW_FactBalance |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Balance snapshot — WalletBalances view scoped to DateFrom/DateTo range | Primary balance source |
| EXW_Wallet.CustomerWalletsView | Wallet user + crypto scope driver | Filter/scope |
| EXW_Wallet.CryptoTypes | Crypto asset metadata (name, instrument, blockchain) | JOIN (CryptoId) |
| EXW_Wallet.EXW_PriceDaily | Daily crypto price in USD | LEFT JOIN (FullDate + InstrumentID) |
| EXW_dbo.EXW_DimUser | Wallet user dimension | LEFT JOIN for RealCID |

## Consumers (Downstream)

| Object | Usage |
|--------|-------|
| eMoney_dbo.SP_EXW_FactBalance_EXT | Cross-schema balance extension reporting (eMoney regulatory scope) |
