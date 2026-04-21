# EXW_dbo.EXW_PaymentReconciliation — Column Lineage

**Generated**: 2026-04-20  
**Object**: EXW_dbo.EXW_PaymentReconciliation  
**Type**: Table  
**Production Sources**: WalletDB.Wallet.Payments, WalletDB.Wallet.PaymentTransactions, WalletDB.Wallet.PaymentStatuses, EXW_dbo.EXW_SimplexMapping, EXW_dbo.EXW_ECPBank  
**ETL Mechanism**: External pipeline (no SSDT SP; cross-schema reconciliation join)  
**Upstream Wiki Repo**: CryptoDBs (WalletDB/Wiki)

---

## ETL Pipeline

```
WalletDB.Wallet.Payments (payment request — ~99K payments)
  + WalletDB.Wallet.PaymentTransactions (crypto execution details)
  + WalletDB.Wallet.PaymentStatuses (FINAL status per payment only)
  + WalletDB.Wallet.FiatTypes (fiat currency name lookup)
  + WalletDB.Wallet.CryptoTypes (crypto name lookup)
  + WalletDB.Wallet.Wallets → GCID mapping
  |
  LEFT JOIN ON CorrelationID / UTI
  |
EXW_dbo.EXW_SimplexMapping (38,044 matched — Simplex provider data)
  |
  LEFT JOIN ON UTI
  |
EXW_dbo.EXW_ECPBank (20,944 matched — ECP Bank settlement data)
  |-- External pipeline (no SSDT SP) ---|
  v
EXW_dbo.EXW_PaymentReconciliation (99,243 rows — one per payment, final status)
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
| 8 | ModificationDate | Wallet.PaymentStatuses | Occurred | Renamed Occurred → ModificationDate (FINAL status event timestamp) | Tier 1 |
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
| 19 | PaymentStatus | Dictionary.PaymentStatuses | Name | Final status only — last PaymentStatusId event per payment | Tier 2 |
| 20 | GCID | Wallet.Wallets → customer mapping | GCID | Derived via wallet-to-customer lookup | Tier 2 |
| 21 | SentTransactionID | Wallet.SagaSendTx or similar | Id/TransactionId | Sent blockchain transaction reference | Tier 2 |
| 22 | ReceivedTransactionID | Wallet.Transactions or similar | Id | Received transaction reference | Tier 2 |
| 23 | BlockchainTransactionId | Wallet.SagaSendTx or similar | BlockchainTransactionId | Blockchain tx hash | Tier 2 |
| 24 | BlockChainFee | Wallet.SagaSendTx or similar | BlockchainFee | Actual (realized) blockchain fee | Tier 2 |
| 25 | UpdateDate | ETL | — | ETL-managed load timestamp | Tier 2 |
| 26 | RequestDateID | ETL | — | Date integer key from RequestDate (YYYYMMDD) | Tier 2 |
| 27 | RealCID | eToro CID mapping | ClientId | eToro platform ClientID mapped from GCID; 29,775 distinct values = GCID cardinality | Tier 4 |
| 28 | SimplexCurr | EXW_dbo.EXW_SimplexMapping | fiat_currency | Renamed; EUR or GBP only (settlement currency) | Tier 4 |
| 29 | SimplexAmountCurr | EXW_dbo.EXW_SimplexMapping | requested_fiat_amount | Renamed; fiat amount requested from Simplex | Tier 4 |
| 30 | SimplexProcessTime | EXW_dbo.EXW_SimplexMapping | timestamp_created | Renamed; Simplex processing timestamp | Tier 4 |
| 31 | SimplexAmountUSD | EXW_dbo.EXW_SimplexMapping or ETL | derived | Fiat amount normalized to USD (SimplexAmountCurr × FX rate, or Simplex-provided USD amount) | Tier 4 |
| 32 | ECPTranDate | EXW_dbo.EXW_ECPBank | transaction_date | Renamed; converted from YYYYMMDD bigint to datetime | Tier 4 |
| 33 | ECPPostDate | EXW_dbo.EXW_ECPBank | posting_date | Renamed; converted from YYYYMMDD bigint to datetime | Tier 4 |
| 34 | ECPType | EXW_dbo.EXW_ECPBank | type | Renamed; always "Purchase" in reconciliation (no refunds) | Tier 4 |
| 35 | Card | EXW_dbo.EXW_ECPBank | card_no_ | Renamed; masked card number | Tier 4 |
| 36 | ECPStatus | EXW_dbo.EXW_ECPBank | status | Renamed; Cleared or Processed | Tier 4 |
| 37 | ECPAmout | EXW_dbo.EXW_ECPBank | acct_amount_gross | Renamed (note typo: "Amout"); gross settlement amount before commission | Tier 4 |
| 38 | ECPCommission | EXW_dbo.EXW_ECPBank | acct_commission_charges | Renamed; commission fee deducted at settlement | Tier 4 |
| 39 | ECPNetAmount | EXW_dbo.EXW_ECPBank | acct_amount_net | Renamed; net settlement amount (gross - commission) | Tier 4 |
| 40 | ECPAdditionalCharge | EXW_dbo.EXW_ECPBank | additional_charges | Renamed; additional charges beyond commission | Tier 4 |
| 41 | bin_country | BIN lookup or EXW_SimplexMapping | derived | Card BIN → issuing country code (e.g., GB, DE, FR); "Unknown" for unresolved BINs | Tier 4 |
| 42 | bank_name | BIN lookup or EXW_SimplexMapping | derived | Card BIN → issuing bank name | Tier 4 |
| 43 | UTI | EXW_dbo.EXW_SimplexMapping | long_id | Cross-reference key linking EXW_SimplexMapping.long_id, EXW_ECPBank.uti, and merch_tran_ref_ | Tier 4 |
| 44 | last_4_digits | EXW_ECPBank.card_no_ or EXW_SimplexMapping | derived | Last 4 digits of payment card; stored as numeric(18,0) | Tier 4 |

---

## Notes

- **One row per PaymentID**: 99,243 rows = 99,243 distinct PaymentIDs — final/current status snapshot; contrasts with EXW_FactPayments (553K rows, one per payment × status event)
- **167-payment gap**: EXW_FactPayments has 99,410 distinct PaymentIDs; EXW_PaymentReconciliation has 99,243 — 167 payments excluded (likely timing/sync or filtered test entries)
- **Three-leg reconciliation coverage**: 61,199 WalletDB-only (no Simplex/ECP match — mostly Failed); 17,100 Simplex-only (no ECP settlement); 20,944 all three sources matched
- **ECPAmout typo**: Column name is intentionally "ECPAmout" (missing 'n') — matches the DDL exactly; do not correct in queries
- **UTI join chain**: CorrelationID in Wallet.Payments → UTI in EXW_SimplexMapping.long_id → UTI in EXW_ECPBank.uti → merch_tran_ref_ (15-char prefix of UTI)
- **16 Tier 1 columns**: Same 16 WalletDB columns as EXW_FactPayments; descriptions inherit verbatim from upstream wiki
- **Upstream wiki paths**:
  - Wallet.Payments: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Payments.md`
  - Wallet.PaymentTransactions: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`
  - Wallet.PaymentStatuses: `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentStatuses.md`
