# eMoney_dbo.eMoney_Dictionary_TransactionCategory — Column Lineage

**Generated**: 2026-04-21  
**Pipeline**: Manual static load (FiatDwhDB.Dictionary.TransactionCategories mirror)  
**Source Database**: FiatDwhDB  
**Source Schema**: Dictionary  
**Source Table**: TransactionCategories  
**Load Pattern**: Manual INSERT (one-time load 2023-06-12, no refresh SP)  
**UC Target**: `_Not_Migrated` (static reference — no UC export)

---

## Column Lineage

| # | DWH Column | Type | Source Table | Source Column | Transform | Tier |
|---|-----------|------|--------------|---------------|-----------|------|
| 1 | TransactionCategoryID | int | FiatDwhDB.Dictionary.TransactionCategories | Id | Rename (Id → TransactionCategoryID), passthrough | Tier 1 |
| 2 | TransactionCategory | varchar(50) | FiatDwhDB.Dictionary.TransactionCategories | Name | Rename (Name → TransactionCategory), passthrough | Tier 1 |
| 3 | UpdateDate | datetime | — (manual load) | — | Load timestamp set at time of manual INSERT (2023-06-12) | Tier 2 |

---

## Source Objects

| Source | Type | Location |
|--------|------|----------|
| FiatDwhDB.Dictionary.TransactionCategories | Table (upstream) | BankingDBs/FiatDwhDB/Wiki/Dictionary/Tables/Dictionary.TransactionCategories.md |

---

## ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionCategories
  (production fiat platform — Id, Name)
    |-- Manual INSERT (one-time, 2023-06-12) ---|
    v
eMoney_dbo.eMoney_Dictionary_TransactionCategory
  (5 rows: 0=Unknown, 1=CardTransaction, 2=BankingTransaction,
   3=TransferTransaction, 4=BalanceAdjustmentTransaction)
    |-- No UC export (static reference, no Generic Pipeline) ---|
    v
  [Not Migrated to UC]
```

---

## Tier Coverage

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | TransactionCategoryID, TransactionCategory |
| Tier 2 | 1 | UpdateDate |
| **Total** | **3** | |

**Tier 1 ratio**: 2/3 (67%)
