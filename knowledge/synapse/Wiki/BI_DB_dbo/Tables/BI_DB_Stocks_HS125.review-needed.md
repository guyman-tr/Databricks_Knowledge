# BI_DB_dbo.BI_DB_Stocks_HS125 — Review Needed

## Tier 4 / Unverified Items

- None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **Hedge servers 125, 9, 3**: These appear in the SP filter (`HedgeServerID IN (125,121,126,112,130,128,9,3,102,124)`) but have zero rows in recent data. Are they decommissioned or intermittently active?
2. **Symbol vs Name**: The SP maps `Dim_Instrument.Name AS Symbol` rather than `Dim_Instrument.Symbol`. Is this intentional or a legacy naming choice? The values may differ for some instruments.
3. **UC migration status**: This table is not in the Generic Pipeline mapping. Is UC migration planned?

## Corrections Applied

- None.

## Atlassian

- Atlassian search unavailable (permission denied). No Confluence/Jira context applied.
