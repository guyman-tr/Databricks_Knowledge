# EXW_dbo.Hourly_OmnibusBalances — Column Lineage

**Object**: EXW_dbo.Hourly_OmnibusBalances  
**Type**: Table  
**Generated**: 2026-04-20  
**ETL Writer**: EXW_dbo.SP_EXW_Hourly (TRUNCATE + INSERT, runs hourly, @d DATE param not used — all dates from GETDATE())  
**Primary Source**: CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances (Bronze External Table from WalletDB.Wallet.V_BI_WalletBalances)  
**Scope**: Omnibus / system wallets only (Gcid <= 0 from EXW_Wallet.CustomerWalletsView)

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | ReportDate | ETL | n/a | CAST(GETDATE() AS DATE) — the SP run date | Tier 2 |
| 2 | WalletID | WalletDB.Wallet.V_BI_WalletBalances | WalletId | Passthrough (nvarchar(max) in EXW vs uniqueidentifier in source — Parquet serialization). Deduped per WalletId×CryptoId by ROW_NUMBER(DateFrom DESC)=1. Scoped to Gcid<=0 wallets. | Tier 1 |
| 3 | CryptoID | WalletDB.Wallet.V_BI_WalletBalances | CryptoId | Passthrough | Tier 1 |
| 4 | InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | JOIN CryptoTypes ON CryptoId → InstrumentId | Tier 2 |
| 5 | Balance | WalletDB.Wallet.V_BI_WalletBalances | Balance | Passthrough (latest snapshot per WalletId×CryptoId, DateFrom DESC) | Tier 1 |
| 6 | WalletType | EXW_Wallet.CryptoTypes + CopyFromLake.WalletDB_Dictionary_WalletTypes | BlockchainCryptoId, CryptoID, Name | CASE WHEN ct.BlockchainCryptoId <> ct.CryptoID THEN 'Conversion' ELSE iwt.Name END. ERC-20 tokens → 'Conversion'; native coins → WalletTypes.Name | Tier 2 |
| 7 | BalanceDate | ETL | n/a | CAST(GETDATE()-N AS DATE) for N in {0,1,2,3} — 4-day rolling window balance-as-of date | Tier 2 |
| 8 | UpdateDate | ETL | n/a | GETDATE() at INSERT time | Tier 2 |
| 9 | USDBalance | EXW_Wallet.EXW_Price (via #DailyPrices) | AvgPrice | Balance × DailyPrices.AvgPrice (daily avg price at BalanceDate). NULL for cryptos with no price mapping. | Tier 2 |

---

## Source Objects

| Source Object | Access Method | Role |
|--------------|---------------|------|
| CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Bronze External Table | Primary balance data source (WalletId, CryptoId, DateFrom, DateTo, Balance) |
| EXW_Wallet.CustomerWalletsView | INNER JOIN (WHERE Gcid <= 0) | Omnibus wallet filter — only system wallets (Gcid<=0) |
| CopyFromLake.WalletDB_Dictionary_WalletTypes | INNER JOIN via iw.WalletTypeId | WalletType name resolution (Redeem, Payment, Funding, C2F, StakingRefund) |
| EXW_Wallet.CryptoTypes | INNER JOIN ON CryptoId | InstrumentId and BlockchainCryptoId lookup (determines 'Conversion' type) |
| EXW_Wallet.EXW_Price (via #DailyPrices) | LEFT JOIN ON CryptoId + FullDate | Daily USD price for USDBalance computation |

---

## ETL Pipeline

```
WalletDB.Wallet.WalletBalances (production)
  |-- V_BI_WalletBalances (rolling 20-day view, WalletDB) --|
  v
CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances
  (Bronze External Table — Parquet from ADLS, Generic Pipeline Override ~60min)
  |-- SP_EXW_Hourly (hourly TRUNCATE + INSERT, Gcid<=0 filter) --|
  v
EXW_dbo.Hourly_OmnibusBalances
  (404 rows, 4-day rolling window, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 3 | WalletID, CryptoID, Balance |
| Tier 2 | 6 | ReportDate, InstrumentID, WalletType, BalanceDate, UpdateDate, USDBalance |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

**Upstream wiki**: CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.V_BI_WalletBalances.md
