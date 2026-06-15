---
object_fqn: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 20
row_count: null
generated_at: '2026-05-19T12:48:08Z'
upstreams:
- main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_nixar_beta_dailybetaprod_v.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_nixar_beta_dailybetaprod_v.sql
concept_count: 0
formula_count: 12
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 20
  unverified_columns: 0
---

# bi_output_dealing_nixar_beta_dailybetaprod_v

> View in `main.bi_dealing`. 0 business concept(s) in §2; 20 of 20 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | 079a992a-c990-4a3a-b901-af1042066afa |
| **Row count** | n/a |
| **Column count** | 20 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jan 29 07:11:25 UTC 2025 |

---

## 1. Business Meaning

`bi_output_dealing_nixar_beta_dailybetaprod_v` is a view in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nixar_beta_dailybetaprod.md`.

Of its 20 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 20 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | InstrumentName | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.InstrumentName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 1 | Date | DATE | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.Date`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 2 | SectorBeta | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorBeta`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 3 | SectorName | STRING | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 4 | SectorBeta30 | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorBeta30`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 5 | SectorBeta90 | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorBeta90`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 6 | AskClose | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.AskClose`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 7 | BidClose | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.BidClose`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 8 | InstrumentAskPctChange | DOUBLE | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.InstrumentAskPctChange`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 9 | PriceTime | TIMESTAMP | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.PriceTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 10 | SectorAskClose | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorAskClose`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 11 | SectorBidClose | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorBidClose`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 12 | SectorAskPctChange | DOUBLE | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorAskPctChange`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 13 | SectorPriceTime | TIMESTAMP | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorPriceTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 14 | InstrumentID | INT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.InstrumentID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 15 | SectorID | INT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.SectorID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 16 | Correlation30 | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.Correlation30`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 17 | Correlation | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.Correlation`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 18 | Correlation90 | FLOAT | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.Correlation90`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |
| 19 | UpdateDate | TIMESTAMP | YES | Source: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod.UpdateDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` | Primary | `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nixar_beta_dailybetaprod.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod
        │
        ▼
main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=20 runtime=20 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod` (wiki: `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_nixar_beta_dailybetaprod.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 12 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 20 TN, 0 U | Elements: 20/20 | Source: view_definition*
