# Bad $1 FTD Cohort — One-Shot Historical Demotion Scripts

**Ticket**: REQ-25250
**PR**: [#3875](https://github.com/eToroX-Labs/DataPlatform/pull/3875)
**Status**: Built. Tested on Synapse **dev** pool. **Not yet run in production.**

## What this folder does

Going-forward, the patched SPs (already in PR #3875 / deployed to UC) demote
the bad cohort on every rebuild. These five scripts clean up the **historical
rows** that were written before the patches landed.

Two bad-FTD events, six dates total:

| Cohort      | Dates                              | Cohort size |
|-------------|------------------------------------|-------------|
| Aug 2025    | 2025-08-18, 2025-08-19, 2025-08-20 | ~13,302     |
| May 2026    | 2026-05-22, 2026-05-23, 2026-05-25 | ~17,678     |
| **Total**   |                                    | **~30,985** |

Cohort definition: `Dim_Customer.FirstDepositDate` ∈ the 6 dates above
AND `FirstDepositAmount = 1` AND has NOT subsequently made any legitimate
deposit (excluded via the NOT EXISTS on multi-deposit CIDs).

Materialised in UC as `main.etoro_kpi_prep.v_bad_ftd_cohort`.
Synapse scripts re-derive the cohort inline (no UC dependency).

## Scripts in this folder

### Synapse (run in `sql_dp_prod_we`)

| # | Script | Target | Estimated rows |
|---|--------|--------|----------------|
| 1 | `synapse_01_daily_status.sql`        | `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status`      | ~8.8 M |
| 2 | `synapse_02_mimo_allplatforms.sql`   | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`     | ~5 K   |
| 3 | `synapse_03_periodic_status.sql`     | `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status`   | ~8.8 M |

Synapse #2 covers **Aug 2025 only** because PR #3875's nightly rerun of
`SP_DDR_Fact_Fact_MIMO_AllPlatforms` for May 2026 dates re-applies the new
demotion patch and overwrites those rows. Confirmed by `synapse_rerun.sql`.

### Databricks (run in Unity Catalog via SQL warehouse)

| # | Script | Target | Estimated rows |
|---|--------|--------|----------------|
| 1 | `databricks_01_daily_status.sql`      | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`      | ~8.8 M |
| 2 | `databricks_02_mimo_allplatforms.sql` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`     | ~3.5 K |
| 3 | `databricks_03_periodic_status.sql`   | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`   | ~4.9 M |

DBX #2 covers **both Aug 2025 AND May 2026 dates** — DBX has no equivalent
"rerun" mechanism on the SP that would re-touch the May rows, so this script
handles all six bad-FTD dates in one pass.

DBX #3 is needed because the bronze sync of the Synapse periodic_status table
only refreshes recent etr_ymd snapshots — historical rows back to 2025-08-18
do not get re-synced after the Synapse UPDATE, so the leak persists in UC
even after `synapse_03_periodic_status.sql` runs.
Once the UC periodic_status table is deprecated in favour of
`main.de_output.ddr_tvf_customer_periodic_status`, this script becomes
unnecessary going forward.

## Run order

1. **Merge PR #3875** so the patched SPs are in production.
2. Run the Synapse rerun script (`../synapse_rerun.sql`, separate file) to
   reprocess the May 2026 dates with the new demotion patches.
3. Run the one-shots:

```text
synapse_01_daily_status.sql         →  ~10-15 min on serverless DW
synapse_02_mimo_allplatforms.sql    →  < 1 min (only ~5 K leaked rows)
synapse_03_periodic_status.sql      →  ~20-25 min on serverless DW
databricks_01_daily_status.sql      →  ~5-15 min on M-or-L SQL warehouse
databricks_02_mimo_allplatforms.sql →  < 1 min
databricks_03_periodic_status.sql   →  ~5-10 min on M-or-L SQL warehouse
```

Scripts are independent — order between Synapse and Databricks does not
matter. Within each platform, order is suggested but not strictly required
(daily must precede periodic for clean MAX(...) semantics on the Synapse side).

## Idempotency

Every script is idempotent. Re-running zeroes already-zeroed columns and
re-asserts the cohort filter. Safe to re-run after future bronze sync
overwrites or partial failures.

## Verification

Each script includes a STEP 3 verification block. Expected post-state:
all flag columns SUM to 0 across the cohort, all FTD anchor columns are
NULL or sentinel `30000101`, all funded fields are 0/NULL.

Cross-system parity check after both Synapse + DBX one-shots complete:

```sql
-- Synapse
SELECT 'syn_dep' AS k, SUM(CAST(IsDepositor AS INT)) AS v
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
WHERE RealCID IN (<bad cohort CIDs>);

-- Databricks
SELECT 'dbx_dep' AS k, SUM(CAST(IsDepositor AS INT)) AS v
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
WHERE RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);
```

Both should return 0.

## How to run

### Synapse (via Cursor MCP)

```text
Use the user-synapse_prod_sql MCP (port 8767) — server uses Integrated
auth (silent SSO), no popup. Paste each script as a single execute_sql
call. Synapse does not support GO/transactions across the temp table +
UPDATE, so the script is one block.
```

For dev pool testing, the canonical Python wrapper is in
`../depositor_demotion/_run_oneshot_dev.py` (daily), `_run_mimo_oneshot_dev.py`
(MIMO), `_run_periodic_oneshot_dev.py` (periodic). All three use
`Authentication=ActiveDirectoryIntegrated`.

### Databricks (via Cursor MCP)

```text
Use the user-databricks_sql MCP. Paste each script as a single execute_sql
call. Spark SQL accepts multi-statement scripts split by semicolons; the
MCP will execute them in order.
```

## Where the going-forward fix lives

Both bugs (MIMO IsPlatformFTD leak AND IsDepositor/IsFunded leak) are
already fixed in the canonical SP sources:

| Patch | Synapse source | DBX source |
|-------|----------------|------------|
| MIMO demotion       | `DataPlatform/.../SP_DDR_Fact_Fact_MIMO_AllPlatforms.sql` (final UPDATE block) | `main.de_output.sp_ddr_fact_mimo_allplatforms` (via `v_mimo_allplatforms` filter) |
| Daily demotion      | `DataPlatform/.../SP_DDR_Customer_Daily_Status.sql` (final UPDATE block) | `main.de_output.sp_ddr_customer_daily_status` (final demotion block in DDL) |

Once PR #3875 merges, the nightly DDR run is self-healing for any future
bad-FTD batch that matches the cohort definition (multiple-of-six dates
above can be extended with a single edit to the cohort CTE).
