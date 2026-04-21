# EXW_dbo.Hourly_Transactions — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_EXW_Hourly | **Load Pattern**: TRUNCATE + INSERT (runs hourly; last 5 days coverage; @d DATE param unused)

## ETL Pipeline

```
EXW_dbo.External_WalletDB_Wallet_TransactionsView (live external view → WalletDB)
  + EXW_Wallet.CryptoTypes (CryptoId → Crypto/DisplayName/CryptoCategoryName)
  + EXW_Wallet.EXW_Price + EXW_Currency.vInstrumentRatesForWeek (#PerHourPrices — hourly AvgPrice)
    |
    | SP_EXW_Hourly — TRUNCATE + INSERT
    | WHERE TransDate >= CAST(GETDATE()-5 AS DATE) — rolling 5-day window
    | Activity classification UNION ALL (7 TransactionTypeId groups)
    | USD = Amount × AvgPrice (per-hour price at TransDate)
    v
EXW_dbo.Hourly_Transactions (rolling ~5 days of wallet transactions)
  |-- (Tableau KPI dashboards — no documented Synapse consumer) ---|
  v
_Not_Migrated

Note: Same SP run also rebuilds Hourly_CustomerBalances, Hourly_OmnibusBalances,
Hourly_RedeemActivity, Hourly_WalletInventory, and Hourly_WalletAllocations.
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| Activity | computed | TransactionTypeId | UNION label: 'Redeem Sent'(0), 'Customer Money Out'(1), 'AmlMoneyBack'(2), 'Funding Sent'(4), 'Conversion Sent From Customer'(5), 'Conversion Sent From Omnibus'(6), 'Other'(all other IDs) | Tier 2 — SP_EXW_Hourly |
| GCID | External_WalletDB_Wallet_TransactionsView | gcid | Passthrough (lowercase alias promoted to GCID) | Tier 2 — SP_EXW_Hourly |
| CryptoId | External_WalletDB_Wallet_TransactionsView | CryptoId | Passthrough | Tier 2 — SP_EXW_Hourly |
| WalletId | External_WalletDB_Wallet_TransactionsView | WalletId | Passthrough | Tier 2 — SP_EXW_Hourly |
| TranID | External_WalletDB_Wallet_TransactionsView | TranID | Passthrough | Tier 2 — SP_EXW_Hourly |
| TransStatusId | External_WalletDB_Wallet_TransactionsView | TransStatusId | Passthrough | Tier 2 — SP_EXW_Hourly |
| TransStatus | External_WalletDB_Wallet_TransactionsView | TransStatus | Passthrough | Tier 2 — SP_EXW_Hourly |
| TransDate | External_WalletDB_Wallet_TransactionsView | TransDate | Passthrough; filter: TransDate >= CAST(GETDATE()-5 AS DATE) | Tier 2 — SP_EXW_Hourly |
| Amount | External_WalletDB_Wallet_TransactionsView | Amount | Passthrough (native crypto units) | Tier 2 — SP_EXW_Hourly |
| USD | computed | Amount × AvgPrice | Amount × #PerHourPrices.AvgPrice (hourly price at TransDate hour) | Tier 2 — SP_EXW_Hourly |
| ActionTypeName | External_WalletDB_Wallet_TransactionsView | ActionTypeName | Passthrough | Tier 2 — SP_EXW_Hourly |
| SenderAddress | External_WalletDB_Wallet_TransactionsView | SenderAddress | Passthrough | Tier 2 — SP_EXW_Hourly |
| ReciverAddress | External_WalletDB_Wallet_TransactionsView | ReciverAddress | Passthrough — typo in source ("Reciver" not "Receiver"); preserved in target | Tier 2 — SP_EXW_Hourly |
| BlockchainTransactionId | External_WalletDB_Wallet_TransactionsView | BlockchainTransactionId | Passthrough | Tier 2 — SP_EXW_Hourly |
| TransactionTypeId | External_WalletDB_Wallet_TransactionsView | TransactionTypeId | Passthrough (used to derive Activity) | Tier 2 — SP_EXW_Hourly |
| TransactionType | External_WalletDB_Wallet_TransactionsView | TransactionType | Passthrough | Tier 2 — SP_EXW_Hourly |
| Occurred | External_WalletDB_Wallet_TransactionsView | Occurred | Passthrough | Tier 2 — SP_EXW_Hourly |
| Crypto | EXW_Wallet.CryptoTypes | Name | Passthrough — joined on CryptoId | Tier 2 — SP_EXW_Hourly |
| DisplayName | EXW_Wallet.CryptoTypes | DisplayName | Passthrough — joined on CryptoId | Tier 2 — SP_EXW_Hourly |
| CryptoCategoryName | EXW_Wallet.CryptoTypes | CryptoCategoryName | Passthrough — joined on CryptoId | Tier 2 — SP_EXW_Hourly |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_EXW_Hourly |

## Source Objects

| Object | Role |
|---|---|
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | Sole transaction source — live external view on WalletDB; all 18 passthrough columns |
| EXW_Wallet.CryptoTypes | Lookup for Crypto (Name), DisplayName, CryptoCategoryName |
| EXW_Wallet.EXW_Price | Source of historical daily prices (EXW_Wallet.EXW_Price) for #7DayPrice/#DailyPrices |
| EXW_Currency.vInstrumentRatesForWeek | Source of recent hourly rates for today/yesterday (#PerHourPrices) |
| EXW_dbo.SP_EXW_Hourly | Writer SP — hourly runner; same run writes 5 other Hourly_* tables |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 2 | 21 | All columns — passthrough from external view or SP-computed; no upstream wiki |
