# Review Needed: DWH_dbo.Dim_MoveMoneyReason

## Data Staleness — CRITICAL

- **DWH has only 4 rows** (IDs 1-4) while production `Dictionary.MoveMoneyReason` documents at least 9 reason codes (IDs 1-3, 5-9).
- Missing from DWH: InternalTransfer Trade (5), InternalTransfer (6), Not In Use (7), Recurring Deposit (8), Recurring Investment (9).
- ID 4 = "Airdrop" exists in DWH but is **not documented** in the upstream production wiki (which noted ID 4 as missing/deprecated). This may indicate a production schema change since the upstream wiki was last updated (2026-03-14).
- All `UpdateDate` values are from **2022** — the Generic Pipeline may not be actively refreshing this table, or the source rows have not changed.

**Action needed**: Verify whether the Generic Pipeline is still syncing this table. Check if IDs 5-9 were intentionally excluded or if the staging load has an issue.

## No Writer SP Found

- No dedicated stored procedure in `DWH_dbo` writes to `Dim_MoveMoneyReason`.
- The table appears to be loaded by the generic dictionary pipeline from `DWH_staging.etoro_Dictionary_MoveMoneyReason`.
- The staging table has only 2 columns (MoveMoneyReasonID, MoveMoneyReason) — `UpdateDate` is added during the ETL load process, but the mechanism is not visible in any SP code.

## Nullable PK

- `MoveMoneyReasonID` is defined as `NULL` in the DDL despite serving as the clustered index key and logical primary key. This is a DDL hygiene issue — consider adding a NOT NULL constraint.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | MoveMoneyReasonID, MoveMoneyReason |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
