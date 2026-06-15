# Synapse to Databricks Migration Profile

**Source workspace:** `prod-synapse-dataplatform-we` (Azure Synapse, West Europe)
**Profile date:** 2026-06-07 (31 days of pool telemetry, 2026-05-07 to 2026-06-07)
**Tooling:** Databricks Labs Lakebridge profiler v0.12.2 (with patches; see appendix)

> Audience: Databricks Migration Consultants. This document replaces the live Lakebridge dashboard since you do not have workspace access. All figures are pulled from `dwh_daily_process.lakebridge_profiler.*` (Delta tables on our metastore).

---

## 1. Executive summary

| Dimension | Value |
|---|---|
| Source | Azure Synapse Dedicated SQL Pool (Gen2 / DW6000c, single active pool) |
| Region | West Europe |
| Storage (used / reserved) | **86.1 TB used / 88.3 TB reserved** across 12 compute nodes |
| Objects | 4,064 base tables / 121 views / 1,283 stored procedures / 97 functions |
| Columns | 79,616 (avg 19.6 cols/table, max 281) |
| 31-day pool DWU | avg 1,820 / **P95 5,545** / **P99 5,590** / peak 6,000 (cap) |
| Memory utilisation | avg **82.7 %** / peak 92 % (sustained pressure) |
| CPU | avg 17.8 % / P95 57 % / peak 100 % |
| Workload mix (snapshot) | 37 % stored-proc calls, 31 % DDL, 14 % ad-hoc QUERY, 13 % OTHER, 3.5 % DML |
| Failure rate | 2.54 % of recent requests `Failed` (252 / 9,918) |
| Daily peak DWU | hits 6,000 cap **every single day** of the 31-day window |
| BI / consumer tools observed | Tableau (23 distinct users), Databricks Lakehouse Federation, Python ETL, ADF, SSMS |

**Migration headline:** workload is memory-bound and bursty. Average utilisation is modest (~30 % of cap), but the pool saturates daily during the 04:00-11:00 UTC ETL/BI window. Object count is large but flat (most "schemas" hold a single table, a Synapse-imposed namespace artefact).

---

## 2. Source environment

### 2.1 Workspace

- **Resource ID:** `/subscriptions/ce091f9e-.../resourceGroups/rg-dataplatform-prod-we/providers/Microsoft.Synapse/workspaces/prod-synapse-dataplatform-we`
- **Storage backend:** ADLS Gen2 - `https://dldataplatformprodwe.dfs.core.windows.net` (filesystem `synapse-dl-fs`)
- **Purview:** integrated (`pureviewdc-dataplatform-prod-we`)
- **Tenant:** `Databases` (separate from the IT-Corporate tenant)

### 2.2 SQL pools

| Pool | SKU | State | Created | Notes |
|---|---|---|---|---|
| `sql_dp_prod_we` | **DW6000c** | Online | 2023-12-03 | Primary production pool |
| `sql_dp_prod_we_20240101_DO_NOT_DELETE__no_retention` | DW100c | Paused | 2025-01-05 | Year-end snapshot |
| `sql_dp_prod_we_20250101_DO_NOT_DELETE__no_retention` | DW100c | Paused | 2025-01-01 | Year-end snapshot |
| `sql_dp_prod_we_20260101_DO_NOT_DELETE__no_retention` | DW100c | Paused | 2026-01-01 | Year-end snapshot |

Only `sql_dp_prod_we` is in scope for migration (the other three are paused snapshots retained for compliance).

### 2.3 Other workspace artefacts

| Artefact | Count | Notes |
|---|---|---|
| Synapse pipelines | (not extracted, see appendix) | |
| Notebooks | 12 | |
| SQL scripts (saved) | 42 | |
| Linked services | 14 | 7 AzureBlobFS, 2 AzureSqlDW, 2 CosmosDb, 2 AzureBlobStorage, 1 AzureKeyVault |
| Spark pools | 1 | (excluded from profiler scope) |
## 3. Storage footprint

| Pool | Reserved | Used | Compute nodes |
|---|---|---|---|
| `sql_dp_prod_we` | 88.3 TB | **86.1 TB** | 12 (per `sys.dm_pdw_nodes_db_partition_stats`) |

Per-node values are roughly even (sharded). Reserved-vs-used delta of ~2 TB is overhead from segments not yet rebuilt.

> **Sizing implication:** under Delta with default Z-ordering and table-level OPTIMIZE you should expect **~30-50 % shrink** versus the Synapse rowstore footprint (typical for our type of mixed-width numeric/string warehouse). Plan for **45-65 TB Delta** post-migration.


## 4. Object inventory

### 4.1 Tables / views (4,064 base tables, 121 views)

Tables grouped by naming convention:

| Pattern | Tables | Notes |
|---|---|---|
| `BI_DB_*` | 1,112 | Reporting marts (BI database mirrored from on-prem) |
| `External_*` | 578 | PolyBase external tables pointing at ADLS / lakes |
| `etoro_*` | 150 | Operational mirrors |
| `DWH_*` | 25 | Core DWH dims/facts |
| `ext_tmp_tbl_*` | 15 | Disposable Polybase staging |
| Other (`*_dbo`, `*_staging`, ad-hoc schemas) | 2,063 | Long tail; mostly per-source mirrors |

Synapse "schema" naming here is unusual: most schemas hold a single table because the team encodes source DB into the schema name (e.g. `BI_DB_dbo.SomeTable`, `External_fiktivo_dbo.X`). The 3,943 base tables span **3,856 distinct schemas**. On Databricks this should be remodelled as `<source>.<schema>.<table>` (3-part UC namespace) - the Synapse flat namespace is a known migration cleanup item.

### 4.2 Routines (1,380 total)

| Type | Count |
|---|---|
| PROCEDURE | 1,283 |
| FUNCTION (scalar / table / inline) | 97 |

These are the biggest conversion lift: each SP needs Lakebridge transpile + reconcile + manual review for T-SQL constructs that don't have a 1:1 in Spark SQL (cursors, table-valued params, RAISERROR, dynamic SQL with `sp_executesql`, MERGE patterns, etc.).

### 4.3 Column type distribution (top 15 of 79,616 columns)

| Synapse type | Columns | Databricks mapping |
|---|---|---|
| `int` | 20,538 | INT |
| `varchar` | 17,721 | STRING |
| `nvarchar` | 9,024 | STRING |
| `decimal` | 6,129 | DECIMAL(p,s) |
| `datetime` | 4,282 | TIMESTAMP_NTZ |
| `numeric` | 3,981 | DECIMAL(p,s) |
| `bigint` | 3,875 | BIGINT |
| `money` | 3,801 | **needs explicit DECIMAL(19,4)** (no native equivalent) |
| `float` | 3,364 | DOUBLE |
| `datetime2` | 2,120 | TIMESTAMP / TIMESTAMP_NTZ |
| `date` | 2,081 | DATE |
| `bit` | 1,449 | BOOLEAN |
| `tinyint` | 627 | SMALLINT (no TINYINT) |
| `smallint` | 257 | SMALLINT |
| `char` | 215 | STRING |

**Type-conversion gotchas to plan for:**
- 3,801 `money` columns - choose precision/scale convention up-front (we standardised on `DECIMAL(19,4)`).
- 627 `tinyint` columns - widen to SMALLINT.
- 4,282 `datetime` + 2,120 `datetime2` - decide TIMESTAMP vs TIMESTAMP_NTZ globally; we lean TIMESTAMP_NTZ since Synapse doesn't carry timezone.
- 121 views: most should become Delta materialised views or Live Tables (downstream consumers expect view names; we plan to keep the names as Databricks views over Delta).

### 4.4 Widest tables (proxy for ETL / model complexity)

| Table | Columns |
|---|---|
| `Dealing_staging.LP_IB_U1059976_Cash_Report_581` | 281 |
| `BI_DB_dbo.External_Fivetran_twitter_campaign_locations_report` | 258 |
| `BI_DB_dbo.BI_DB_V_DDR_Daily_Panel` | 249 |
| `Dealing_staging.LP_IB_I3158027_Cash_Report_33_tmp` | 232 |
| `Dealing_staging.LP_IB_I3158027_Cash_Report_33_new` | 232 |

Median table is 11 columns, P95 is 68. The fat tables are mostly Fivetran landing tables (auto-generated) and the one true wide reporting fact `BI_DB_V_DDR_Daily_Panel`.


## 5. Runtime load profile (what drives compute sizing)

### 5.1 31-day pool utilisation (`sql_dp_prod_we`)

| Metric | Mean | P50 | P95 | P99 | Peak |
|---|---:|---:|---:|---:|---:|
| CPUPercent | 17.84 | 8.92 | 57.07 | 70.45 | 100.00 |
| DWUUsed | 1,820 | 746 | 5,545 | 5,590 | 6,000 |
| DWUUsedPercent | 30.34% | 12.43% | 92.42% | 93.17% | 100% |
| DWULimit | 4,227 | 4,227 | 4,232 | 4,235 | 6,000 |
| MemoryUsedPercent | 82.65% | 82.84% | 83.28% | 84.01% | 92.00% |
| Connections | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

Interpretation:
- The workload is not CPU-bound on average, but regularly reaches high DWU usage.
- Memory sits at a high baseline (~83%), suggesting pressure from large scans/shuffles and/or broad concurrent transforms.
- The pool reaches the 6,000 cap every day in the observed window.

### 5.2 Intra-day shape (UTC, from DWUUsed averages)

Observed hot window: roughly **04:00-11:00 UTC**.

Representative hourly averages:
- 04:00 -> 4,594 DWU
- 05:00 -> 5,049 DWU
- 06:00 -> 5,271 DWU
- 07:00 -> 4,962 DWU
- 08:00 -> 4,056 DWU
- 09:00 -> 2,445 DWU
- 10:00 -> 3,371 DWU

Off-peak is substantially lower (e.g. 18:00-23:00 around 126-294 DWU average).

### 5.3 Request mix and success

From `dedicated_session_requests` (9,918 requests in extraction slice):

| Dimension | Count | Share |
|---|---:|---:|
| Completed | 9,663 | 97.43% |
| Failed | 252 | 2.54% |
| Cancelled | 2 | 0.02% |
| Running | 1 | 0.01% |

Command type distribution:

| Command type | Count | Avg elapsed (ms) | P95 elapsed (ms) | Max elapsed (ms) |
|---|---:|---:|---:|---:|
| ROUTINE | 3,701 | 4,104 | 9,479 | 360,812 |
| DDL | 3,047 | 1,545 | 3,369 | 360,771 |
| QUERY | 1,410 | 451 | 3,202 | 40,819 |
| OTHER | 1,346 | 4,380 | 16,301 | 216,311 |
| DML | 342 | 4,693 | 17,763 | 96,022 |
| TRANSACTION_CONTROL | 72 | 552 | 853 | 1,046 |

Resource class tags on QUERY/DML were mostly empty in DMV snapshot (84.3%), with some `ETL`, `Ad-hoc`, `smallrc`, `TableauUsers`.

### 5.4 Client/application fingerprint (sessions)

Top observed apps:
- `Databricks-User-Query` (5,075 sessions; 66,181 queries) - Lakehouse federation / Databricks SQL pushdown consumers.
- `Microsoft SQL Server` (1,489 sessions; 20,065 queries) - service/API style clients.
- `Python` (1,051 sessions; 6,491 queries) - ETL orchestration/scripts.
- `Tableau 2025.3` (540 sessions; 35,909 queries; 23 distinct logins).
- `SSMS` and developer tools (long-tail troubleshooting / ad-hoc use).

This confirms significant BI + programmatic consumption that will need cutover planning, not just batch ETL rewrite.

---

## 6. Migration impact estimate (consulting-ready)

### 6.1 Capacity and cost posture

Current Synapse posture is heavily overprovisioned for peak handling (DW6000c) with low off-peak utilisation.

For Databricks, recommended target model:
- Move to autoscaling SQL warehouses + job clusters.
- Size for the 04:00-11:00 UTC peak window, not all-day fixed capacity.
- Use workload split:
  - BI serving warehouse(s) for Tableau/ad-hoc.
  - Job compute for ETL/stored-proc replacements.

Initial sizing envelope (to validate in pilot):
- **Serving:** Start at medium-large SQL warehouse, autoscale max tuned to p95 equivalent.
- **ETL:** Job clusters sized to absorb 5k-5.5k DWU-equivalent window (parallel pipelines), with Photon enabled.
- **Storage:** Plan **45-65 TB Delta** after compaction and format conversion.

### 6.2 Engineering effort profile

Complexity drivers:
- 1,283 stored procedures (largest effort bucket).
- 97 functions.
- 4,064 tables and 121 views (mostly mechanical migration + compatibility testing).
- Mixed tool consumers (Tableau, Python, Databricks federation, SSMS-like users).

Rough workstream split:
1. **Schema/data migration** (bulk, automatable)  
2. **Procedure/function transpile + manual remediation** (dominant engineering effort)  
3. **Consumer cutover and contract testing** (BI + API + ops scripts)  
4. **Performance tuning** (Photon, partitioning, Z-Order, caching, materialized views)  

### 6.3 Key risks to track

- Stored procedure semantic drift after transpilation.
- Time semantics (`datetime`/`datetime2`) and money precision handling.
- External table dependencies (`External_*`) and data-lake path assumptions.
- Dashboard/report compatibility during staged cutover.
- Memory-heavy peak window requiring deliberate pipeline concurrency control.

---

## 7. What consultants can run immediately

Primary dataset location:
- Catalog/schema: `dwh_daily_process.lakebridge_profiler`
- Key tables:
  - `dedicated_tables`
  - `dedicated_columns`
  - `dedicated_views`
  - `dedicated_routines`
  - `dedicated_sessions`
  - `dedicated_session_requests`
  - `dedicated_storage_info`
  - `metrics_dedicated_pool_metrics`
  - `metrics_workspace_level_metrics`
  - `workspace_sql_pools`, `workspace_linked_services`, etc.

Recommended first checks:
1. Validate peak-hour compute pressure from `metrics_dedicated_pool_metrics`.
2. Build top-N long-running command families from `dedicated_session_requests`.
3. Prioritize SP remediation backlog from `dedicated_routines`.
4. Map BI dependencies from session app/login patterns.

---

## 8. Appendix - profiler run notes and caveats

1. **Lakebridge profiler required compatibility patches** in this environment:
   - Synapse transaction handling (AUTOCOMMIT for pyodbc/SQLAlchemy path).
   - `INFORMATION_SCHEMA.ROUTINES` unsupported on Dedicated pool -> switched to `sys.objects`.
   - Case-sensitive system catalog behavior required lower-case `sys.*` references.
   - Dedicated request DMV column casing alignment.
2. These patches were used only to complete extraction; final published metrics/tables are stable and queryable.
3. `workspace_pipelines` count is not present in the extracted table set for this run (known extractor gap in this version).

---

## Contact

If you need direct SQL access to the profiler dataset, request access to catalog `dwh_daily_process` and schema `lakebridge_profiler`.

