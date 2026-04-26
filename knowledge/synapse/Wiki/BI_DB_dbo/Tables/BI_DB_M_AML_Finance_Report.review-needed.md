# Review Needed: BI_DB_dbo.BI_DB_M_AML_Finance_Report

## Tier 4 Items (Needs Verification)

- None. All columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **DDR dependency**: The SP JOINs to `BI_DB_DDR_CID_Level` with `Funded_New_Def=1`. This table is on the explicit blacklist (deprecated). If DDR_CID_Level is decommissioned, this SP's population filter will break. Is there a replacement funding flag?
2. **INNER JOIN on Fact_CustomerAction**: The login lookup uses INNER JOIN via GROUP BY, meaning customers who have never logged in are excluded entirely. Is this intentional, or should the join be LEFT to include zero-login customers?
3. **Large table growth**: At ~3.5M rows/month, the table grows by ~42M rows/year with no apparent archival. Current size: 102M rows. Is there a retention policy?
4. **V_Liabilities view**: The equity calculation depends on `V_Liabilities`. If this view definition changes, the equity values may shift without the SP code changing.

## Cross-Object Consistency

- CID: consistent with BI_DB_dbo convention (int, from Fact_SnapshotCustomer.RealCID)
- Regulation values: 11 distinct at latest month — superset of AML_Account_Closed (includes MAS, NYDFS+FINRA, None)
- Related to BI_DB_M_AML_Account_Closed (same AML domain, different perspective: this is active population, that is blocked population)

## Corrections Applied

- None.
