# Review Needed: BI_DB_dbo.BI_DB_ProfessionalCustomers

## Tier 4 Items

- **Desk column**: Currently not populated by SP (commented out). Historical data present but stale. Unclear when/why it was disabled. May require checking git history for SP_ProfessionalCustomers.
- **ThirdParty_Fivetran source**: The SP has commented-out code referencing `[ThirdParty_Fivetran].[Fivetran].[gsheets].[customer_managers]` for desk data. This integration may have been deprecated or moved elsewhere.

## Questions for Reviewer

1. Is the Desk column intentionally deprecated? Should it be removed from the DDL?
2. Is there a replacement source for desk assignment (the commented-out Fivetran/GSheets integration)?
3. The table only contains 'Approved' rows -- is there a companion table tracking 'Cancelled' professional status transitions?

## Confidence Notes

- RealCID is the only Tier 1 column (passthrough from Fact_SnapshotCustomer, origin Customer.CustomerStatic)
- All other columns are Tier 2 (ETL-computed by SP_ProfessionalCustomers)
- The stale Desk column is a data quality concern for consumers who may be using it without knowing it's no longer refreshed
