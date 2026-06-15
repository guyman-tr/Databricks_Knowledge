---
object_fqn: main.bi_output.bi_output_vg_date
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_date
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T15:01:50Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_date.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_date.sql
concept_count: 0
formula_count: 7
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_date

> View in `main.bi_output`. 0 business concept(s) in §2; 10 of 10 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_date` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 10 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 26 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Thu Nov 20 18:13:34 UTC 2025 |

---

## 1. Business Meaning

`bi_output_vg_date` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md`.

Of its 10 columns: 5 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Primary key. Date encoded as integer YYYYMMDD (e.g. 20260101 for 2026-01-01). The join target for every date-keyed fact in the warehouse. (Tier 1 — DDL + SP_PopulateDimDate) |
| 1 | Date | TIMESTAMP | YES | Native SQL date (e.g. 2026-01-01). 1:1 with DateKey. Use this when a date-typed comparison is needed; use DateKey for integer joins. (Tier 1 — DDL) |
| 2 | WeekNumberYear | INT | YES | Sunday-Start week number of year (1-53). Week starts Sunday — US retail convention. (Tier 1 — DDL) |
| 3 | CalendarYearMonth | STRING | YES | Calendar year-month label, format `YYYY-MM` (e.g. `'2026-04'`). Most common GROUP BY key for monthly rollups. (Tier 2 — live sample) |
| 4 | CalendarQuarter | INT | YES | Calendar quarter 1-4. (Tier 1 — DDL) |
| 5 | CalendarYear | INT | YES | Calendar year (e.g. 2026). (Tier 1 — DDL) |
| 6 | IsLastDayWeek | INT | NO | Computed flag (CASE expression in source). Formula: `,FullDate AS Date ,SSWeekNumberOfYear WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,SSWeekNumberOfYe…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 7 | IsLastDayQuarter | INT | NO | Computed flag (CASE expression in source). Formula: `,FullDate AS Date ,SSWeekNumberOfYear WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,SSWeekNumberOfYe…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 8 | IsLastDayMonth | INT | NO | Computed flag (CASE expression in source). Formula: `,FullDate AS Date ,SSWeekNumberOfYear WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,SSWeekNumberOfYe…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 9 | IsLastDayYear | INT | NO | Computed flag (CASE expression in source). Formula: `,FullDate AS Date ,SSWeekNumberOfYear WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,SSWeekNumberOfYe…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
        │
        ▼
main.bi_output.bi_output_vg_date   ←── this object
        │
        ▼
main.bi_output.bi_output_vg_aum
main.bi_output.bi_output_vg_club
main.bi_output.bi_output_vg_copy_mimo
... (23 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=10 runtime=10 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output.bi_output_vg_aum`
- `main.bi_output.bi_output_vg_club`
- `main.bi_output.bi_output_vg_copy_mimo`
- `main.bi_output.bi_output_vg_customer_snapshot`
- `main.bi_output.bi_output_vg_customer_snapshot_test`
- `main.bi_output.bi_output_vg_customer_snapshot_v2`
- `main.bi_output.bi_output_vg_ddr_customers_snapshot`
- `main.bi_output.bi_output_vg_mimo`
- `main.bi_output.bi_output_vg_parentcid`
- `main.bi_output.bi_output_vg_revenue`
- `main.bi_output.bi_output_vg_volume_amount`
- `main.etoro_kpi.customer_snapshot_v`
- `main.etoro_kpi.ddr_aum_v`
- `main.etoro_kpi.ddr_mimo_v`
- `main.etoro_kpi.ddr_pnl_v`
- `main.etoro_kpi.ddr_revenue_v`
- `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- `main.etoro_kpi_stg.bi_output_vg_aum_slim`
- `main.etoro_kpi_stg.bi_output_vg_mimo_slim`
- `main.etoro_kpi_stg.bi_output_vg_revenue_slim`
- _(+6 more)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 7 | Tiers: 5 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: view_definition*
