# Review Needed — eMoney_dbo.eMoney_Dictionary_TransactionType

## Summary

Low-risk dictionary table. 2 of 3 columns are Tier 1 (upstream verbatim). No Tier 3 or Tier 4 columns.

## Items for Review

### 1. UpdateDate semantics (Tier 2)

- **Column**: `UpdateDate`
- **Issue**: All 15 rows show the same value `2023-06-12 03:48:01.773`. This appears to be the Generic Pipeline load timestamp, not a per-row update timestamp. Confirm whether this reflects the last full-table Override load date or has a different meaning.
- **Action**: Verify with ETL team whether UpdateDate is populated by the Generic Pipeline Bronze export or by the FiatDwhDB source itself.

### 2. UC target existence

- **UC Target**: `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype`
- **Issue**: Bundle resolution shows this UC target as "unresolved". The Gold export may not yet exist or may use a different naming convention.
- **Action**: Verify UC target exists in Databricks Unity Catalog.

### 3. CryptoToFiat (ID=14) categorization gap

- **Observation**: SP_eMoney_Calculated_Balance classifies TxTypeID=14 (CryptoToFiat) under `TBD` via the `TxClientBalanceCategory` fallback rather than a dedicated CASE branch. This means C2F transactions are excluded from all named balance categories.
- **Action**: Confirm with product team whether this is intentional or a pending classification.

### 4. Referenced-By completeness

- **Observation**: 9 SPs reference `TxTypeID` but the dictionary table column is `TransactionTypeID`. The SPs join via `eMoney_Fact_Transaction_Status.TxTypeID`, not directly to this dictionary. Section 6.2 lists downstream consumers — verify these all actually JOIN to this dictionary or use the type IDs inline.
