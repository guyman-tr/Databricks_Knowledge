---
object_fqn: main.bi_output.bi_output_deltaapp_subscription_view
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_deltaapp_subscription_view
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T15:01:35Z'
upstreams:
- main.bi_db.bronze_deltaapp_bronze_subscriptions
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_deltaapp_subscription_view.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_deltaapp_subscription_view.sql
concept_count: 0
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_deltaapp_subscription_view

> View in `main.bi_output`. 0 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_deltaapp_subscription_view` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Nov 23 08:59:06 UTC 2025 |

---

## 1. Business Meaning

`bi_output_deltaapp_subscription_view` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_deltaapp_bronze_subscriptions` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_deltaapp_bronze_subscriptions.md`.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | user_id | STRING | YES | Direct passthrough from upstream. Formula: `data.user_id`. (Tier 2 — computed in source) |
| 1 | event_date | STRING | YES | Direct passthrough from upstream. Formula: `data.event_date`. (Tier 2 — computed in source) |
| 2 | account_id | STRING | YES | Direct passthrough from upstream. Formula: `data.account_id`. (Tier 2 — computed in source) |
| 3 | event_origin | STRING | YES | Direct passthrough from upstream. Formula: `data.event_origin`. (Tier 2 — computed in source) |
| 4 | event_id | STRING | YES | Direct passthrough from upstream. Formula: `data.event_id`. (Tier 2 — computed in source) |
| 5 | event_type | STRING | YES | Direct passthrough from upstream. Formula: `data.event_type`. (Tier 2 — computed in source) |
| 6 | event_status | STRING | YES | Direct passthrough from upstream. Formula: `data.event_status`. (Tier 2 — computed in source) |
| 7 | customer_id | STRING | YES | Direct passthrough from upstream. Formula: `data.customer_id`. (Tier 2 — computed in source) |
| 8 | product_id | STRING | YES | Direct passthrough from upstream. Formula: `data.product_id`. (Tier 2 — computed in source) |
| 9 | price_id | STRING | YES | Direct passthrough from upstream. Formula: `data.price_id`. (Tier 2 — computed in source) |
| 10 | subscription_interval | STRING | YES | Direct passthrough from upstream. Formula: `data.subscription_interval`. (Tier 2 — computed in source) |
| 11 | subscription_type | STRING | YES | Direct passthrough from upstream. Formula: `data.subscription_type`. (Tier 2 — computed in source) |
| 12 | subscription_plan_id | STRING | YES | Direct passthrough from upstream. Formula: `data.subscription_plan_id`. (Tier 2 — computed in source) |
| 13 | period_start_date | STRING | YES | Direct passthrough from upstream. Formula: `data.period_start_date`. (Tier 2 — computed in source) |
| 14 | period_end_date | STRING | YES | Direct passthrough from upstream. Formula: `data.period_end_date`. (Tier 2 — computed in source) |
| 15 | trial_active | STRING | YES | Direct passthrough from upstream. Formula: `data.trial_active`. (Tier 2 — computed in source) |
| 16 | payment_amount | FLOAT | YES | Direct passthrough from upstream. Formula: `data.payment_amount`. (Tier 2 — computed in source) |
| 17 | payment_amount_received | FLOAT | YES | Direct passthrough from upstream. Formula: `data.payment_amount_received`. (Tier 2 — computed in source) |
| 18 | payment_amount_refunded | FLOAT | YES | Direct passthrough from upstream. Formula: `data.payment_amount_refunded`. (Tier 2 — computed in source) |
| 19 | payment_currency | STRING | YES | Direct passthrough from upstream. Formula: `data.payment_currency`. (Tier 2 — computed in source) |
| 20 | payment_method | STRING | YES | Direct passthrough from upstream. Formula: `data.payment_method`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_deltaapp_bronze_subscriptions` | Primary | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_deltaapp_bronze_subscriptions.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_deltaapp_bronze_subscriptions
        │
        ▼
main.bi_output.bi_output_deltaapp_subscription_view   ←── this object
        │
        ▼
main.bi_output_stg.subscription
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_deltaapp_bronze_subscriptions` (wiki: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_deltaapp_bronze_subscriptions.md`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.subscription`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 21 | Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
