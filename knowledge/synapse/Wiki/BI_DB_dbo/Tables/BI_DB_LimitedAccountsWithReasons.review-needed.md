# Review Needed — BI_DB_dbo.BI_DB_LimitedAccountsWithReasons

Generated: 2026-04-22 | Batch: 29

## Tier 4 / Unresolved Items

| Column | Issue | Action Needed |
|--------|-------|---------------|
| CashoutStatus | Values observed as empty in sample (not NULL, but empty string). Distribution not captured — need to understand all Dim_CashoutStatus.Name values for restricted wire cashouts. | Reviewer: confirm expected CashoutStatus values for pending wire cashouts |
| PlayerStatusSubReason | NULL in most rows in sample. Full list of valid values not verified — Dim_PlayerStatusSubReasons not fully explored. | Reviewer: confirm SubReason values, especially for AML bucket |
| Tickets | Mechanism relies on BI_DB_SF_Cases (CID + CreatedDate). BI_DB_SF_Cases is not yet documented in this wiki project — its schema, refresh, and completeness are unknown. | Reviewer: confirm BI_DB_SF_Cases is still active and SF case sync is current |

## Known Data Quality Issues

1. **DDL Typos**: `LastLoggeedIn` (double 'e') and `PlayerStatusReasoon` (double 'o') are permanent column name typos present in both DDL and SP INSERT statement. Cannot be fixed without DDL ALTER + SP change.

2. **Balance/Equity Naming Inversion**: `Balance` = Credit (cash), `Equity` = Liabilities + ActualNWA (total equity). The names appear swapped relative to finance convention.

3. **BlockedTime NULL Risk**: Customers restricted before Fact_SnapshotCustomer coverage will have NULL BlockedTime and NULL TimeBucket. Prevalence unknown.

4. **Cashouts Logic Scope**: Cashout check uses FundingTypeID=19 (wire transfers) only. Non-wire cashouts are excluded. This may undercount cashout activity for non-wire jurisdictions.

5. **6-Month Filter Removed (2024-11-05)**: The original filter `WHERE DATEADD(MONTH, -6, GETDATE()) <= BlockedTime` was removed. Historical long-blocked customers are now included — analysts who relied on the old behavior should be aware.

## Open Questions

- Is `RiskGroupID` at the country level clearly understood by operations teams (vs. assuming it's customer risk)?
- Are there additional PlayerStatusIDs that could appear beyond the 6 currently observed (5, 9, 10, 12, 13, 15)?
- Is the `V_BI_DB_LimitedAccountsWithReasons_COPY_BI_DB` view still actively used or deprecated?

## Upstream Wiki Coverage

| Source | Wiki Exists? | Tier 1 Columns Inherited |
|--------|-------------|--------------------------|
| Customer.CustomerStatic | Yes (via Dim_Customer.md) | CID, PlayerStatusID |
| Dictionary.Country | Yes (via Dim_Country.md) | Country, RiskGroupID |
| BI_DB_CIDFirstDates | Yes (documented Batch 2) | CID (relay) |
