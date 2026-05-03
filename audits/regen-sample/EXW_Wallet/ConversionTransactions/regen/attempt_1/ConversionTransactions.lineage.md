# EXW_Wallet.ConversionTransactions — Column Lineage

> Generated: 2026-04-30 | Phase 10B | Source: WalletDB.Wallet.ConversionTransactions

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source DB** | WalletDB |
| **Primary Source Table** | Wallet.ConversionTransactions |
| **Writer SP** | None (Generic Pipeline Bronze landing) |
| **Generic Pipeline ID** | 656 |
| **Copy Strategy** | Append |
| **Frequency** | Daily (1440 min) |
| **Data Range** | 2018-10-28 to 2023-06-14 (likely dormant) |

## Load Pattern

No dedicated writer SP exists. Data is loaded via Generic Pipeline #656 from WalletDB.Wallet.ConversionTransactions using daily Append strategy in parquet format. The last recorded transaction is from 2023-06-14, suggesting the table is dormant.

## ETL Pipeline

```
WalletDB.Wallet.ConversionTransactions (production, WalletDB server)
  |-- Generic Pipeline #656 (Bronze, Append, daily/1440 min, parquet) --|
  v
EXW_Wallet.ConversionTransactions (98,713 rows, HASH(ConversionId), HEAP)
  |-- Generic Pipeline (Bronze export) --|
  v
wallet.bronze_walletdb_wallet_conversiontransactions (UC Bronze)
```

## Source Objects

| # | Source Object | Source Type | Relationship |
|---|-------------|------------|--------------|
| 1 | WalletDB.Wallet.ConversionTransactions | Production table | Primary source via Generic Pipeline |
| 2 | EXW_Wallet.Conversions | Sibling Synapse table | Parent conversion record (ConversionId = Conversions.Id) |
| 3 | EXW_Wallet.EXW_TransactionsView | Synapse view | Consumer — joins via Conversions.CorrelationId for conversion_in/out CTEs |
| 4 | EXW_dbo.EXW_FactConversions | Downstream Synapse table | Consumes per-leg amounts, fees, addresses |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Id | Wallet.ConversionTransactions | Id | Passthrough | Tier 3 |
| 2 | ConversionId | Wallet.ConversionTransactions | ConversionId | Passthrough | Tier 3 |
| 3 | WalletId | Wallet.ConversionTransactions | WalletId | Passthrough | Tier 3 |
| 4 | CryptoRateUsd | Wallet.ConversionTransactions | CryptoRateUsd | Passthrough | Tier 3 |
| 5 | ToAddress | Wallet.ConversionTransactions | ToAddress | Passthrough | Tier 3 |
| 6 | Amount | Wallet.ConversionTransactions | Amount | Passthrough | Tier 3 |
| 7 | EtoroFeePercentage | Wallet.ConversionTransactions | EtoroFeePercentage | Passthrough | Tier 3 |
| 8 | EtoroFeeCalculated | Wallet.ConversionTransactions | EtoroFeeCalculated | Passthrough | Tier 3 |
| 9 | EstimatedBlockChainFee | Wallet.ConversionTransactions | EstimatedBlockChainFee | Passthrough | Tier 3 |
| 10 | Occurred | Wallet.ConversionTransactions | Occurred | Passthrough | Tier 3 |
| 11 | CryptoId | Wallet.ConversionTransactions | CryptoId | Passthrough | Tier 3 |
| 12 | etr_y | Generic Pipeline | Occurred | Year extracted from Occurred | Tier 3 |
| 13 | etr_ym | Generic Pipeline | Occurred | Year-month extracted from Occurred | Tier 3 |
| 14 | etr_ymd | Generic Pipeline | Occurred | Full date extracted from Occurred | Tier 3 |

_DDL column count: 13. Lineage rows 1-14 account for all columns (etr_* are ETL-generated)._

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 3 | 13 | All columns (no upstream wiki available; grounded in DDL, live data, view code, and downstream EXW_FactConversions documentation) |

## UC External Lineage

| Property | Value |
|----------|-------|
| UC Target | `wallet.bronze_walletdb_wallet_conversiontransactions` |
| UC Format | parquet |
| Lineage API | Not configured (Bronze landing) |
