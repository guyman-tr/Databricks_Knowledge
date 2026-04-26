# BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2) or upstream Dim_Customer wiki (Tier 1).

## Questions for Reviewer

1. **Tableau artifact columns**: 5 duplicate CID columns (RealCID_Custom_SQL_Query1, CID_Custom_SQL_Query2, CID_Custom_SQL_Query1_1, CID_Custom_SQL_Query1_2, plus RealCID = CID). Can any be deprecated?
2. **FinalTaxedlnterest typo**: Column name has lowercase 'l' not uppercase 'I'. Inherited from BI_DB_InterestMonthly and ultimately from the Interest production system.
3. **Column count**: DDL has 46 columns, batch assignment said 47. Verified: 46 in both DDL and INSERT.
4. **INNER JOIN on #interest_daily**: Customers in BI_DB_InterestMonthly but NOT in BI_DB_InterestDaily for that month are excluded. Is this intentional or a data gap?
5. **UC migration**: Table is _Not_Migrated — no entry in generic pipeline mapping. PII fields (masked) may be a blocker for UC export.
6. **Tax data completeness**: LEFT JOINs on #tax and #TaxRequirement mean some customers have NULL tax fields. Is FieldId=6 the correct filter for all regulation-required tax IDs?

## Corrections Applied

- Column count corrected from 47 to 46.

## Cross-Object Consistency

- CID, RegulationID, StatusID, MonthOfInterest, MonthlyAccumulatedInterest, TaxPercentage, FinalTaxedlnterest, ValidFrom descriptions aligned with BI_DB_InterestMonthly wiki (Tier 2 inherited).
- RealCID, FirstName, LastName, MiddleName, UserName, BirthDate, City, Address, Zip, BuildingNumber, Gender descriptions aligned with Dim_Customer wiki (Tier 1 inherited).
