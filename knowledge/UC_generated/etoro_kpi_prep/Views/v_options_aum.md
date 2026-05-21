---
object_fqn: main.etoro_kpi_prep.v_options_aum
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_options_aum
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:26:29Z'
upstreams:
- main.general.bronze_usabroker_apex_options
- main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_options_aum.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_options_aum.sql
concept_count: 2
formula_count: 8
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 8
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_options_aum

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 8 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_options_aum` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 4 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 23 10:23:42 UTC 2026 |

---

## 1. Business Meaning

`v_options_aum` is a view in `main.etoro_kpi_prep` that composes 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_usabroker_apex_options` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 8 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 8 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `first_funding`: `RN = 1`
**What**: `WHERE` clause at the top of scope `first_funding` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `RN`
**Rules**:
- `RN = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_options_aum.sql` L27

### 2.2 Filter on scope `latest_daily_buypower`: `daily_rn = 1`
**What**: `WHERE` clause at the top of scope `latest_daily_buypower` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `daily_rn`
**Rules**:
- `daily_rn = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_options_aum.sql` L38

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
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `first_funding` applies `RN = 1` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `latest_daily_buypower` applies `daily_rn = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.general.bronze_usabroker_apex_options`) |
| 1 | DateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(Date, 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 2 | Date | DATE | YES | Cast of upstream column. Formula: `CAST(ProcessDate AS DATE)`. (Tier 2 — computed in source) |
| 3 | OptionsTotalEquity | DECIMAL | YES | Cast of upstream column. Formula: `CAST(TotalEquity AS DECIMAL(18,2))`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 4 | OptionsCashEquity | DECIMAL | YES | Cast of upstream column. Formula: `CAST(CashEquity AS DECIMAL(18,2))`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 5 | OptionsPositionMarketValue | DECIMAL | YES | Cast of upstream column. Formula: `CAST(PositionMarketValue AS DECIMAL(18,2))`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 6 | FirstOptionsAUMDateID | INT | YES | Cast of upstream column. Formula: `CAST(DATE_FORMAT(CAST(FirstFundingDate AS DATE), 'yyyyMMdd') AS INT)`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |
| 7 | FirstOptionsAUMDate | DATE | YES | Cast of upstream column. Formula: `CAST(FirstFundingDate AS DATE)`. (Tier 2 — from `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_usabroker_apex_options` | Primary | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_usabroker_apex_options
main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
        │
        ▼
main.etoro_kpi_prep.v_options_aum   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
main.etoro_kpi_prep.v_ddr_fact_aum
main.etoro_kpi_prep.v_population_funded
... (1 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_usabroker_apex_options` (wiki: `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`
- `main.etoro_kpi_prep.v_ddr_fact_aum`
- `main.etoro_kpi_prep.v_population_funded`
- `main.etoro_kpi_prep_stg.bi_db_ddr_fact_aum`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 8 | Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: view_definition*
