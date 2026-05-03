# Review Needed: BI_DB_dbo.Synapse_Table_etoro_History_DepositAction

## 1. Upstream Wiki Discovery

- The regen harness `_no_upstream_found.txt` marker was present, but a rich upstream wiki WAS found independently at `DB_Schema/etoro/Wiki/History/Tables/History.DepositAction.md` (9.1/10 quality, all 23 columns documented).
- All 23 columns are direct passthroughs from production `etoro.History.DepositAction` via Bronze parquet COPY INTO. All assigned Tier 1.
- **Action**: Consider updating the harness lineage resolver to detect `Synapse_Table_etoro_*` naming pattern and map to corresponding production tables.

## 2. UC Target

- Table is marked `_Not_Migrated` — no Unity Catalog target exists.
- The Bronze source IS mapped in Generic Pipeline (ID 959): `general.bronze_etoro_history_depositaction`.
- **Action**: Confirm whether this Synapse landing table needs a separate UC target or if the Bronze UC table is sufficient.

## 3. Ephemeral Nature

- This table is dropped and recreated daily by `SP_Create_Synapse_Table_etoro_History_DepositAction`. It holds only one day of data at a time.
- **Action**: Verify whether this table should be documented as a persistent object or flagged as a transient staging artifact.

## 4. Type Widening

- Several columns have wider types in Synapse than production: `ApprovalNumber` (varchar(20) -> varchar(max)), `AuthCode` (varchar(20) -> varchar(max)), `Remark` (varchar(255) -> varchar(max)), `MatchStatusID` (tinyint -> int). This is due to `AUTO_CREATE_TABLE = 'ON'` in the COPY INTO command inferring types from parquet.
- **Action**: No functional impact, but worth noting for downstream consumers expecting specific type constraints.

## 5. SP_H_Deposits Uses External Table Variant

- `SP_H_Deposits` uses `External_etoro_History_DepositAction_Yesterday` (external table pointing at a fixed date) rather than this Synapse table. The two tables serve the same purpose but are loaded differently.
- **Action**: Confirm whether `SP_H_Deposits` should be migrated to use the Synapse table instead of the external table.

---

*Generated: 2026-04-30 | Reviewer: Pending*
