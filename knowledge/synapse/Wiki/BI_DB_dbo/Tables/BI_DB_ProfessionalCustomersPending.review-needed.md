# Review Needed: BI_DB_dbo.BI_DB_ProfessionalCustomersPending

## Tier 4 Items

- **SelectedCriteria > 1 filter**: The SP filters applications where SelectedCriteria > 1. Unclear what this field represents exactly (likely number of professional criteria met: trading volume, portfolio size, work experience). SelectedCriteria = 1 might indicate incomplete applications.
- **Desk column**: Same stale/deprecated issue as BI_DB_ProfessionalCustomers.

## Questions for Reviewer

1. What does SelectedCriteria represent in the External_BI_OUTPUT_Customer_ProfessionalCustomers source? How many criteria are available?
2. Is the 6-month lookback intentional policy? Should older pending applications be tracked somewhere?
3. Same Desk deprecation question as BI_DB_ProfessionalCustomers.

## Confidence Notes

- RealCID is Tier 1 (passthrough from Fact_SnapshotCustomer.RealCID, origin Customer.CustomerStatic)
- ClubTier is Tier 1 (dim-lookup passthrough from Dim_PlayerLevel.Name, origin Dictionary.PlayerLevel)
- Country is Tier 1 (dim-lookup passthrough from Dim_Country.Name, origin Dictionary.Country)
- DaysSinceApplication is Tier 2 (ETL-computed DATEDIFF)
