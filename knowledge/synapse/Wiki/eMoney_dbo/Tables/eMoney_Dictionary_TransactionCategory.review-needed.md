# Review Needed — eMoney_dbo.eMoney_Dictionary_TransactionCategory

**Generated**: 2026-04-21  
**Reviewer Action Required**: LOW priority — static reference, straightforward  

---

## Tier 4 Items (Limited Confidence)

None. All 3 columns resolved to Tier 1 or Tier 2.

---

## Open Questions for Domain Reviewers

1. **Is this table actively maintained?** The UpdateDate is frozen at 2023-06-12. If FiatDwhDB adds new TransactionCategory values (e.g., ID 5+), this table will NOT auto-update. Should a refresh mechanism be added, or is this intentionally static?

2. **Why does SP_eMoney_DimFact_Transaction NOT use this table?** The SP loads `External_FiatDwhDB_Dictionary_TransactionCategories` (a live FiatDwhDB external table) instead of this local copy. This means the ETL has a live source and a stale local copy side-by-side. Is `eMoney_Dictionary_TransactionCategory` redundant / unused?

3. **UC Migration scope**: Is this table intended for Unity Catalog migration? Given its static nature and the existence of the FiatDwhDB external table alternative, it may be out of scope for UC export.

---

## Lineage Gaps

- **UpdateDate source**: Confirmed as the manual INSERT timestamp (2023-06-12). No production source equivalent. Documented as Tier 2 (manual load artifact).

---

## Flags

- **Potential redundancy**: `eMoney_Dictionary_TransactionCategory` is not joined by any current SP; its production counterpart (`External_FiatDwhDB_Dictionary_TransactionCategories`) is used instead. Consider deprecating this local copy if it adds no unique value.
- **Static drift risk**: Values frozen at 2023-06-12. Monitor FiatDwhDB for new category additions.
