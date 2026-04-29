# Review Needed: BI_DB_dbo.BI_DB_Q_AML_EDD_US_Report

## Tier 4 Items

- **External_RiskClassification_dbo_V_RiskClassificationDataLake**: No upstream wiki exists for this external source. RiskScoreName and RiskScore_Explanation descriptions are inferred from live data.
- **BI_DB_AML_Documents_Request**: Depends on this BI_DB table for document flags. If that table's semantics change, document flags here may break.
- **BI_DB_AML_PlayerStatus_Changes**: Last status change logic excludes Current_ID IN (2,4). What are these specific status IDs? Need Dim_PlayerStatus mapping.
- **Dim_Regulation DWHRegulationID vs ID**: SP joins on `fsc.RegulationID = dr1.DWHRegulationID` -- uses DWHRegulationID, not ID. These map to 7=FinCEN, 8=FinCEN+FINRA.

## Questions for Reviewer

1. Who is the business owner of this AML EDD report? No author header in the SP.
2. Why are PlayerLevelID (2,6,7) = Platinum+ the only tiers included? Is EDD required for all high-risk customers or only high-tier ones?
3. The SP has no author metadata -- when was it created and by whom?
4. Active_Dep_or_CO and Active_Trade_or_Loggedin use LEFT JOIN and CASE WHEN IS NOT NULL. For older Report_Dates (Q4 2024), some rows show NULL for these columns. Were these columns added later?

## Confidence Notes

- PII columns (FirstName, MiddleName, LastName) are Tier 1 from Customer.CustomerStatic via Dim_Customer
- Country, POB_Country, Club, HasWallet, RegisteredReal are Tier 1 via dim lookups
- Most other columns are Tier 2 (computed or from BI_DB/external sources without upstream wikis)
- The 40 columns span 18+ source objects -- this is one of the most complex BI_DB reports
