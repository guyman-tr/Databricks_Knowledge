# BI_DB_D_HighRedeemsApprovalForManagement — Review Needed

**Batch**: 20 | **Generated**: 2026-04-22 | **Reviewer**: Pending

## Tier 4 Items (Unverified — need confirmation)

None. All columns traced to confirmed SP code and source tables.

## Questions for Domain Expert / Reviewer

1. **CRITICAL — Hardcoded DateID=20230504 in V_Liabilities join**: SP line 214 reads `LEFT JOIN [DWH_dbo].[V_Liabilities] V ON V.CID=a.CID AND DateID=20230504`. This means NWA, Balance, and Equity always reflect May 4, 2023 values — never updated regardless of when the SP runs. Confirmed in live data: NWA=0 for all current rows; Balance/Equity NULL for one customer (no V_Liabilities row at that date). **Is this a known bug or intentional?** If intentional, what is the business reason for freezing financial data to May 2023? If a bug, should it be changed to `DateID=@dayID`?

2. **NWA = V_Liabilities.BonusCredit**: The column is labeled "NWA" (Net Worth Attribution) but sources V_Liabilities.BonusCredit (bonus/credit balance). In other contexts (e.g., BI_DB_Corporates_SummaryReport), NWA-equivalent metrics use Liabilities+ActualNWA. Is BonusCredit the correct field for NWA in this management report, or should it use V_Liabilities.ActualNWA instead?

3. **$50,000 threshold hardcoded in HAVING clause**: The `HAVING sum(ValueEOD) > 50000` threshold is hardcoded in the SP with no parameter. Has this threshold ever been reviewed? Is it still the correct approval threshold for management oversight of high redeems in 2026?

4. **WasContactedLast12Months joins BI_DB_UsageTracking_SF — what is this table?**: The SP joins `BI_DB_UsageTracking_SF` on CID for ActionName='Phone_Call_Succeed__c'. Is BI_DB_UsageTracking_SF a Salesforce CRM sync table? Is it populated daily, or could there be a lag between a phone call being logged in SF and appearing here?

5. **Revenues = lifetime CommissionOnClose — is this correct scope?**: The Revenues column aggregates ALL closed position commissions from Dim_Position for the customer's entire history — not just commissions related to the pending redeems or for a specific period. Is this the intended metric for the management approval report (customer lifetime value), or should it be scoped to a time window (e.g., last 12 months)?

6. **ProvidedSelfie uses DocumentTypeID=15 — is this the current selfie type?**: The selfie check uses `dtdt.DocumentTypeID=15`. If the BackOffice document type system has been updated or if selfie document types have changed since 2021, this filter may miss newer selfie records. Can the BackOffice team confirm that DocumentTypeID=15 still represents selfie/liveness documents in the current BO system?

## Potential Data Quality Issues

- **Stale NWA/Balance/Equity (hardcoded DateID=20230504)**: These three columns are frozen to May 4, 2023 financial data. Any analysis using these fields for current financial risk assessment will be wrong. For current financial position, query V_Liabilities directly with the current date.
- **NULL Balance/Equity**: Customers who had no V_Liabilities record on 2023-05-04 return NULL for Balance and Equity (no ISNULL wrapper, unlike NWA). Downstream computations must handle these NULLs explicitly.
- **AMLComment/RiskComment case-sensitivity**: Empty comments are stored as '' not NULL. String comparisons and ETL loads must handle this convention.
- **Age precision**: DATEDIFF(year,...) counts year boundaries crossed, not full years. A customer born on December 31 will show age+1 on January 1, even though they are only 1 day into their new year.

## Correction Log

*(Empty — no corrections yet)*
