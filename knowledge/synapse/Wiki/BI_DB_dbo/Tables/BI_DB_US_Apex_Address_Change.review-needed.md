# BI_DB_dbo.BI_DB_US_Apex_Address_Change — Review Needed

## Tier 4 Items (Unverified)

- None — all columns traced to SP code and DWH/USABroker sources.

## Questions for Reviewer

1. **PII handling**: This table contains FirstName, LastName, Address, City, State, PreviousState, Previous_Address, PreviousCity — confirm access controls are in place.
2. **Dim_Range usage**: The SP uses Dim_Range.FromDateID with a ToDateID >= @DateID filter — this tracks the customer's DateRange at the time of snapshot. Confirm this correctly identifies the change date vs the snapshot date.
3. **Apex LEFT JOIN**: ~6% of rows have empty ApexStatus — these customers may not have an Apex account. Should they be included?

## Cross-Object Consistency Notes

- CID, GCID, FirstName, LastName descriptions inherited verbatim from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic).
- Address/City from Fact_SnapshotCustomer kept at Tier 2 (SP transform via LAG).
