# Lineage: eMoney_dbo.eMoney_BankPaymentsUK

**Generated**: 2026-04-21  
**Writer SP**: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` (BankPaymentsUK section)  
**Load Pattern**: Incremental — DELETE WHERE Created = @Date + INSERT from Tribe AccountsActivities  
**Distribution**: HASH(TransactionId), CLUSTERED COLUMNSTORE INDEX (CCI)

---

## Source Objects

| Source | Type | Role |
|--------|------|------|
| #AccountsActivities (Tribe ETL temp table) | Tribe Reconciliation | Raw GBP bank payment transactions from Tribe — filtered: HolderCurrencyAlpha='GBP', Network IN ('Internal Payment','External Payment'), TransactionCode NOT IN (6,14,15,24,25,64) |
| eMoney_dbo.eMoney_Dim_Account (or CopyFromLake) | DWH Table | AccountId source for JOIN (implicit in Tribe data reconciliation) |

---

## Column Lineage

| # | Synapse Column | Source DB | Source Schema | Source Table | Source Column | Transform | Tier |
|---|---------------|-----------|---------------|--------------|---------------|-----------|------|
| 1 | HolderId | FiatDwhDB | dbo | AccountsProviderHoldersMapping | ProviderHolderId | Passthrough from Tribe AccountsActivities (#AccountsActivities.HolderId) | 2 |
| 2 | AccountId | FiatDwhDB | dbo | FiatAccount | Id | Passthrough from #AccountsActivities | 1 |
| 3 | ExternalBankAccountId | FiatDwhDB | dbo | FiatBankAccount | Id | Passthrough from #AccountsActivities (the other bank's account record) | 1 |
| 4 | BankAccountNumber | FiatDwhDB | dbo | FiatBankAccount | — | External bank account numeric identifier from AccountsActivities | 2 |
| 5 | TransactionCode | FiatDwhDB | dbo | FiatTransactions | — | Tribe transaction type code; CASE expression input for BankActivityType | 2 |
| 6 | TransactionDateTime | FiatDwhDB | dbo | FiatTransactions | — | Passthrough from AccountsActivities | 2 |
| 7 | TransactionAmount | FiatDwhDB | dbo | FiatTransactions | Amount | Transaction amount in TransactionCurrency (always GBP for this table) | 2 |
| 8 | TransactionCurrencyCode | FiatDwhDB | dbo | FiatTransactions | — | ISO 4217 numeric code (always 826=GBP for this table) | 2 |
| 9 | TransactionCurrencyAlpha | FiatDwhDB | dbo | FiatTransactions | — | Text currency code (always 'GBP' for this table) | 2 |
| 10 | HolderAmount | FiatDwhDB | dbo | FiatTransactions | HolderAmount | Amount in holder currency (GBP); positive=MI, negative=MO | 2 |
| 11 | HolderCurrencyAlpha | FiatDwhDB | dbo | FiatTransactions | — | Holder currency text (always 'GBP'); SP filter: HolderCurrencyAlpha='GBP' | 2 |
| 12 | TransactionId | FiatDwhDB | dbo | FiatTransactions | Id | Tribe/FiatDwhDB transaction PK; HASH distribution key; unique per row | 2 |
| 13 | EpmMethodId | FiatDwhDB | dbo | FiatTransactions | — | Electronic payment method identifier from AccountsActivities | 2 |
| 14 | BankActivityType | ETL | — | — | — | CASE expression on TransactionCode; 4 live values: BankPayIns-External (TC 57/59/68), BankPayOuts-External (TC 56/58), BankPayOuts-DebitAdj (TC 11), BankPayOuts-BankingReturn (TC 66) | 2 |
| 15 | Created | FiatDwhDB | dbo | FiatTransactions | Created | Tribe batch creation date for the transaction record; DELETE WHERE Created + INSERT key | 2 |
| 16 | Date | ETL | — | — | — | CAST(TransactionDateTime AS DATE) — actual transaction business date | 2 |
| 17 | DateID | ETL | — | — | — | YYYYMMDD integer of Date | 2 |
| 18 | UpdateDate | ETL | — | — | — | GETDATE() at INSERT time | 2 |

---

## ETL Pipeline

```
Tribe / FiatDwhDB GBP bank payment transactions (SEPA, internal, direct debit channels)
  |-- SP_eMoney_Reconciliation_ETLs: #AccountsActivities (Tribe reconciliation temp table) ---|
  Filter: HolderCurrencyAlpha='GBP'
         AND Network IN ('Internal Payment', 'External Payment')
         AND TransactionCode NOT IN (6,14,15,24,25,64)
  |-- BankActivityType CASE: TC→BankPayIns-External / BankPayOuts-External / BankPayOuts-DebitAdj / BankPayOuts-BankingReturn ---|
  v
DELETE WHERE Created = @Date
INSERT INTO eMoney_dbo.eMoney_BankPaymentsUK (incremental append, daily window)
  v
eMoney_dbo.eMoney_BankPaymentsUK (468,632 rows, 2025-12-21→2026-04-11, HASH(TransactionId), CCI)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | AccountId, ExternalBankAccountId |
| Tier 2 | 16 | All others (HolderId, BankAccountNumber, TransactionCode, TransactionDateTime, TransactionAmount, TransactionCurrencyCode, TransactionCurrencyAlpha, HolderAmount, HolderCurrencyAlpha, TransactionId, EpmMethodId, BankActivityType, Created, Date, DateID, UpdateDate) |

*Tier 1: 2 | Tier 2: 16 | Total: 18*
