# Review Needed — BI_DB_dbo.BI_DB_Cashout_Performance_Monitoring

**Batch**: 70 | **Generated**: 2026-04-23 | **Quality**: 8.5/10

## Tier 2 Items (Require Human Verification)

| Column | Current Description | Question |
|---|---|---|
| [Withdraw Status] | Resolved from Dim_CashoutStatus.Name | Dim_CashoutStatus wiki says IDs 5-17 are "not in DWH" but live data shows ID=5 (Partially Processed, 3 rows) — has Dim_CashoutStatus been updated recently? |
| [Prepared By] | CONCAT(FirstName, ' ', LastName) from BackOffice.Manager via OUTER APPLY for CashoutStatusID IN (1,14) | Confirm these are the correct status IDs for "prepared by" attribution — is ID=14 (Pending Review) the right second status? |

## Known Data Quality Issues

- **"System  " trailing space**: The CONCAT in the SP produces "System " (with trailing space) because the system account's LastName is blank. Analysts should use LTRIM/RTRIM when grouping by [Prepared By].
- **UpdateDate identical across rows**: All rows share the same UpdateDate (ETL run timestamp from GETDATE()). This is by design — not a bug.
- **Column names with spaces**: 4 of 6 columns require double-bracket quoting in SQL (`[[Column Name]]`). This is an ETL anti-pattern but baked into the DDL.

## No Tier 4 Items

All columns have confirmed sources from live data sampling and SP analysis.
