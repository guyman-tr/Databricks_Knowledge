# EXW_dbo.Hourly_RedeemActivity — Column Lineage

**Object**: EXW_dbo.Hourly_RedeemActivity  
**Type**: Table  
**Generated**: 2026-04-20  
**ETL Writer**: EXW_dbo.SP_EXW_Hourly (TRUNCATE + INSERT, runs hourly, 7-day rolling window)  
**Primary Source**: EXW_dbo.External_WalletDB_Wallet_TransactionsView → #tx (temp copy, SELECT *)  
**Scope**: Sent redemption transactions only (TransactionTypeId = 0); aggregated per CryptoID × calendar date

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Date | WalletDB.Wallet.TransactionsView (via External_WalletDB_Wallet_TransactionsView → #tx) | TransDate | CAST(TransDate AS DATE) — aggregation key (GROUP BY). Redeem transactions only (TransactionTypeId=0). | Tier 2 |
| 2 | CryptoID | EXW_Wallet.CryptoTypes | CryptoID | INNER JOIN CryptoTypes ON tv.CryptoId = ct.CryptoID → ct.CryptoID. Aggregation key (GROUP BY). Effectively passes through tv.CryptoId from the transactions view. | Tier 2 |
| 3 | CryptoName | EXW_Wallet.CryptoTypes | Name | INNER JOIN CryptoTypes → ct.Name AS CryptoName. Aggregation key (GROUP BY). Crypto name lookup; not from transactions source. | Tier 2 |
| 4 | TotalRedeemTX | WalletDB.Wallet.TransactionsView (via #tx) | gcid | COUNT(gcid) — count of redemption transactions per CryptoID × Date. Null gcid would be excluded from COUNT; in practice gcid is always populated for sent transactions (Gcid=0 = system). | Tier 2 |
| 5 | TotalRedeemUnits | WalletDB.Wallet.TransactionsView (via #tx) | Amount | SUM(Amount) — total native-unit redemption volume per CryptoID × Date. Amount upstream: "Transaction amount in native crypto units." | Tier 2 |
| 6 | ReportDate | ETL | n/a | CAST(GETDATE() AS DATE) — the SP run date. Same for all rows in a given run. | Tier 2 |
| 7 | UpdateDate | ETL | n/a | GETDATE() at INSERT time. Records the specific hourly run that wrote this row. | Tier 2 |
| 8 | USDValue | EXW_Wallet.EXW_Price (via #DailyPrices) | AvgPrice | SUM(Amount) × dp.AvgPrice — total USD redemption value. AvgPrice is in the GROUP BY clause (daily average price per CryptoID × Date from #DailyPrices). No NULL USDValue rows in practice (all active redeem cryptos have price mappings). | Tier 2 |

---

## Source Objects

| Source Object | Access Method | Role |
|--------------|---------------|------|
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | SELECT * → #tx temp table (HASH(gcid), HEAP) | Primary source: all wallet transactions. Filtered to TransactionTypeId=0, TransDate >= last 7 days. |
| EXW_Wallet.CryptoTypes | INNER JOIN ON tv.CryptoId = ct.CryptoID | CryptoName lookup and CryptoID passthrough |
| EXW_Wallet.EXW_Price (via #DailyPrices) | LEFT JOIN ON CryptoID + CAST(TransDate AS DATE) = FullDate | Daily avg USD price for USDValue computation. One price per CryptoID per Date. |

---

## ETL Pipeline

```
WalletDB.Wallet.SentTransactions (production — blockchain redemption records)
  |-- Wallet.TransactionsView (unified tx view, types 0/5/6/7/8/9 + received) --|
  v
CopyFromLake.WalletDB_Wallet_TransactionsView
  (Bronze External Table — Parquet from ADLS)
  |-- EXW_dbo.External_WalletDB_Wallet_TransactionsView (view wrapper) --|
  |-- SP_EXW_Hourly: SELECT * → #tx (HASH(gcid), HEAP) --|
  |-- WHERE TransactionTypeId = 0 AND TransDate >= DATEDIFF(DAY, 7, GETDATE()) --|
  |-- GROUP BY CAST(TransDate AS DATE), CryptoID, CryptoName, dp.AvgPrice --|
  v
EXW_dbo.Hourly_RedeemActivity
  (79 rows, 17 cryptos, 8 dates, 7-day rolling window, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (all columns are aggregated or lookup-enriched; no direct passthrough) |
| Tier 2 | 8 | Date, CryptoID, CryptoName, TotalRedeemTX, TotalRedeemUnits, ReportDate, UpdateDate, USDValue |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

**Upstream wiki consulted**: WalletDB/Wiki/Wallet/Views/Wallet.TransactionsView.md (TransDate, Amount, gcid, TransactionTypeId definitions)  
**Note**: No T1 columns — Hourly_RedeemActivity is a pure aggregation table; no column is a direct passthrough of an upstream-documented source column.
