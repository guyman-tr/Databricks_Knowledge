# EXW_dbo.Hourly_CustomerBalances — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_EXW_Hourly | **Load Pattern**: TRUNCATE + INSERT (runs hourly; @d DATE param unused in balance section — GETDATE() used throughout)

## ETL Pipeline

```
CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances (live balance SCD from WalletDB)
  + EXW_Wallet.CryptoTypes (CryptoId → CryptoName mapping)
  + EXW_Wallet.CustomerWalletsView (wallet owner GCID; filter Gcid > 0 = customer wallets only)
  + EXW_Wallet.EXW_Price + EXW_Currency.vInstrumentRatesForWeek (daily price for USDBalance)
    |
    | SP_EXW_Hourly (@d DATE — not used; GETDATE() governs all dates)
    | ROW_NUMBER OVER (WalletId, CryptoId ORDER BY DateFrom DESC) = 1 (dedup per wallet-crypto)
    | Balance <> 0 filter (for today, today-1, today-3; today-2 has no filter)
    | SUM(Balance) per CryptoId per snapshot date (UNION ALL 4 date offsets)
    | TRUNCATE + INSERT ---|
    v
EXW_dbo.Hourly_CustomerBalances (N rows per run ≈ 4 snapshots × active cryptos)
  |-- (no documented consumer) ---|
  v
_Not_Migrated

Note: Same SP run also rebuilds Hourly_OmnibusBalances, Hourly_RedeemActivity,
Hourly_WalletInventory, Hourly_WalletAllocations, and Hourly_Transactions.
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| ReportDate | GETDATE() | — | CAST(GETDATE() AS DATE) — the date this SP run executed | Tier 2 — SP_EXW_Hourly |
| CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough (via WalletDB_Wallet_V_BI_WalletBalances JOIN CryptoTypes) | Tier 2 — SP_EXW_Hourly |
| CryptoName | EXW_Wallet.CryptoTypes | Name | Passthrough | Tier 2 — SP_EXW_Hourly |
| UnitBalance | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Balance | SUM(Balance) per CryptoId per snapshot date; Balance <> 0 filter (except today-2) | Tier 2 — SP_EXW_Hourly |
| BalanceDate | GETDATE() | — | Computed: CAST(GETDATE() AS DATE), GETDATE()-1, GETDATE()-2, GETDATE()-3 — one row per day offset | Tier 2 — SP_EXW_Hourly |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_EXW_Hourly |
| USDBalance | EXW_Wallet.EXW_Price + EXW_Currency.vInstrumentRatesForWeek | AvgPrice | UnitBalance × AvgPrice from #DailyPrices (daily price for BalanceDate) | Tier 2 — SP_EXW_Hourly |

## Source Objects

| Object | Role |
|---|---|
| CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Source of balance snapshots (DateFrom/DateTo SCD; customer wallets only Gcid>0) |
| EXW_Wallet.CryptoTypes | Lookup for CryptoName from CryptoID |
| EXW_Wallet.CustomerWalletsView | Filter: Gcid > 0 = customer wallets; excludes 6 hardcoded BlockchainProviderWalletId hot wallets |
| EXW_Wallet.EXW_Price | Source of daily AvgPrice for USDBalance (most recent price per CryptoID per date) |
| EXW_Currency.vInstrumentRatesForWeek | Source of today and yesterday hourly rates (used to build #DailyPrices) |
| EXW_dbo.SP_EXW_Hourly | Writer SP — hourly runner; same run writes 5 other Hourly_* tables |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 2 | 7 | All columns — SP-derived aggregations; no upstream wiki for WalletDB balance source |
