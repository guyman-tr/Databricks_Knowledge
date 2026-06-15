---
object_fqn: main.etoro_kpi.customer_segments_mail_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.customer_segments_mail_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 25
row_count: null
generated_at: '2026-05-19T15:20:35Z'
upstreams:
- main.bi_output.bi_output_marketing_sfmc_sfmc_report
- main.mixpanel.login_events
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/customer_segments_mail_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/customer_segments_mail_v.sql
concept_count: 0
formula_count: 25
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 24
  unverified_columns: 0
---

# customer_segments_mail_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 25 of 25 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.customer_segments_mail_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 25 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Apr 16 09:29:04 UTC 2026 |

---

## 1. Business Meaning

`customer_segments_mail_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_marketing_sfmc_sfmc_report` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_marketing_sfmc_sfmc_report.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 25 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 24 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | SubscriberID | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.SubscriberID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 1 | GCID | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.GCID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 2 | SentTime | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.SentTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 3 | SendDateID | INT | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.SendDateID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 4 | Subject | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.Subject`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 5 | SendID | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.SendID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 6 | EmailName | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.EmailName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 7 | CampaignGroup | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CampaignGroup`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 8 | CampaignSubGroup | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CampaignSubGroup`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 9 | CampaignName | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CampaignName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 10 | CampaignNumber | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CampaignNumber`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 11 | CountOpen | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CountOpen`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 12 | UniqueOpen | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.UniqueOpen`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 13 | CountClicks | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CountClicks`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 14 | UniqueClicks | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.UniqueClicks`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 15 | CountBounce | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CountBounce`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 16 | Delivered | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.Delivered`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 17 | OpenDate | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.OpenDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 18 | ClickDate | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.ClickDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 19 | CountSend | LONG | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.CountSend`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 20 | LSD | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.LSD`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 21 | last_login | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `le.last_login`. (Tier 2 — computed in source) |
| 22 | etr_y | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.etr_y`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 23 | etr_ym | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.etr_ym`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |
| 24 | etr_ymd | STRING | YES | Source: `main.bi_output.bi_output_marketing_sfmc_sfmc_report.etr_ymd`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.bi_output.bi_output_marketing_sfmc_sfmc_report`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_marketing_sfmc_sfmc_report.md` |
| `main.mixpanel.login_events` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_marketing_sfmc_sfmc_report
main.mixpanel.login_events
        │
        ▼
main.etoro_kpi.customer_segments_mail_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=25 runtime=25 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_marketing_sfmc_sfmc_report` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_marketing_sfmc_sfmc_report.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 0/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 25 | Tiers: 0 T1, 1 T2, 0 T3, 0 T4, 0 T5, 24 TN, 0 U | Elements: 25/25 | Source: view_definition*
