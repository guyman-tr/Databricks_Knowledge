---
object_fqn: main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:48:16Z'
upstreams:
- main.bi_dealing.gold_dealing_oms_internalmarket_parameters
- main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/gold_dealing_oms_internalmarket_imdynamicbookfutures_v.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/gold_dealing_oms_internalmarket_imdynamicbookfutures_v.sql
concept_count: 1
formula_count: 9
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 9
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# gold_dealing_oms_internalmarket_imdynamicbookfutures_v

> View in `main.bi_dealing`. 1 business concept(s) in §2; 9 of 9 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | matansa@etoro.com |
| **Row count** | n/a |
| **Column count** | 9 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed Nov 12 10:16:01 UTC 2025 |

---

## 1. Business Meaning

`gold_dealing_oms_internalmarket_imdynamicbookfutures_v` is a view in `main.bi_dealing` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_dealing.gold_dealing_oms_internalmarket_parameters` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_oms_internalmarket_parameters.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 9 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 9 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `di` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `,'                       ' as URL ,'       ' as OmsParam ,date(UpdateTime`
**Evidence**: `knowledge/UC_generated/bi_dealing/_discovery/source_code/gold_dealing_oms_internalmarket_imdynamicbookfutures_v.sql` L53
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `,'                       ' as URL ,'       ' as OmsParam ,date(UpdateTime` | Lookup via alias `di` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates`) |
| 1 | Model | STRING | NO | Computed in source (transform kind not classified). Formula: `,'IMDynamicBook'`. (Tier 2 — literal) |
| 2 | ModelParameter | STRING | NO | Computed in source (transform kind not classified). Formula: `,'IMDynamicBook' as Model ,'askLegs'`. (Tier 2 — literal) |
| 3 | Value | STRING | NO | Computed in source (transform kind not classified). Formula: `,'IMDynamicBook' as Model ,'askLegs' as ModelParameter , cast(10 as string)`. (Tier 2 — literal) |
| 4 | UpdateTime | TIMESTAMP | NO | Cast of upstream column. Formula: `cast ((etoro - oms)*(10 ^ Precision) as int ) Mid2MidDiff_Tick, current_timestamp()`. (Tier 2 — from `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates`, `main.bi_dealing.gold_dealing_oms_internalmarket_parameters`, `valid_parameters` (+1 more)) |
| 5 | ModelVersion | INT | NO | Computed in source (transform kind not classified). Formula: `,'IMDynamicBook' as Model ,'askLegs' as ModelParameter , cast(10 as string) AS Value ,UpdateTime ,1`. (Tier 2 — literal) |
| 6 | URL | STRING | NO | Arithmetic combination of upstream columns. Formula: `,'IMDynamicBook' as Model ,'askLegs' as ModelParameter , cast(10 as string) AS Value ,UpdateTime ,1 as ModelVersion ,'/api/db/table/Automaton'`. (Tier 2 — computed in source) |
| 7 | OmsParam | STRING | NO | Arithmetic combination of upstream columns. Formula: `,'IMDynamicBook' as Model ,'askLegs' as ModelParameter , cast(10 as string) AS Value ,UpdateTime ,1 as ModelVersion ,'/api/db/table/Automaton' as URL ,'askLegs'`. (Tier 2 — computed in source) |
| 8 | etr_ymd | DATE | NO | Arithmetic combination of upstream columns. Formula: `,'IMDynamicBook' as Model ,'askLegs' as ModelParameter , cast(10 as string) AS Value ,UpdateTime ,1 as ModelVersion ,'/api/db/table/Automaton' as URL ,'askLegs' as OmsParam ,date(UpdateTime) etr_ymd`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_dealing.gold_dealing_oms_internalmarket_parameters` | Primary | `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_oms_internalmarket_parameters.md` |
| `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_dealing.gold_dealing_oms_internalmarket_parameters
main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
        │
        ▼
main.bi_dealing.gold_dealing_oms_internalmarket_imdynamicbookfutures_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=9 runtime=9 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_dealing.gold_dealing_oms_internalmarket_parameters` (wiki: `knowledge/UC_generated/bi_dealing/<Tables|Views>/gold_dealing_oms_internalmarket_parameters.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 1/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 9 | Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: view_definition*
