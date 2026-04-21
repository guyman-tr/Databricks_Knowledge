# eMoney_dbo.eMoney_Dictionary_TransactionCategory

> Static lookup table defining 5 transaction category values for the eToro Money fiat platform (0=Unknown through 4=BalanceAdjustmentTransaction). Mirrored from FiatDwhDB.Dictionary.TransactionCategories via a one-time manual INSERT on 2023-06-12; no refresh SP. Referenced conceptually by eMoney_Dim_Transaction and eMoney_Fact_Transaction_Status via the TxCategoryID column (resolved at query time).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Dictionary.TransactionCategories (manual one-time load, 2023-06-12) |
| **Refresh** | None — static reference (no writer SP; loaded once) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` (static reference — no Generic Pipeline export) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A (not migrated) |

---

## 1. Business Meaning

`eMoney_Dictionary_TransactionCategory` is a 5-row static lookup table that classifies fiat platform transactions into mutually exclusive high-level categories. Each row maps an integer category identifier to a human-readable category name. The values enumerate the four distinct transaction flow types used in the eToro Money fiat platform — card payments, banking (IBAN/bank transfer), transfers between accounts, and balance adjustments — plus an Unknown sentinel.

The table was loaded on 2023-06-12 as a direct mirror of `FiatDwhDB.Dictionary.TransactionCategories` and has never been updated (all 5 rows share the same UpdateDate). It is effectively a compile-time constant — the category codes are embedded in the production fiat platform schema and are unlikely to change. The table is NOT directly joined by any current ETL stored procedure in eMoney_dbo (SP_eMoney_DimFact_Transaction instead loads `External_FiatDwhDB_Dictionary_TransactionCategories`, a live FiatDwhDB external table); `eMoney_Dictionary_TransactionCategory` serves as a static DWH-local reference for ad-hoc queries and documentation purposes.

**Complete value set (5 rows)**: 0=Unknown, 1=CardTransaction, 2=BankingTransaction, 3=TransferTransaction, 4=BalanceAdjustmentTransaction

---

## 2. Business Logic

### 2.1 Category Taxonomy

**What**: Transaction category defines the high-level payment rail or mechanism used for the transaction.  
**Columns Involved**: TransactionCategoryID, TransactionCategory  
**Rules**:
- **0 = Unknown**: Default/unclassified; should be rare in clean production data.
- **1 = CardTransaction**: Fiat transactions executed via a physical or virtual card (Visa debit card, card-based purchases).
- **2 = BankingTransaction**: IBAN/bank account-based transactions (SEPA, SWIFT, bank wires).
- **3 = TransferTransaction**: Internal transfers between eToro Money accounts or between currency balances.
- **4 = BalanceAdjustmentTransaction**: Regulatory or operational balance corrections that are not card/bank/transfer (e.g., manual adjustments, CASS reimbursements).

### 2.2 Static Reference Semantics

**What**: This table is a compile-time constant; the category codes are stable and defined by the production fiat platform schema.  
**Columns Involved**: UpdateDate  
**Rules**:
- All 5 rows have `UpdateDate = 2023-06-12 03:48:01.663` — the timestamp of the original manual INSERT.
- No refresh mechanism exists. If new categories are added to FiatDwhDB, this table WILL NOT automatically reflect them — a manual INSERT would be required.
- SP_eMoney_DimFact_Transaction uses a live FiatDwhDB external table (`External_FiatDwhDB_Dictionary_TransactionCategories`) for its category lookup rather than this table.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution with HEAP index. This 5-row table is broadcast to all compute nodes — no join skew possible. Fully appropriate for a lookup table of this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| List all transaction categories | `SELECT * FROM eMoney_dbo.eMoney_Dictionary_TransactionCategory ORDER BY TransactionCategoryID` |
| Decode TxCategoryID in eMoney_Dim_Transaction | `LEFT JOIN eMoney_dbo.eMoney_Dictionary_TransactionCategory cat ON t.TxCategoryID = cat.TransactionCategoryID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| eMoney_dbo.eMoney_Dim_Transaction | `TxCategoryID = TransactionCategoryID` | Resolve category name for transaction records |
| eMoney_dbo.eMoney_Fact_Transaction_Status | `TxCategoryID = TransactionCategoryID` | Same decode for fact table |

### 3.4 Gotchas

- **No active ETL consumers**: SP_eMoney_DimFact_Transaction does NOT join this table; it uses the live `External_FiatDwhDB_Dictionary_TransactionCategories` mirror instead. This table is for ad-hoc analyst use only.
- **Static data**: If FiatDwhDB adds new categories, this table will be stale until manually updated.
- **All columns nullable**: Despite being a reference table, all columns are nullable (NULL-safe in production because the load was clean, but the schema permits NULLs).
- **TransactionCategoryID is int, not tinyint**: FiatDwhDB uses `tinyint` for the Id column; this table uses `int`. No data loss, but be aware of the type difference in JOINs.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim — description copied from FiatDwhDB.Dictionary.TransactionCategories |
| Tier 2 | Derived from SP code, DDL context, or live data observation |
| Tier 3 | Inferred from naming conventions and column patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary / domain knowledge |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransactionCategoryID | int | YES | Lookup identifier. Primary key. Values: 0=Unknown, 1=CardTransaction, 2=BankingTransaction, 3=TransferTransaction, 4=BalanceAdjustmentTransaction. (Tier 1 — FiatDwhDB.Dictionary.TransactionCategories) |
| 2 | TransactionCategory | varchar(50) | YES | Human-readable name for this value. Contains the full category label string (e.g., "BalanceAdjustmentTransaction"). (Tier 1 — FiatDwhDB.Dictionary.TransactionCategories) |
| 3 | UpdateDate | datetime | YES | Timestamp of the last data update. For this static table, all rows carry 2023-06-12 03:48:01 — the date of the original one-time manual load from FiatDwhDB. (Tier 2 — manual load artifact) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| TransactionCategoryID | FiatDwhDB.Dictionary.TransactionCategories | Id | Rename (Id → TransactionCategoryID) |
| TransactionCategory | FiatDwhDB.Dictionary.TransactionCategories | Name | Rename (Name → TransactionCategory) |
| UpdateDate | Manual load (no production source) | — | Set at INSERT time (2023-06-12) |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionCategories
  (production fiat platform — Id tinyint, Name nvarchar)
    |-- Manual INSERT (one-time, 2023-06-12) ---|
    v
eMoney_dbo.eMoney_Dictionary_TransactionCategory
  (5 rows, all UpdateDate = 2023-06-12, REPLICATE HEAP)
    |-- No Generic Pipeline export (static reference) ---|
    v
  [Not Migrated to Unity Catalog]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing FK references.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| TransactionCategoryID | eMoney_dbo.eMoney_Dim_Transaction (TxCategoryID) | Category decode for latest-status transaction dimension |
| TransactionCategoryID | eMoney_dbo.eMoney_Fact_Transaction_Status (TxCategoryID) | Category decode for all-status transaction fact |

*Note: No SP in eMoney_dbo directly JOINs this table. SP_eMoney_DimFact_Transaction uses `External_FiatDwhDB_Dictionary_TransactionCategories` instead. These relationships are for ad-hoc analyst use.*

---

## 7. Sample Queries

### 7.1 List all transaction categories

```sql
SELECT 
    TransactionCategoryID,
    TransactionCategory,
    UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_TransactionCategory]
ORDER BY TransactionCategoryID;
```

### 7.2 Distribution of transaction categories in eMoney_Dim_Transaction

```sql
SELECT 
    cat.TransactionCategoryID,
    cat.TransactionCategory,
    COUNT(*) AS TxCount
FROM [eMoney_dbo].[eMoney_Dim_Transaction] t
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_TransactionCategory] cat
    ON t.TxCategoryID = cat.TransactionCategoryID
GROUP BY cat.TransactionCategoryID, cat.TransactionCategory
ORDER BY cat.TransactionCategoryID;
```

### 7.3 Check for unknown category codes in transaction fact

```sql
SELECT DISTINCT 
    t.TxCategoryID,
    cat.TransactionCategory
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_TransactionCategory] cat
    ON t.TxCategoryID = cat.TransactionCategoryID
WHERE cat.TransactionCategoryID IS NULL
    OR cat.TransactionCategoryID = 0;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. The table is a low-level static reference with no documented Confluence pages or Jira tickets.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 11/14*  
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 7/10*  
*Object: eMoney_dbo.eMoney_Dictionary_TransactionCategory | Type: Table | Production Source: FiatDwhDB.Dictionary.TransactionCategories (manual load 2023-06-12)*
