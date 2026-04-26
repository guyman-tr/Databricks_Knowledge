# Review Needed — BI_DB_dbo.BI_DB_MifidAccountType_Count

Generated: 2026-04-22 | Batch: 29

## Tier 4 / Unresolved Items

| Column | Issue | Action Needed |
|--------|-------|---------------|
| Date | Reflects SP run date (GETDATE()), not a configured business date. The CLUSTERED INDEX on Date enables time-range queries, but querying "as of a specific business date" requires knowing when the SP actually ran on that date. | Reviewer: confirm whether 'Date' is treated as a business-date approximation by consumers, and whether time-of-day variability in GETDATE() matters. |
| Desk | Can be NULL for countries without a mapping in Ext_Dim_Country_Region_Desk. Distribution of NULLs unknown. | Reviewer: confirm whether NULL Desk is expected for certain country groups, and whether downstream reports filter or handle NULL Desk. |

## Known Data Quality Issues

1. **Rolling Window Not Enforced**: The SP deletes Date = DATEADD(DAY,-30,GETDATE()) on each run. The table retains 2029 distinct run dates (2020-09-22 to 2026-04-13) — far exceeding the 30-day design intent. Historical rows persist because the SP did not run continuously every day, leaving older dates undeleted.

2. **Count ≠ Customer ID**: The `Count` column is `COUNT(RealCID)` per group, not a customer identifier. Column name may be confused with primary keys named "Count" in other contexts.

3. **Broader Population Than AML Tables**: No IsDepositor, VerificationLevel, or regulation exclusion filter. BVI, eToroUS, NFA customers are included. Total counts are not comparable to AML-scoped reports.

4. **SP Has No Author or Date Comment**: Provenance unknown. SP was created with no documentation.

## Open Questions

- Is the intended retention period still 30 days, or has the design intent changed to preserve full history?
- Is there a downstream report that queries this table expecting only the last 30 days? If so, a WHERE Date >= DATEADD(DAY,-30,GETDATE()) filter should be added.
- Who owns SP_MifidAccountType_Count and maintains the MiFID II classification logic?

## Upstream Wiki Coverage

| Source | Wiki Exists? | Tier 1 Columns Inherited |
|--------|-------------|--------------------------|
| Dictionary.AccountType | Yes (via Dim_AccountType.md) | AccountType |
| Dictionary.Country | Yes (via Dim_Country.md) | Country |
| Dictionary.MifidCategorization | Yes (via Dim_MifidCategorization.md) | MifidCategorization |
