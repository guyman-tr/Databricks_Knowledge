---
object_fqn: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:48:12Z'
upstreams:
- main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_tables_h_pricelocks_hourly_report_v.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_tables_h_pricelocks_hourly_report_v.sql
concept_count: 0
formula_count: 8
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 3
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 5
  unverified_columns: 0
---

# bi_output_dealing_tables_h_pricelocks_hourly_report_v

> View in `main.bi_dealing`. 0 business concept(s) in §2; 8 of 8 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | olegab@etoro.com |
| **Row count** | n/a |
| **Column count** | 8 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue Feb 20 08:38:51 UTC 2024 |

---

## 1. Business Meaning

`bi_output_dealing_tables_h_pricelocks_hourly_report_v` is a view in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_tables_h_pricelocks_hourly.md`.

Of its 8 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 5 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | Date | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.DateID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`). |
| 1 | Asset | STRING | YES | Computed flag (CASE expression in source). Formula: `DateID as Date ,CASE InstrumentTypeID WHEN 1 THEN 'Currencies' WHEN 2 THEN 'Commodities' WHEN 4 THEN 'Indices' WHEN 5 THEN 'Stocks' WHEN 6 THEN 'ETF' WHEN 10 THEN 'Crypto…`. (Tier 2 — from `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`) |
| 2 | Exchange | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.Exchange`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`). |
| 3 | InstrumentID | INT | YES | Source: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.InstrumentID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`). |
| 4 | InstrumentDisplayName | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.InstrumentDisplayName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`). |
| 5 | EventName | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.EventName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`). |
| 6 | TotalLocks | LONG | YES | Computed flag (CASE expression in source). Formula: `DateID as Date ,CASE InstrumentTypeID WHEN 1 THEN 'Currencies' WHEN 2 THEN 'Commodities' WHEN 4 THEN 'Indices' WHEN 5 THEN 'Stocks' WHEN 6 THEN 'ETF' WHEN 10 THEN 'Crypto…`. (Tier 2 — from `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`) |
| 7 | TotalDuration | LONG | YES | Computed flag (CASE expression in source). Formula: `DateID as Date ,CASE InstrumentTypeID WHEN 1 THEN 'Currencies' WHEN 2 THEN 'Commodities' WHEN 4 THEN 'Indices' WHEN 5 THEN 'Stocks' WHEN 6 THEN 'ETF' WHEN 10 THEN 'Crypto…`. (Tier 2 — from `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | Primary | `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_tables_h_pricelocks_hourly.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly
        │
        ▼
main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=8 runtime=8 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` (wiki: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_tables_h_pricelocks_hourly.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 8 | Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5, 5 TN, 0 U | Elements: 8/8 | Source: view_definition*
