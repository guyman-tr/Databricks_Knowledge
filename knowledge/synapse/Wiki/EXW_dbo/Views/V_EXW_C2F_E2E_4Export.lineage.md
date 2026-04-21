---
object: EXW_dbo.V_EXW_C2F_E2E_4Export
type: View
base_table: EXW_dbo.EXW_C2F_E2E
filter: None (full table)
lineage_generated: 2026-04-20
---

# Column Lineage — EXW_dbo.V_EXW_C2F_E2E_4Export

## View Definition Summary

```
SELECT 103 columns FROM EXW_dbo.EXW_C2F_E2E
(no WHERE filter)
```

101 columns are direct pass-through (identical names and semantics).
2 columns apply a type cast for export compatibility:
- `C2FCorrelationID`: CAST(uniqueidentifier AS varchar(50))
- `SentWalletID`: CAST(uniqueidentifier AS varchar(50))

No columns are renamed or excluded vs. the base table.

## ETL Chain

```
[SP_EXW_C2F_E2E — full DELETE + INSERT]
  Sources: WalletConversionDB.C2F + WalletDB.Wallet + FiatDwhDB + DWH snapshots
  v
EXW_dbo.EXW_C2F_E2E (14,544 rows)
  |-- V_EXW_C2F_E2E_4Export (view — no filter) ---|
  v
Downstream export consumers (BI, reporting, data delivery)
  |-- UC Target: _Not_Migrated ---|
```

## Column Lineage

| # | View Column | Base Table Column | Type Cast | Tier |
|---|------------|-------------------|-----------|------|
| 1 | C2FCorrelationID | C2FCorrelationID | uniqueidentifier → varchar(50) | Tier 1 — C2F.Conversions |
| 2 | TargetPlatformID | TargetPlatformID | — | Tier 1 — C2F.Conversions |
| 3 | TargetPlatform | TargetPlatform | — | Tier 2 — SP_EXW_C2F_E2E |
| 4 | ConversionCycle | ConversionCycle | — | Tier 2 — SP_EXW_C2F_E2E |
| 5 | LastModificationDateTime | LastModificationDateTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 6 | LastModificationDate | LastModificationDate | — | Tier 2 — SP_EXW_C2F_E2E |
| 7 | LastModificationDateID | LastModificationDateID | — | Tier 2 — SP_EXW_C2F_E2E |
| 8 | GCID | GCID | — | Tier 1 — C2F.Conversions |
| 9 | RealCID | RealCID | — | Tier 2 — SP_EXW_C2F_E2E |
| 10 | RequestID | RequestID | — | Tier 1 — Wallet.Requests |
| 11 | RequestCryptoID | RequestCryptoID | — | Tier 1 — Wallet.Requests |
| 12 | RequestDateTime | RequestDateTime | — | Tier 1 — Wallet.Requests |
| 13 | RequestLastStatusID | RequestLastStatusID | — | Tier 2 — SP_EXW_C2F_E2E |
| 14 | RequestLastStatus | RequestLastStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 15 | RequestLastStatusDateTime | RequestLastStatusDateTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 16 | SentTransactionID | SentTransactionID | — | Tier 1 — Wallet.SentTransactions |
| 17 | SentBlockchainTransactionID | SentBlockchainTransactionID | — | Tier 1 — Wallet.SentTransactions |
| 18 | SentWalletID | SentWalletID | uniqueidentifier → varchar(50) | Tier 1 — Wallet.SentTransactions |
| 19 | SentTransactionDateTime | SentTransactionDateTime | — | Tier 1 — Wallet.SentTransactions |
| 20 | SentBlockchainFee | SentBlockchainFee | — | Tier 1 — Wallet.SentTransactions |
| 21 | SentCryptoID | SentCryptoID | — | Tier 1 — Wallet.SentTransactions |
| 22 | SentAmount | SentAmount | — | Tier 2 — SP_EXW_C2F_E2E |
| 23 | SentEtoroFees | SentEtoroFees | — | Tier 2 — SP_EXW_C2F_E2E |
| 24 | SentLastStatusID | SentLastStatusID | — | Tier 2 — SP_EXW_C2F_E2E |
| 25 | SentLastStatus | SentLastStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 26 | EstimatedFiatAmount | EstimatedFiatAmount | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 27 | EstimatedUsdAmount | EstimatedUsdAmount | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 28 | EstimatedCryptoToUsdRate | EstimatedCryptoToUsdRate | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 29 | EstimatedFiatToUsdRate | EstimatedFiatToUsdRate | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 30 | EstimatedCryptoToFiatRate | EstimatedCryptoToFiatRate | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 31 | EstimatedDateTime | EstimatedDateTime | — | Tier 1 — C2F.EstimatedFiatTransactions |
| 32 | C2FConversionID | C2FConversionID | — | Tier 1 — C2F.Conversions |
| 33 | CryptoID | CryptoID | — | Tier 1 — C2F.Conversions |
| 34 | Crypto | Crypto | — | Tier 2 — SP_EXW_C2F_E2E |
| 35 | FiatCurrencyID | FiatCurrencyID | — | Tier 1 — C2F.Conversions |
| 36 | FiatCurrency | FiatCurrency | — | Tier 2 — SP_EXW_C2F_E2E |
| 37 | CryptoAmount | CryptoAmount | — | Tier 1 — C2F.Conversions |
| 38 | TotalFeePercentage | TotalFeePercentage | — | Tier 1 — C2F.Conversions |
| 39 | TotalFeeUSD | TotalFeeUSD | — | Tier 2 — SP_EXW_C2F_E2E |
| 40 | ConversionDateTime | ConversionDateTime | — | Tier 1 — C2F.Conversions |
| 41 | ConversionDateID | ConversionDateID | — | Tier 2 — SP_EXW_C2F_E2E |
| 42 | ConversionDate | ConversionDate | — | Tier 2 — SP_EXW_C2F_E2E |
| 43 | ConversionStatusID | ConversionStatusID | — | Tier 1 — C2F.ConversionStatuses |
| 44 | ConversionStatus | ConversionStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 45 | ConversionStatusDateTime | ConversionStatusDateTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 46 | ConversionStatusDateID | ConversionStatusDateID | — | Tier 2 — SP_EXW_C2F_E2E |
| 47 | ConversionStatusDate | ConversionStatusDate | — | Tier 2 — SP_EXW_C2F_E2E |
| 48 | BlockchainTransactionID | BlockchainTransactionID | — | Tier 1 — C2F.CryptoTransactions |
| 49 | FromAddress | FromAddress | — | Tier 2 — SP_EXW_C2F_E2E |
| 50 | ToAddress | ToAddress | — | Tier 1 — C2F.CryptoTransactions |
| 51 | BlockchainFee | BlockchainFee | — | Tier 1 — C2F.CryptoTransactions |
| 52 | CryptoTransactionDateTime | CryptoTransactionDateTime | — | Tier 1 — C2F.CryptoTransactions |
| 53 | CryptoTransactionDateID | CryptoTransactionDateID | — | Tier 2 — SP_EXW_C2F_E2E |
| 54 | CryptoTransactionDate | CryptoTransactionDate | — | Tier 2 — SP_EXW_C2F_E2E |
| 55 | CryptoToFiatRate | CryptoToFiatRate | — | Tier 1 — C2F.FiatTransactions |
| 56 | FiatToUsdRate | FiatToUsdRate | — | Tier 1 — C2F.FiatTransactions |
| 57 | CryptoToUsdRate | CryptoToUsdRate | — | Tier 1 — C2F.FiatTransactions |
| 58 | FiatAmount | FiatAmount | — | Tier 1 — C2F.FiatTransactions |
| 59 | UsdAmount | UsdAmount | — | Tier 1 — C2F.FiatTransactions |
| 60 | FiatAccountID | FiatAccountID | — | Tier 1 — C2F.FiatTransactions |
| 61 | FiatDetails | FiatDetails | — | Tier 1 — C2F.FiatTransactions |
| 62 | RateTime | RateTime | — | Tier 1 — C2F.FiatTransactions |
| 63 | FiatTxTime | FiatTxTime | — | Tier 1 — C2F.FiatTransactions |
| 64 | eMoneyTransactionID | eMoneyTransactionID | — | Tier 2 — SP_EXW_C2F_E2E |
| 65 | eMoneyTxCreatedDate | eMoneyTxCreatedDate | — | Tier 2 — SP_EXW_C2F_E2E |
| 66 | eMoneyReferenceNumber | eMoneyReferenceNumber | — | Tier 2 — SP_EXW_C2F_E2E |
| 67 | eMoneyLastTxStatusID | eMoneyLastTxStatusID | — | Tier 2 — SP_EXW_C2F_E2E |
| 68 | eMoneyLastTxStatus | eMoneyLastTxStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 69 | eMoneyHolderAmount | eMoneyHolderAmount | — | Tier 2 — SP_EXW_C2F_E2E |
| 70 | eMoneyLastStatusTime | eMoneyLastStatusTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 71 | eMoneyProviderTransactionID | eMoneyProviderTransactionID | — | Tier 2 — SP_EXW_C2F_E2E |
| 72 | eMoneyAccountProgram | eMoneyAccountProgram | — | Tier 2 — SP_EXW_C2F_E2E |
| 73 | eMoneyAccountSubProgram | eMoneyAccountSubProgram | — | Tier 2 — SP_EXW_C2F_E2E |
| 74 | eMoneyCurrencyBalanceID | eMoneyCurrencyBalanceID | — | Tier 2 — SP_EXW_C2F_E2E |
| 75 | eMoneyProviderCurrencyBalanceID | eMoneyProviderCurrencyBalanceID | — | Tier 2 — SP_EXW_C2F_E2E |
| 76 | eMoneyHolderID | eMoneyHolderID | — | Tier 2 — SP_EXW_C2F_E2E |
| 77 | eMoneyIsValidETM | eMoneyIsValidETM | — | Tier 2 — SP_EXW_C2F_E2E |
| 78 | eMoneyEntity | eMoneyEntity | — | Tier 2 — SP_EXW_C2F_E2E |
| 79 | IsTestAccount | IsTestAccount | — | Tier 2 — SP_EXW_C2F_E2E |
| 80 | IsRequestDone | IsRequestDone | — | Tier 2 — SP_EXW_C2F_E2E |
| 81 | TribeHolderAmount | TribeHolderAmount | — | Tier 2 — SP_EXW_C2F_E2E |
| 82 | TribeTxDateTime | TribeTxDateTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 83 | DepositID | DepositID | — | Tier 2 — SP_EXW_C2F_E2E |
| 84 | DepositDateTime | DepositDateTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 85 | DepositModificationTime | DepositModificationTime | — | Tier 2 — SP_EXW_C2F_E2E |
| 86 | DepositLastStatusID | DepositLastStatusID | — | Tier 2 — SP_EXW_C2F_E2E |
| 87 | DepositLastStatus | DepositLastStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 88 | DepositUSD | DepositUSD | — | Tier 2 — SP_EXW_C2F_E2E |
| 89 | RegulationID | RegulationID | — | Tier 2 — SP_EXW_C2F_E2E |
| 90 | Regulation | Regulation | — | Tier 2 — SP_EXW_C2F_E2E |
| 91 | CountryID | CountryID | — | Tier 2 — SP_EXW_C2F_E2E |
| 92 | Country | Country | — | Tier 2 — SP_EXW_C2F_E2E |
| 93 | CustomerRegionID | CustomerRegionID | — | Tier 2 — SP_EXW_C2F_E2E |
| 94 | State | State | — | Tier 2 — SP_EXW_C2F_E2E |
| 95 | IsValidCustomer | IsValidCustomer | — | Tier 2 — SP_EXW_C2F_E2E |
| 96 | IsCreditReportValidCB | IsCreditReportValidCB | — | Tier 2 — SP_EXW_C2F_E2E |
| 97 | PlayerLevelID | PlayerLevelID | — | Tier 2 — SP_EXW_C2F_E2E |
| 98 | Club | Club | — | Tier 2 — SP_EXW_C2F_E2E |
| 99 | PlayerStatusID | PlayerStatusID | — | Tier 2 — SP_EXW_C2F_E2E |
| 100 | PlayerStatus | PlayerStatus | — | Tier 2 — SP_EXW_C2F_E2E |
| 101 | WalletEntity | WalletEntity | — | Tier 2 — SP_EXW_C2F_E2E |
| 102 | AccountManager | AccountManager | — | Tier 2 — SP_EXW_C2F_E2E |
| 103 | UpdateDate | UpdateDate | — | Tier 2 — SP_EXW_C2F_E2E |

## Notes

- 101 of 103 columns are direct pass-through (no rename, no cast, no computation)
- 2 columns are CAST from uniqueidentifier to varchar(50) for downstream export compatibility:
  - C2FCorrelationID: allows Power BI / Excel / ODBC consumers that don't support GUID types
  - SentWalletID: same reason
- No rows are filtered — view is a full pass-through of EXW_C2F_E2E (14,544 rows)
- No UC target (view — no direct lake mapping)
