# Review Needed: EXW_Wallet.Requests

## 1. Missing Upstream Wiki

All 13 columns are Tier 3 because no upstream wiki exists for WalletDB.Wallet.Requests. If a wiki is created for the WalletDB production database, columns 1-8 and 13 should be upgraded to Tier 1 with verbatim descriptions from that wiki.

## 2. Deprecated Columns

- **DeviceId**: 100% NULL across all 5M rows. Confirm with the Wallet team whether this column is intentionally unpopulated or if there is a data pipeline issue.
- **etr_y, etr_ym, etr_ymd**: All 100% NULL. These appear to be legacy ETL partition columns that were never used. Consider whether they should be dropped from the DDL or if they serve a future purpose.

## 3. RequestTypeId Dictionary Values

The 10 request types (0-9) were resolved from `CopyFromLake.WalletDB_Dictionary_RequestTypes`. Confirm that the dictionary is complete and no new types have been added to production that are not yet in the dictionary.

## 4. DetailsJson Schema

The JSON structure in DetailsJson varies by RequestTypeId. No formal schema documentation was found. Recommend documenting the expected JSON schemas per request type:
- Type 0 (CreateWallet): Likely NULL or minimal
- Type 1 (SendTransaction): {Amount, ToAddress, OriginalAddress}
- Type 4 (Conversion): {CryptoIdFrom, CryptoIdTo, AmountFrom, AmountTo, IsAmountFromFixed, RateUsedFrom, RateUsedTo, ConversionFeePercentage, BlockChainFromFee, BlockChainToFee}
- Types 2, 3, 5, 6, 7, 8, 9: Schema unknown from sample data

## 5. CryptoId Mapping

Sample data shows CryptoId values 1, 2, 6, 18. Full mapping to cryptocurrency names should be verified against EXW_Wallet.CryptoTypes. The description infers 1=Bitcoin, 2=Ethereum from context but should be confirmed.

## 6. Production Source Confirmation

The table is identified as a Generic Pipeline mirror of WalletDB.Wallet.Requests based on the pipeline mapping (generic_id=720). No writer SP exists in Synapse — confirm this is the intended loading mechanism and that no manual or ad-hoc loads occur.
