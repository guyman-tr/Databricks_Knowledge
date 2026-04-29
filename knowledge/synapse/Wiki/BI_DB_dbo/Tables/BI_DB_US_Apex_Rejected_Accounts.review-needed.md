# BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts — Review Needed

## Tier 4 Items (Unverified)

- None — all columns traced to SP code and DWH/USABroker sources.

## Questions for Reviewer

1. **DesignatedRegulationID vs RegulationID**: The SP filters on DesignatedRegulationID=8, but the output column is RegulationID (primary regulation). Should the output show DesignatedRegulationID instead, or both?
2. **ErrortDate typo**: The column is named `ErrortDate` (double 't') in the DDL — is this intentional or should an ALTER fix the name?
3. **V_Liabilities**: What does the Liabilities value represent specifically? Total cash owed, margin requirements, or pending withdrawals?
4. **CipCheckRejectedBySketch**: The second most common validation error (14%) — "Sketch" likely refers to an identity verification vendor. Confirm vendor context.
