---
object_fqn: main.bi_dealing.newhedgedash_email_csv
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.newhedgedash_email_csv
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:48:17Z'
upstreams:
- main.bi_dealing.bi_output_dealing_nhd_dashboard
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/newhedgedash_email_csv.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/newhedgedash_email_csv.sql
concept_count: 0
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 21
  unverified_columns: 0
---

# newhedgedash_email_csv

> View in `main.bi_dealing`. 0 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.newhedgedash_email_csv` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun May 11 08:05:01 UTC 2025 |

---

## 1. Business Meaning

`newhedgedash_email_csv` is a view in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_dealing.bi_output_dealing_nhd_dashboard` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nhd_dashboard.md`.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 21 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_dealing.bi_output_dealing_nhd_dashboard` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | Date | TIMESTAMP | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Date`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 1 | HS | INT | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.HS`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 2 | LiquidityAccountID | INT | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.LiquidityAccountID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 3 | LiquidityAccountName | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.LiquidityAccountName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 4 | INS | INT | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.INS`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 5 | InstrumentType | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.InstrumentType`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 6 | Symbol | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Symbol`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 7 | Clients_Units_Buy | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_Units_Buy`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 8 | Clients_Units_Sell | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_Units_Sell`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 9 | Clients_Units | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_Units`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 10 | eToro_Units | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.eToro_Units`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 11 | Diff_Units | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Diff_Units`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 12 | Clients_NOPUSD_Buy | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_NOPUSD_Buy`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 13 | Clients_NOPUSD_Sell | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_NOPUSD_Sell`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 14 | Clients_NOPUSD | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Clients_NOPUSD`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 15 | eToro_NOPUSD | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.eToro_NOPUSD`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 16 | Uncovered_NOP | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Uncovered_NOP`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 17 | ISINCode | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.ISINCode`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 18 | Ask | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Ask`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 19 | Bid | DECIMAL | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.Bid`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |
| 20 | UpdateDate | TIMESTAMP | YES | Source: `main.bi_dealing.bi_output_dealing_nhd_dashboard.UpdateDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nhd_dashboard`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_dealing.bi_output_dealing_nhd_dashboard` | Primary | `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nhd_dashboard.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_dealing.bi_output_dealing_nhd_dashboard
        │
        ▼
main.bi_dealing.newhedgedash_email_csv   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_dealing.bi_output_dealing_nhd_dashboard` (wiki: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nhd_dashboard.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 21 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 21 TN, 0 U | Elements: 21/21 | Source: view_definition*
