# Review Needed: BI_DB_dbo.BI_DB_Affiliate_Guidlines_Report

Generated: 2026-04-23 | Batch: 54 | Pipeline: build-wiki-bidb-batch

---

## 🔴 HIGH PRIORITY — KYC_filled Is Permanently NULL

**Column**: KYC_filled

The source that populates `KYC_filled` (count of KYC questions answered by the customer from `UserApiDB.KYC.CustomerAnswers`) is commented out in the SP. Two implementation variants (direct query and linked-server openquery) are both disabled:

```sql
-- isnull(qa.QuestionsAnswered, 0) As KYC_filled,  ← COMMENTED OUT
NULL As KYC_filled,  ← current code
```

If downstream compliance reports use this field for KYC completion monitoring, they are silently receiving NULL for all customers. This is likely broken — it should either be re-implemented or the column should be removed.

**Action**: Determine whether UserApiDB.KYC.CustomerAnswers is accessible via a supported connection method. If yes, restore the source query. If no, remove the column and update downstream consumers.

---

## 🟡 MEDIUM — Table Name Typo

**Object name**: BI_DB_Affiliate_**Guidlines**_Report (missing 'e')

The correct spelling is "Guidelines." This typo is embedded in both the table name and the SP name. While changing this would require coordination (SP, table, external consumers), it should be flagged for a future cleanup cycle.

---

## 🟡 MEDIUM — UpdateDate Type Mismatch

`UpdateDate` is declared as `datetime` in the DDL but the SP inserts `CONVERT(DATE, GetDate())` — a date-only value with time component always `00:00:00`. This is a schema/implementation mismatch. Either:
- Change the SP to use `GETDATE()` directly (for true datetime), or
- Change the DDL column type to `date`

---

## 🟡 MEDIUM — Unmatched Affiliates Not Logged

When fiktivo affiliate usernames fail to match any etoro Dim_Customer.UserName, the affiliate is silently excluded from the output (TradingAccount_CID=0 filtered out by inner join). There is no logging of how many affiliates failed to match. This is a data completeness gap — affiliate records in fiktivo with no matching etoro account are invisible in this report.

**Action**: Add a diagnostic step or a separate exclusion log to track unmatched affiliates.

---

## ℹ️ INFO — Duplicate CIDs

~1,459 customers appear in more than one row (71,336 rows vs 69,877 distinct CIDs). This reflects customers linked to multiple affiliates. Downstream consumers aggregating at the CID level must handle this — use DISTINCT CID or filter to a specific AffiliateID.

---

## ℹ️ INFO — UC Migration Status

**UC Target**: `_Not_Migrated`

No Unity Catalog migration target is defined. If affiliate reporting is moving to Databricks, include this table in scope.
