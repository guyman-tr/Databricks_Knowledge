# DWH_dbo.Dim_ActionType — Review Needed

## Production Source Unknown

- No writer SP found in DWH_dbo for this table.
- Data arrives via DWH_Migration staging table (varchar-typed columns) and is loaded by the Generic Pipeline.
- The original production source is unknown — likely a manually-maintained or application-managed lookup table from the trading platform (possibly `Trade.ActionType` or similar in etoroDB).
- **Action needed**: Identify the production database and table that owns the ActionType enumeration. Once found, update lineage to Tier 1.

## No Upstream Wiki

- `_no_upstream_found.txt` marker is present.
- All 6 columns are Tier 3 — grounded in DDL + live data evidence, but no upstream documentation exists.
- If an upstream wiki is created for the source table, all columns should be re-evaluated for Tier 1 inheritance.

## Data Quality Notes

- **ActionTypeID=33 is missing**: Gap in the ID sequence (0-32, 34-45). Verify whether this is intentional (deleted action type) or a data issue.
- **Typos in Name column**: "Recived" (IDs 24-26) should be "Received". These appear to be legacy typos in the source data.
- **Double spaces**: Several Name values contain double spaces ("Unregister  mirror", "Publish  Post"). Inconsistent with other values.
- **CategoryID overlap**: Cashout (ID=8, CategoryID=4) and InternalWithdraw (ID=45, CategoryID=4) share the same CategoryID but have different Category strings ("Cashout" vs "Withdraw"). Verify this is intentional.

## Staleness Risk

- UpdateDate/InsertDate values are from 2013-2014, suggesting the table has not been modified since initial seeding.
- Confirm whether the table is still actively used or if it has been superseded by a newer action type system.
