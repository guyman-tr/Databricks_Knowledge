# BI_DB_dbo.BI_DB_Tax_Reports_Status — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **No upstream wiki for FinanceReports**: The FinanceReports database does not have a production wiki. FromUtc, TillUtc, and ReportStatusID descriptions are derived from SP code analysis only (Tier 2). If a FinanceReports wiki is built, these columns should be upgraded to Tier 1.
2. **ReportStatusID values 5 and 6**: Both map to 'Completed'. What distinguishes them? Possibly 5=generated, 6=delivered? The SP comments don't clarify.
3. **Country list expansion**: The SP has been updated 3 times (2024, 2025, 2026) to add countries. The 2026 update adds "all countries for filtering in the dashboard." Historical data before these updates may not include all countries.
4. **No UC mapping**: This table does not appear in the Generic Pipeline mapping. Confirm whether it should be exported to Unity Catalog.

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- Country description matches DWH_dbo.Dim_Country.Name (Tier 1 — Dictionary.Country) ✓
