# BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2).

## Questions for Reviewer

1. **Balance_Group CASE bug**: Lines 101-102 in SP both test `nb.Balance >= -500`. The second condition ("Less than -500 USD") is unreachable — those values fall to ELSE "Check". Live data confirms 5,107 rows with "Check". Should the second condition be `nb.Balance >= -5000` or `nb.Balance < -500`?
2. **Funded column JOIN bug**: `bddcl.DateID = vl.CID` compares a date ID to a customer ID. This is almost certainly a bug — should likely be `bddcl.DateID = vl.DateID`. Results in 97.5% NULL for Funded.
3. **BI_DB_DDR_CID_Level dependency**: This table is on the explicit blacklist (scheduled for decommission). The Funded column will break when DDR_CID_Level is removed.
4. **Commented-out More_than_30Days_ind**: The original More_than_30Days_ind logic (lines 46, 61-62) using a direct V_Liabilities self-join is commented out. The replacement uses a temp table self-join. Was the commented version the intended approach?
5. **UC migration**: Table is _Not_Migrated. Small aggregated table suitable for UC export.

## Corrections Applied

None.

## Cross-Object Consistency

- All columns are ETL-computed aggregations (Tier 2). No upstream wiki inheritance applicable.
