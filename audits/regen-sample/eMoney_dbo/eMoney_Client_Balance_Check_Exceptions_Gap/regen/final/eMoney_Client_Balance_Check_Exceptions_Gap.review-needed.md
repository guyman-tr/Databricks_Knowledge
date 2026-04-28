# Review Needed: eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

## Summary

Low-complexity alert table with 3 columns, all Tier 2 (ETL-computed). No Tier 1 inheritance applicable — all columns are aggregated or derived by the SP, not passthroughs.

## Items for Human Review

### 1. UC Migration Status

- Table is marked `_Not_Migrated`. Confirm whether this alert table needs a Unity Catalog target or if it remains Synapse-only.

### 2. Historical Exception Tracking

- The TRUNCATE + INSERT pattern means only the latest run's exceptions survive. If historical exception tracking is needed, this table's design would need to change (append-only instead of truncate).
- Confirm with the eToro Money finance team whether exception history is tracked elsewhere (e.g., external monitoring, Jira alerts).

### 3. Empty Table Confirmation

- Table currently has 0 rows. This is expected behavior (no exceptions on latest run), not a data quality issue. Confirmed via live sampling on 2026-04-27.

### 4. UpdateDate Semantics

- `UpdateDate` in this table is the `@Date` SP parameter (business date), NOT `GETDATE()` like in the parent `eMoneyClientBalance` table. This naming inconsistency may confuse analysts. Consider documenting prominently or renaming.
