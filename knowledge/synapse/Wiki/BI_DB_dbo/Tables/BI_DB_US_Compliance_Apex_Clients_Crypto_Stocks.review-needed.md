# Review Needed: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks

## Tier 4 Items

No Tier 4 items in this wiki.

## Questions for Reviewer

1. **Population mismatch**: This table includes ALL US depositors (431K) while the parent compliance table filters to VL3+closed/Reg8 (403K). Is this intentional? The two tables don't have a 1:1 relationship — some CIDs in Crypto_Stocks won't match to the compliance table.
2. **CashInCopy negative values**: TotalCash - Credit can go negative. Is this expected behavior or a data quality issue?
3. **V_Liabilities date parameter**: The SP uses @Date (typically yesterday). Confirm this aligns with the compliance team's reporting expectations.

## Cross-Object Consistency

- `CID` description matches Dim_Customer wiki and BI_DB_US_Compliance_Apex_Clients wiki verbatim.
- `AccountStatusName` description matches Dim_AccountStatus wiki verbatim.
- `Address_State` description matches Dim_State_and_Province wiki verbatim.

## Reviewer Corrections

None yet.
