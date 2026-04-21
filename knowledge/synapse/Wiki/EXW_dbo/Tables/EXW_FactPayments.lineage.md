# EXW_dbo.EXW_FactPayments — Column Lineage

**Generated**: 2026-04-20  
**Object**: EXW_dbo.EXW_FactPayments  
**Type**: Table  
**Production Sources**: WalletDB.Wallet.Payments, WalletDB.Wallet.PaymentTransactions, WalletDB.Wallet.PaymentStatuses  
**ETL Mechanism**: External pipeline (no SSDT SP; likely Generic Pipeline or ADF from WalletDB)  
**Upstream Wiki Repo**: CryptoDBs (WalletDB/Wiki)

---

## ETL Pipeline

```
WalletDB.Wallet.Payments (payment request — ~99K rows)
  + WalletDB.Wallet.PaymentTransactions (crypto execution details)
  + WalletDB.Wallet.PaymentStatuses (status events — ~553K events for ~99K payments)
  + WalletDB.Wallet.FiatTypes (fiat currency name lookup)
  + WalletDB.Wallet.CryptoTypes (crypto name lookup)
  + WalletDB.Wallet.Wallets → GCID mapping
  |-- External pipeline (no SSDT SP) ---|
  v
EXW_dbo.EXW_FactPayments (553K rows — one per payment × status event)
  HASH(GCID), HEAP
  |-- Data frozen 2022-09-20 — Simplex decommissioned ---|
  v
UC Target: _Not_Migrated (no mapping in bronze_opsdb_dbo_vw_unitycatalog_mapping_tables)
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|------------|-------------|---------------|-----------|------|
| 1 | PaymentID | Wallet.Payments | Id | Renamed Id → PaymentID; passthrough value | Tier 1 |
| 2 | ProviderPaymentID | Wallet.Payments | ProviderPaymentId | Passthrough (case rename) | Tier 1 |
| 3 | WalletID | Wallet.Payments | WalletId | Passthrough (case rename) | Tier 1 |
| 4 | AmountInFiat | Wallet.Payments | Amount | Renamed Amount → AmountInFiat; passthrough value | Tier 1 |
| 5 | FiatID | Wallet.Payments | FiatId | Passthrough (case rename) | Tier 1 |
| 6 | CorrelationID | Wallet.Payments | CorrelationId | Passthrough (case rename) | Tier 1 |
| 7 | RequestDate | Wallet.Payments | Occurred | Renamed Occurred → RequestDate; passthrough value | Tier 1 |
| 8 | ModificationDate | Wallet.PaymentStatuses | Occurred | Renamed Occurred → ModificationDate (status event timestamp) | Tier 1 |
| 9 | ExchangeRate | Wallet.PaymentTransactions | ExchangeRate | Passthrough | Tier 1 |
| 10 | ToAddress | Wallet.PaymentTransactions | ToAddress | Passthrough | Tier 1 |
| 11 | AmountInCrypto | Wallet.PaymentTransactions | Amount | Renamed Amount → AmountInCrypto; passthrough value | Tier 1 |
| 12 | EtoroFeePercentage | Wallet.PaymentTransactions | EtoroFeePercentage | Passthrough | Tier 1 |
| 13 | EtoroFeeCalculated | Wallet.PaymentTransactions | EtoroFeeCalculated | Passthrough | Tier 1 |
| 14 | ProviderFeeCalculated | Wallet.PaymentTransactions | ProviderFeeCalculated | Passthrough | Tier 1 |
| 15 | EstimatedBlockChainFee | Wallet.PaymentTransactions | EstimatedBlockChainFee | Passthrough | Tier 1 |
| 16 | CryptoId | Wallet.Payments | CryptoId | Passthrough | Tier 1 |
| 17 | FiatName | Wallet.FiatTypes | FiatName | Denormalized join (FiatId → FiatName) | Tier 2 |
| 18 | CryptoName | Wallet.CryptoTypes | Name | Denormalized join (CryptoId → Name, renamed CryptoName) | Tier 2 |
| 19 | PaymentStatus | Dictionary.PaymentStatuses | Name | Denormalized join (PaymentStatusId → status name string) | Tier 2 |
| 20 | GCID | Wallet.Wallets → customer mapping | GCID | Derived via wallet-to-customer lookup | Tier 2 |
| 21 | SentTransactionID | Wallet.SagaSendTx or similar | Id/TransactionId | Sent blockchain transaction reference | Tier 2 |
| 22 | ReceivedTransactionID | Wallet.Transactions or similar | Id | Received transaction reference | Tier 2 |
| 23 | BlockchainTransactionId | Wallet.SagaSendTx or similar | BlockchainTransactionId | Blockchain tx hash | Tier 2 |
| 24 | BlockChainFee | Wallet.SagaSendTx or similar | BlockchainFee | Actual (realized) blockchain fee | Tier 2 |
| 25 | BlockchainCryptoID | Wallet.CryptoTypes | CryptoID | Blockchain-specific crypto identifier | Tier 2 |
| 26 | UpdateDate | ETL | — | ETL-managed load timestamp | Tier 2 |
| 27 | RequestDateID | ETL | — | Date integer key from RequestDate (YYYYMMDD) | Tier 2 |
| 28 | Date | ETL | — | Date portion of RequestDate (cast to date) | Tier 2 |

---

## Notes

- **One row per (PaymentID, PaymentStatus) event**: 553,884 rows / 99,410 distinct PaymentIDs ≈ 5.57 rows per payment — matches the ~11 PaymentStatus events in Wallet.PaymentStatuses
- **16 Tier 1 columns** from 3 upstream WalletDB tables — very high T1 coverage
- **Upstream wiki repo**: CryptoDBs/WalletDB/Wiki (routing file confirmed)
- **Upstream wiki paths**:
  - Wallet.Payments: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md`
  - Wallet.PaymentTransactions: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`
  - Wallet.PaymentStatuses: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentStatuses.md`
