---
object_fqn: main.bi_output.funded
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.funded
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 2
row_count: null
generated_at: '2026-06-19T14:35:59Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/funded.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/funded.sql
concept_count: 0
formula_count: 0
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 2
---

# funded

> View in `main.bi_output`. 0 business concept(s) in §2; 0 of 2 columns documented from anchored evidence; 2 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.funded` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 2 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Thu Oct 10 08:29:46 UTC 2024 |

---

## 1. Business Meaning

`funded` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md`.

Of its 2 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | Year | INT | YES | Transform `unknown` for column `Year` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | CID | LONG | YES | Transform `passthrough` for column `CID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata
        │
        ▼
main.bi_output.funded   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=2 runtime=2 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 0 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 2 U | Elements: 2/2 | Source: view_definition*
