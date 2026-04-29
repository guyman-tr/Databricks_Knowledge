# Review Needed: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients

## Tier 4 Items

No Tier 4 items in this wiki.

## Questions for Reviewer

1. **Q30 AnswerId mapping**: AnswerId values 93=Shareholder, 94=Broker Employee, 95=Public Official, 96=None Apply — these are extracted from SP code. Confirm these AnswerId values are stable and not environment-dependent.
2. **Population completeness**: The filter requires VL3 AND (closed-US OR active-US-Reg8). Are there US compliance scenarios where VL2 or VL1 accounts should also be tracked?
3. **ApexID format**: Observed "3" prefix + alphanumeric (e.g., "3FN28343", "3ES62365", "3EX34652"). Confirm this is the standard Apex ID format or if other prefixes exist.

## Cross-Object Consistency

- `CID` / `GCID` descriptions match Dim_Customer wiki verbatim.
- `Address_Country` / `Citizenship` descriptions match Dim_Country wiki verbatim.
- `AccountStatusName` description matches Dim_AccountStatus wiki verbatim.
- `Regulation` / `DesignatedRegulation` descriptions match Dim_Regulation wiki verbatim.
- `ApexID` / `ApexStatus` / `ApproverName` / `ApexApprovedDate` descriptions sourced from USABroker upstream wikis.

## Reviewer Corrections

None yet.
