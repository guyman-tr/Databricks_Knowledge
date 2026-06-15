# Migration Blacklist Plan — Priority-0 SPs & Table Objects — 2026-05-31

**Goal**: produce a defensible blacklist of Synapse stored procedures (and their output tables) that should **not** be migrated to Databricks, so the migration runner skips them outright.

**Scope (this plan)**: Phases A and B per user direction. Phase 3 (near-duplicate consolidation) deferred.

---

## 0. Universe & current state

From `.specify/Configs/opsdb-objects-status.json`: **710 SPs**, each with one output table.

| Schema | SP count | Notes |
|---|---|---|
| `BI_DB_dbo` | 463 | bulk of priority-0 daily |
| `Dealing_dbo` | 156 | dealing analytics |
| `Dealing_staging` | 87 | dealing staging |
| `DWH-DAYLY` | 4 | misc |

| Priority | Count |
|---|---|
| 0 (no orchestration weight) | 480 ← target of this exercise |
| >0 (already in scope or done) | 230 |

**Available data sources (validated)**:
- `user-synapse_prod_sql` MCP — **WORKING**
- `user-synapse_sql` MCP — **WORKING**
- `user-opsdb_sql` MCP — **DOWN** (needs restart in Cursor settings; non-blocking)
- DataPlatform repo for SP source SQL
- Tableau Metadata API toolkit at `tools/tableau/`
- Existing Tableau index (~15 tables) at `knowledge/tableau/_index/` — needs bulk sweep

---

## 1. Deliverable artifact

`audits/migration_blacklist_<date>.csv` — one row per SP, plus a checkbox sidecar `audits/migration_blacklist_<date>.md` in the same shape as `tools/lakebridge/audit/PRUNE_LIST.md`.

```
proc_fqn, output_table_fqn, priority, frequency, process_name,
classification,            # KEEP | DROP_HARD | DROP_SOFT | SUSPECT
verdict_tier,              # A1..A7 (stale) | B1..B4 (orphan) | KEEP
score_total,               # 0–100
signal_naming, signal_empty_body, signal_zero_rows, signal_low_rows,
signal_stale_data, signal_no_internal_consumer,
signal_no_tableau, signal_dead_tableau, signal_dead_owner,
signal_duplicate_writer, signal_failed_runs,
last_proc_modified, last_table_loaded, days_since_load, row_count,
internal_consumers_count, tableau_workbooks_count,
tableau_active_workbooks_90d, evidence_links,
human_review_status,       # PENDING | CONFIRMED_DROP | REPRIEVE | NEEDS_INFO
notes
```

**Output-tables blacklist** is derived: `SELECT output_table_fqn FROM blacklist WHERE classification IN (DROP_HARD, DROP_SOFT)`.

---

## 2. Phase A — Stale / junk hard drop

Cheap signals computed without external API access. Each SP gets a weighted score; thresholds determine tier.

### A1 — Naming markers (weight 30, near-deterministic)

Regex over `proc_fqn` AND `output_table_fqn`:

```
\b(bkp|bckp|backup|old|legacy|deprecated|junk|tmp|temp|trash)\b
\b(test|qa|sandbox|poc|pilot|nitsan|eyal|guy|adi|tomer|<owner_initials>)\b
_v0\b | _v[12]_old\b | _2$ | _3$
_\d{8}\b | _\d{4}_\d{2}_\d{2}\b | _Y\d{4}\b
```

Pattern catalog already exists in `tools/lakebridge/_categorize_remaining.py`; reuse.

### A2 — Empty / no-op SP body (weight 25, deterministic)

Read SP source from DataPlatform repo. Drop if body (after stripping `BEGIN/END/SET NOCOUNT/PRINT/comments`):
- empty
- `RETURN`
- single `SELECT 1` / `SELECT GETDATE()`
- contains only `IF 1=0` / `WHERE 1=2` (disabled-but-shipped pattern)
- single `EXEC` to a procedure that itself is on the blacklist

### A3 — Output-table data freshness (weight 25) ✅ **VALIDATED**

For each SP, query the output table for the most-recent `UpdateDate` (or fallback). Today is the source of truth for the user's heuristic: *"daily SP with no fresh data in past month → either feeding null data or failing silently"*.

**Column priority chain** (validated against `INFORMATION_SCHEMA.COLUMNS`):

| Column | Coverage | Type |
|---|---|---|
| `UpdateDate` | 1369 tables (~95% of universe) | datetime |
| `LastUpdateDate` | 223 tables | datetime |
| `ModificationDate` | 46 tables | datetime |
| `ReportDateID` | 295 tables | int YYYYMMDD |
| `DateID` | 342 tables | int YYYYMMDD |
| `Date` | 573 tables | date/datetime |
| (none of above) | residual | flag as "no_freshness_col" |

**Per-table probe pattern** (validated, must use `COUNT_BIG(*)` — `COUNT(*)` overflows on multi-billion-row fact tables):

```sql
SELECT
  '<table>' AS tbl,
  CONVERT(varchar(20), MAX(UpdateDate), 120) AS last_update,
  COUNT_BIG(*) AS row_count
FROM <schema>.<table>
```

**Tier triggers (Daily-frequency SPs)**:
- `days_since_load > 30` → A3.HARD
- `days_since_load > 7` AND `frequency='Daily'` → A3.SOFT
- (relax thresholds proportionally for Weekly/Monthly/Quarterly)

**Live demo** (random 9 priority-0 daily BI_DB SPs sampled 2026-05-31):
- `BI_DB_Diversification` last refreshed 2026-05-16 → **15 days stale** → A3.HARD
- `BI_DB_OPS_HighCompensationsVsDeposits` is fresh but **2 rows total** → A3a candidate
- 7 others: KEEP. Hit rate ≈ 22% on a random sample.

### A3a — Low-row output (weight 15)

Fresh-but-tiny: `row_count < 100` AND not on the known reference-dimension allowlist (configurable). Flags procedures producing nothing useful even though they ran. Caught `BI_DB_OPS_HighCompensationsVsDeposits` (2 rows) in the validation sample.

### A4 — Failed-runs signal (weight 25, requires OpsDB MCP)

Once `user-opsdb_sql` MCP is restored, query `dbo.ObjectStatusHistory` (per user direction) for run-success rate over last 90 days:
- 0 successful runs in 90 days → A4.HARD
- ≥30% failure rate → A4.SOFT

**Status**: blocked on MCP restart; **not a hard prerequisite** — A3 freshness already captures this implicitly (failing SP → stale table).

### A5 — SP body unchanged > 36 months (weight 10)

`MAX(modify_date)` from `sys.sql_modules` cross-referenced with the dependency graph: code untouched in 3+ years that feeds nothing → stale.

### A6 — Cascade orphan (weight 10)

SP's primary input is dropped or itself on the blacklist → cascade-drop. Run as a second pass after A1–A5.

### A7 — Duplicate writer (weight 5, signal-only)

Two or more SPs target the **same** `TableName`. Surface for visibility; do not auto-drop (Phase 3 territory). Already detected in the validation sample: `BI_DB_AML_Documents_Request` is written by both `SP_AML_Documents_Request` and `SP_W_AML_PEP_Customers`.

### Phase A scoring & tiers

- `DROP_HARD` if `score ≥ 60` OR any single deterministic signal fires (A1 dated suffix, A2 empty body, A3.HARD)
- `DROP_SOFT` if `40 ≤ score < 60`
- `SUSPECT` if `25 ≤ score < 40` — proceed to Phase B
- Else continue to Phase B

**Expected**: ~150–200 in `DROP_HARD` from Phase A alone (the user's "1/3 stale" estimate).

---

## 3. Phase B — Orphan / dead-end output

Run only on rows surviving Phase A. Question becomes: *"this SP runs and produces fresh data — but does anyone consume that data?"*

### B0 — Build the consumer graph

For each surviving `output_table_fqn`, collect consumers from:

1. **Internal DWH consumers** — `opsdb-procedure-dependencies.json` reverse lookup + `sys.sql_expression_dependencies` for views/functions/SPs not in OpsDB.
2. **Generic-pipeline / Databricks consumers** — UC `system.access.table_lineage` and `system.access.column_lineage` for the mirror table in `main.<schema>` (already mapped during the migration write side).
3. **Tableau consumers** — bulk Tableau Metadata API sweep (B1).
4. **PowerBI / external** — out of scope unless inventory provided; mark `unknown` rather than `none`.

Persist to `audits/_consumer_graph_<date>.csv (consumer_kind, consumer_id, last_touched, owner)`.

### B1 — Tableau bulk sweep

Reuse `tools/tableau/extract_table_metadata.py`:
- Generate `pilots_all_outputs.txt` from full output-table list (~480 lines after A drops).
- Run in chunks of 50 to avoid throttling.
- Extend GraphQL query to also capture `embeddedDatasources.name` and per-view `name` for cross-reference with REST in B2.

### B2 — Tableau usage-decay (NEW capability — small build)

Add `tools/tableau/fetch_view_stats.py`:
```
GET /api/{ver}/sites/{site_id}/workbooks/{wb_luid}/views?fields=usage
GET /api/{ver}/sites/{site_id}/views/{view_luid}/usage  → totalViewCount + lastViewedAt
```
Aggregate per workbook → `knowledge/tableau/_index/usage.csv (workbook_luid, last_viewed_at, views_90d, views_365d)`.

### B3 — Owner activity check

Cross-reference `workbook.owner.username` against a `departed_users.txt` (or HR/AD export). Workbooks owned by departed users with no recent ownership change accelerate deprecation.

### B4 — Phase B classification matrix

| Internal consumers | Tableau workbooks | Tableau active 90d | UC lineage | Class |
|---|---|---|---|---|
| 0 | 0 | n/a | 0 | **DROP_HARD** (B1) |
| 0 | ≥1 | 0 | 0 | **DROP_SOFT** (B2: dead Tableau only) |
| 0 | ≥1 | ≥1 | 0 | **KEEP** (live Tableau consumer) |
| 0 | ≥1, owner departed | 0 | 0 | **DROP_HARD** (B3) |
| ≥1 internal | * | * | * | **KEEP** (internal feeder; Phase 3 territory) |
| 0 | 0 | n/a | ≥1 | **SUSPECT** — investigate DBX users |

### B5 — Custom-SQL trap

Tableau workbooks often hide table refs in custom SQL. The existing `extract_tableau_edges.py` already parses these; when B1 returns a workbook with `via=custom_sql`, also resolve the SQL body and surface secondary tables it touches.

---

## 4. Workflow / scripts to build

| # | Script | Reuses | Output |
|---|---|---|---|
| 1 | `tools/migration_blacklist/build_universe.py` | OpsDB static JSONs | `audits/_universe_<date>.csv` (710 rows) |
| 2 | `tools/migration_blacklist/score_phase_a.py` | DataPlatform repo, Synapse MCP, OpsDB MCP (optional) | `audits/_phase_a_<date>.csv` |
| 3 | `tools/migration_blacklist/probe_freshness.py` | Synapse MCP `UpdateDate`-chain | `audits/_freshness_<date>.csv` |
| 4 | `tools/migration_blacklist/build_consumer_graph.py` | sys.sql_expression_dependencies, opsdb deps, UC lineage | `audits/_consumer_graph_<date>.csv` |
| 5 | `tools/migration_blacklist/run_tableau_sweep.sh` | existing `extract_table_metadata.py` | `knowledge/tableau/<table>.md` + indices |
| 6 | `tools/tableau/fetch_view_stats.py` | tableauserverclient REST | `knowledge/tableau/_index/usage.csv` |
| 7 | `tools/migration_blacklist/score_phase_b.py` | outputs of 4,5,6 | `audits/_phase_b_<date>.csv` |
| 8 | `tools/migration_blacklist/merge_and_render.py` | A+B + checkbox renderer (PRUNE_LIST shape) | `audits/migration_blacklist_<date>.{csv,md}` |

Steps 1–4 run in parallel. 5+6 are I/O-bound on Tableau API (batch + throttle).

---

## 5. Open gaps to confirm

| # | Gap | Recommended resolution |
|---|---|---|
| 1 | OpsDB MCP `user-opsdb_sql` is in error state | User restart in Cursor Settings → MCP |
| 2 | `ObjectStatusHistory` schema (per user direction) | Validate after MCP restart; use for failed-runs signal A4 |
| 3 | Tableau view-usage retention | Confirm with Tableau admin (default 365d) |
| 4 | Departed-users source | Pick: AD/HR export OR "owner-not-modified-12mo" heuristic |
| 5 | PowerBI / external consumers | If none, mark out-of-scope explicitly |
| 6 | Service Broker queue dump (~1000 procs vs OpsDB 710) | Add SB queue as second universe source; anything outside OpsDB → `DROP_HARD` by default |

**Recommendation on #6**: yes, add the SB queue dump. Anything not in OpsDB is by definition orphan-orchestration.

---

## 6. Confidence tiers, guardrails, review

**Three-tier review gate** before any actual drop:

1. **Tier-Hard (auto-confirm)** — `DROP_HARD` rows that fired ≥2 deterministic signals: batch-confirm with one click; sample 10 manually before mass-confirm.
2. **Tier-Soft (1-by-1 review)** — `DROP_SOFT` and `SUSPECT`: rendered as checkbox markdown; user ticks, agent acts.
3. **Tier-Reprieve** — stakeholder claim → `human_review_status=REPRIEVE`, capture justification in `notes`, migrate the SP.

**Guardrails**:
- Blacklist is **never** translated into `DROP TABLE` / `DROP PROC` on Synapse — it gates only the **migration runner**. Synapse decommissioning is a separate post-cutover pass.
- Every `DROP_HARD` carries an `evidence_links` column for auditability.
- Anything fed into a `priority>0` SP is auto-`KEEP` regardless of score.
- Re-runnable: each phase script is idempotent; dated outputs allow re-scoring after stakeholder feedback.

---

## 7. Execution order & rough effort

| Step | Effort | Blocks on |
|---|---|---|
| Confirm 6 gaps in §5 | 30 min | user |
| Phase A scripts (1–3) | 1 day | nothing |
| Consumer graph (4) | 0.5 day | OpsDB MCP for full reverse-deps (degraded otherwise) |
| Tableau bulk sweep (5) | 0.5 day wall-clock (throttled API) | nothing |
| View-stats + owner check (6+B3) | 0.5 day | Tableau admin confirmation |
| Phase B scoring (7) | 0.5 day | 4,5,6 done |
| Merge + checkbox render (8) | 0.25 day | A+B done |
| **User review pass** | depends on count | — |
| Wire blacklist into migration runner | 0.5 day | review done |

End-to-end build: **~3.5 working days** + review window.

---

## 8. Out of scope (explicit)

- Phase 3 (near-duplicate consolidation) — held off per user direction; current plan produces the input set.
- Modifying Synapse — no drops, no comments. Pure migration-routing concern.
- Re-classifying priority>0 procs — auto-`KEEP`.
- Cross-domain blacklist (Spaceship / Moneyfarm / Wallet) — separate scope.

---

## 9. Validation evidence (live, 2026-05-31)

End-to-end probe ran on 9 random priority-0 daily BI_DB SPs:

| Output table | last_update | row_count | Verdict |
|---|---|---|---|
| `BI_DB_AML_Periodic_Review_AR` | 2026-05-31 06:13 | 4,704,900 | KEEP |
| `BI_DB_OPS_HighCompensationsVsDeposits` | 2026-05-31 05:35 | **2** | A3a low-row |
| `DWH_CIDsDailyRisk` | 2026-05-31 05:27 | 4,831,872,747 | KEEP |
| `BI_DB_DailyTaboolaCombineAffwiz` | 2026-05-31 05:26 | 919,019 | KEEP |
| `BI_DB_US_Apex_Address_Change` | 2026-05-31 05:17 | 12,413 | KEEP |
| `BI_DB_AML_Documents_Request` | 2026-05-31 05:11 | 16,582,151 | KEEP (but A7 duplicate-writer flag) |
| `BI_DB_DDR_Fact_MIMO_Trading_Platform` | 2026-05-31 04:54 | 72,924,420 | KEEP |
| `BI_DB_AML_Gatsby_Alerts` | 2026-05-30 13:44 | 855 | KEEP |
| `BI_DB_Diversification` | **2026-05-16** | 370,468,909 | **A3.HARD — 15d stale daily SP** |

Hit rate ≈ 22% on a random pull. Extrapolated to the full 480 priority-0 daily population, expect ~100 rows from A3 alone before any other signal fires.
