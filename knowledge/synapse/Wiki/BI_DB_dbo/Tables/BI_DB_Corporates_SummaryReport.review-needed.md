# BI_DB_Corporates_SummaryReport — Review Needed

**Batch**: 20 | **Generated**: 2026-04-21 | **Reviewer**: Pending

## Tier 4 Items (Unverified — need confirmation)

None. All columns traced to confirmed sources (SP code, DWH wikis).

## Questions for Domain Expert / Reviewer

1. **ApprovedDateTime semantics**: The SP derives this as MIN(Dim_Date.FullDate) for the first Dim_Range snapshot with AccountTypeID IN (2,14). Is this actually used as the "corporate account approval date" in business reporting? Or is there a more authoritative approval timestamp in BackOffice?

2. **TotalDeposits cumulative scope**: TotalDeposits sums ALL approved BI_DB_AllDeposits regardless of date. Is this intentional — i.e., should analysts always use this as "lifetime deposits" and never compare it to Balance/TotalEquity (which is point-in-time)?

3. **PlayerStatus trailing spaces**: varchar(max) values from Dim_PlayerStatus.Name appear with trailing spaces in live data (e.g., "Blocked                                            "). Is this a known issue? Should RTRIM be applied in the SP?

4. **AccountType drift (57 accounts)**: 57 accounts appear in this table despite no longer having AccountTypeID 2 or 14. Is this expected (accounts changed type but remain in scope for corporate monitoring)? Should the SP add a WHERE clause to exclude them, or is this intentional?

5. **V_Liabilities join**: The SP LEFT JOINs V_Liabilities on `vl.CID = c.RealCID AND vl.DateID = @EndDateID`. If V_Liabilities doesn't have a row for a given customer/date, Balance and TotalEquity default to 0. How common is this? Are these excluded from corporate reporting dashboards?

## Potential Data Quality Issues

- **Trailing spaces in status fields**: PlayerStatus and PlayerLevel are varchar(max) from denormalized DIM lookups — may have inconsistent trailing whitespace. RTRIM recommended in downstream queries.
- **GCID NULL for old accounts**: Older accounts (pre-GCID introduction) have GCID=NULL. Reports requiring unique customer identification should use RealCID, not GCID.
- **AccountType non-corporate rows**: 57 rows (~1.2%) with non-Corporate/SMSF current AccountType. May distort aggregations if AccountType is used as a filter.

## Correction Log

*(Empty — no corrections yet)*
