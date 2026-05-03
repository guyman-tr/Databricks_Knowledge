# EXW_Wallet.Conversions — Review Needed

## 1. Tier 3 Coverage

All 13 columns are Tier 3. No upstream wiki exists for WalletDB.Wallet.Conversions (`_no_upstream_found.txt` marker present). Descriptions are grounded in DDL structure, live data sampling (50,268 rows), distribution analysis, and JOIN context from EXW_TransactionsView.

## 2. Items Requiring Human Review

- **ConversionTypeId**: All rows have value 1. No lookup/dictionary table found in EXW_Dictionary. A reviewer should confirm what ConversionTypeId=1 represents and whether other values existed historically or are expected in future.
- **FromCryptoId / ToCryptoId**: 25 distinct integer values each. No dedicated crypto asset dictionary table found in EXW_Dictionary. Reviewer should confirm which dictionary or lookup these IDs reference (possibly an application-level enum or an external crypto asset registry).
- **Dormant table**: Last data is from 2023-06-14. Reviewer should confirm whether the table is intentionally retired or if the Generic Pipeline ingestion was paused/broken.
- **CorrelationId semantics**: Used as JOIN key to SentTransactions in EXW_TransactionsView. Reviewer should confirm whether CorrelationId is globally unique or scoped to a specific transaction type.

## 3. Missing Upstream Wiki

The `_no_upstream_found.txt` marker confirms no upstream wiki could be resolved for WalletDB.Wallet.Conversions. If a wiki is later created for the WalletDB production database, this object should be re-documented to upgrade columns from Tier 3 to Tier 1.

## 4. Downstream Dependencies

- **EXW_Wallet.EXW_TransactionsView** — uses Conversions in two CTEs (conversion_in_transactions, conversion_out_transactions) joined via CorrelationId to SentTransactions
- **EXW_dbo.EXW_FactConversions** — loaded via SP_EXW_C2F_E2E from CopyFromLake.WalletConversionDB_C2F_Conversions (a separate C2F pipeline, not directly from this table)
