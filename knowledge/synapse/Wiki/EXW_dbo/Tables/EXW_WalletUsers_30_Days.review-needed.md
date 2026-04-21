---
object: EXW_dbo.EXW_WalletUsers_30_Days
review_priority: LOW
batch: 9
---

# EXW_WalletUsers_30_Days — Review Flags

## Flags

| # | Flag | Severity | Detail |
|---|------|----------|--------|
| 1 | TransactionTypeID 10 and 13 exclusion — business meaning | LOW | The SP excludes TransactionTypeID IN(10,13) from Transaction30Days. The exact meaning of types 10 and 13 is not in this wiki. Confirm these are internal/system types and not customer-visible transactions. Check EXW_FactTransactions dictionary. |
| 2 | BI_DB_CIDFirstDates coverage | LOW | LoggedIn30Days sources from BI_DB_dbo.BI_DB_CIDFirstDates. Coverage of this table versus all wallet users is unknown — if some users are not represented in CIDFirstDates, LoggedIn30Days may be 0 even if they have logged in. |
| 3 | DISTINCT in INSERT | LOW | The SP uses `SELECT DISTINCT` — if EXW_DimUser has duplicate GCIDs (should not happen by design), only one row is kept and LoggedIn30Days/Transaction30Days values may be silently dropped. Verify EXW_DimUser has no GCID duplicates. |
| 4 | Continent NULLs for unknown countries | LOW | Countries not in the 250-row ISO hardcoded table will have NULL Continent. This is a known limitation of the hardcoded mapping approach. |

## No blocking issues. File is complete.
