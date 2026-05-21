---
object_fqn: main.etoro_kpi_prep.v_dim_dataplatform_uuid
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_dim_dataplatform_uuid
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:26:22Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.bi_db.bronze_sub_accounts_accounts
- main.etoro_kpi.v_spaceship_aum
- main.etoro_kpi_prep.v_spaceship_aum
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_dataplatform_uuid.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_dataplatform_uuid.sql
concept_count: 2
formula_count: 6
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 6
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_dim_dataplatform_uuid

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_dataplatform_uuid` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 4 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 19 07:33:23 UTC 2026 |

---

## 1. Business Meaning

`v_dim_dataplatform_uuid` is a view in `main.etoro_kpi_prep` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 6 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 6 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `source_platform` computed flag
**What**: Computed flag on `source_platform` set to `'         '` when the predicates below hold, else `'          '`.
**Columns Involved**: `source_platform`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_dataplatform_uuid.sql` etoro_kpi_prep.sql L43-L43
**Source(s)**: `main.bi_db.bronze_sub_accounts_accounts`

### 2.2 Filter on scope `sps_cross`: `providerName = '         '`
**What**: `WHERE` clause at the top of scope `sps_cross` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `providerName`
**Rules**:
- `providerName = '         '`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_dataplatform_uuid.sql` L23

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
| Filter on discriminator flags | Use `source_platform = 1`-style filters on the precomputed flag columns (`source_platform`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `sps_cross` applies `providerName = '         '` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | dp_uuid | STRING | YES | Cast of upstream column. Formula: `CAST(GCID AS STRING)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 1 | source_platform | STRING | NO | `source_platform` computed flag. Formula: `CASE WHEN sps_user_id IS NOT NULL THEN 'both_gcid' ELSE 'etoro_gcid' END`. (Tier 2 — from `main.bi_db.bronze_sub_accounts_accounts`) |
| 2 | gcid | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 3 | cid | INT | YES | Direct passthrough from upstream. Formula: `primary_cid`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 4 | etoro_cid_count | LONG | YES | Direct passthrough from upstream. Formula: `cid_count`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 5 | sps_user_id | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- SPS user_ids that are cross-onboarded (have a GCID via sub_accounts) sps_cross AS ( SELECT DISTINCT accountId AS sps_user_id, gcid`. (Tier 2 — from `main.bi_db.bronze_sub_accounts_accounts`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.etoro_kpi.v_spaceship_aum` | JOIN/UNION | `knowledge/uc_domains/spaceship/schemas/etoro_kpi/Views/v_spaceship_aum.md` |
| `main.etoro_kpi_prep.v_spaceship_aum` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_spaceship_aum.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.bi_db.bronze_sub_accounts_accounts
main.etoro_kpi.v_spaceship_aum
... (1 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_dim_dataplatform_uuid   ←── this object
        │
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
main.de_output.de_output_etoro_kpi_dim_dataplatform_uuid
main.de_output_stg.de_output_etoro_kpi_dim_dataplatform_uuid
... (1 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum`
- `main.de_output.de_output_etoro_kpi_dim_dataplatform_uuid`
- `main.de_output_stg.de_output_etoro_kpi_dim_dataplatform_uuid`
- `main.etoro_kpi_prep.v_ddr_fact_aum`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 6 | Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
