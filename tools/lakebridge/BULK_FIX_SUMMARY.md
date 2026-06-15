# Bulk fix + deploy of failed Stored Procedures

## Headline

|                              | Count |
|------------------------------|------:|
| SPs in transpiled output     |   127 |
| Originally deployed (bulk)   |    42 |
| Surgical-fixed (sp_dim_customer + dl) | 2 |
| **Bulk-fixer wins (this pass)** | **9** |
| **Total now in UC**          | **53** |
| Still failing                |    74 |

A bulk fixer (`bulk_fix_deploy_sps.py`) was built on top of the existing
`fix_and_deploy_sp_dim_customer*` fixers. It applies:

- Backticked-type unwrap (`` `string` `` → `STRING`)
- `IMMEADIATE` typo fix
- `SET VARIABLE`/`DECLARE VARIABLE` keyword cleanup
- `cast(<expr> TYPE)` → `cast(<expr> AS TYPE)` with paren-aware walk
- `END IF` → `END IF;`
- Comment-out of unsupported `EXEC sp_executesql`
- Conservative line-start statement-keyword semicolon injector
- All 17 fixers inherited from sp_dim_customer (typed COALESCE, MERGE
  dedupe, COLLATE strip, EXIT HANDLER strip, WITH-clause strip, etc.)

## What's in UC now

```
dwh_daily_process.migration_tables  →  53 procedures
```

New SPs added by the bulk fixer pass:

1. `sp_check_dim_instrument_correlation_differences`
2. `sp_killtableausessions`
3. `sp_dictionaries_dl_to_synapse`
4. `sp_dim_customer_20240104`
5. `sp_fact_regulationtransfer_dl_to_synapse`
6. `sp_test_externaltointernal`
7. `sp_dim_position_hedgetype_history`
8. `sp_fact_customeraction_checkexistpartition`
9. `sp_fact_customeraction_isparitalcloseparent`

## Residual 74 failures by business priority

| Bucket | Count | Migration-critical? |
|---|---:|---|
| **CRITICAL** (writes to one of the 40 main.* mirror-gap tables) | 10 | YES — must fix |
| **BUSINESS** (other Dim_/Fact_ logic + `_DL_To_Synapse` loaders)  | 24 | YES — should fix |
| BACKUP (`_bkp_*`, `_OLD_VER`, `_Eyal`, `JUNK_*`, `_20240507`) | 12 | NO — historical |
| TEST (`SP_Test_*`, `SP_Check_*`) | 2 | NO — non-prod |
| INFRA (Synapse-only: CopyInto, DropTable, AddPartitions, Parquet, ColumnstoreMaintenance, KillTableau, AlterWorkload, DBA_*) | 20 | NO — not applicable to Delta/UC |
| OTHER (BI_DB stub, NOC_LiabilitiesChange, SWITCH ops) | 6 | mixed |

**Real outstanding work: ~34 SPs.** The other 40 are dead code or Synapse-only
infrastructure that doesn't need to exist in Unity Catalog.

### CRITICAL list (10) — must work for the migration cutover

```
DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate.sql
DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_DeleteByDateRange.sql
DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour.sql
DWH_dbo.SP_Dim_Instrument_Correlation_Half_Records.sql
DWH_dbo.SP_Fact_CustomerAction_SWITCH.sql
DWH_dbo.SP_Fact_Position_Futures_Snapshot.sql
DWH_dbo.SP_Fact_SnapshotCustomer.sql
DWH_dbo.SP_Fact_SnapshotCustomerCloseYear.sql
DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse.sql
DWH_dbo.SP_Fact_SnapshotEquity_TotalPositionAmount.sql
```

### BUSINESS list (24)

```
DWH_dbo.SP_Dim_Instrument_Correlation.sql
DWH_dbo.SP_Dim_Instrument_Correlation_Build_GroupsInstruments.sql
DWH_dbo.SP_Dim_Instrument_Correlation_ByGroupRange.sql
DWH_dbo.SP_Dim_Instrument_Correlation_FilterByInstrumentID.sql
DWH_dbo.SP_Dim_Mirror_DL_To_Synapse.sql
DWH_dbo.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse.sql
DWH_dbo.SP_Dim_Position_DL_To_Synapse.sql
DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog.sql
DWH_dbo.SP_Fact_BillingDeposit.sql
DWH_dbo.SP_Fact_BillingDeposit_DL_To_Synapse.sql
DWH_dbo.SP_Fact_BillingWithdraw.sql
DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse.sql
DWH_dbo.SP_Fact_CustomerAction.sql
DWH_dbo.SP_Fact_CustomerAction_Create_SWITCH_SINGLE.sql
DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse.sql
DWH_dbo.SP_Fact_CustomerUnrealized_PnL.sql
DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse.sql
DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0.sql
DWH_dbo.SP_Fact_FirstCustomerAction.sql
DWH_dbo.SP_Fact_FirstCustomerAction_DL_To_Synapse.sql
DWH_dbo.SP_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK.sql
DWH_dbo.SP_Fact_Guru_Copiers.sql
DWH_dbo.SP_Fact_History_Cost.sql
DWH_dbo.SP_Fact_RegulationTransfer.sql
```

## Why bulk regex hit a wall

The 74 remaining errors fall into a few structural categories that cannot
be cleaned up by line-level regex without proper SQL parsing:

1. **Broken `WHILE` loops** — BladeBridge translates the T-SQL form `WHILE
   <cond> BEGIN ... END` but emits the body without a matching block, so
   the parser hits `WHILE` mid-statement.
2. **Dynamic SQL** (`EXEC sp_executesql N'...'`) — used inside `CopyInto*`,
   `DropTable`, `Truncate*`, `AddPartitions*`. Has no clean Databricks
   equivalent.
3. **`CROSS APPLY OpenJson(...)`** — `CreateParquetCopyTableFromjson*` uses
   T-SQL JSON shredding; needs hand-rewrite to `LATERAL VIEW` + `from_json`.
4. **Output parameters** (`OUT V_x INT`) — Databricks SQL Procedures support
   only `IN`. The 3 `near 'OUT'` failures all use this pattern.
5. **Multiple SELECTs without terminator** — typical inside `SP_Fact_*`
   bodies where BladeBridge places multiple SELECT/INSERT/MERGE next to
   each other; the conservative semicolon injector helps but can't recover
   when the body has WHILE/IF blocks that themselves are malformed.
6. **Mid-procedure DDL** — `CREATE TABLE` / `DROP TABLE` inside a
   `BEGIN..END` block requires `EXECUTE IMMEDIATE` in Databricks. Affects
   `BI_DB_dbo`, `SP_AlterWorkLoadGroup`, `SP_DWH_Status` (uses dynamic
   schema introspection).

## Recommended next steps

1. **Drop the 40 dead SPs** (BACKUP + TEST + INFRA). Don't waste cycles on:
   - 12 backup/junk SPs — no semantic value, just historical curiosity
   - 2 test SPs — keep code but don't deploy
   - 20 infra SPs — replace conceptually with Delta/UC equivalents
     (partition discovery is automatic in Delta; CopyInto is `COPY INTO`
     Delta; KillTableauSessions has no analog; etc.)

2. **Surgical-fix the 10 CRITICAL SPs** using the `fix_and_deploy_sp_dim_customer.py`
   template. Each gets its own short script that imports the shared `base`
   fixers and adds 1–3 SP-specific patches. The pattern works; we proved
   it with `sp_dim_customer` and `sp_dim_customer_dl_to_synapse`.

3. **Apply the same pattern to the 24 BUSINESS SPs** afterwards.

Estimated effort: roughly 1–2 hours per SP for the first few until we
extract more reusable fixers; later ones go faster as the shared library
grows.

## Artifacts

- `tools/lakebridge/bulk_fix_deploy_sps.py` — the bulk fix+deploy harness
- `tools/lakebridge/bulk_fix_output/` — every transpiled-and-fixed SQL file
  for inspection / diff against the v3 raw transpiler output
- `tools/lakebridge/bulk_fix_deploy_report.csv` — per-SP outcome
  (`ok` / `error` / `skip` with full error string)
- `tools/lakebridge/_bucket_errors.py` — quick error-pattern bucketing
- `tools/lakebridge/_categorize_remaining.py` — priority bucketing script
