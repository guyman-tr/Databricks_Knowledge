---
object_fqn: main.bi_output.bi_output_wf_view
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_wf_view
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 18
row_count: null
generated_at: '2026-06-19T14:35:58Z'
upstreams:
- main.bi_db.bronze_wealth_france_wealth_france_users_data
- main.bi_db.bronze_sub_accounts_accounts
- main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_wf_view.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_wf_view.sql
concept_count: 0
formula_count: 18
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 18
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_wf_view

> View in `main.bi_output`. 0 business concept(s) in §2; 18 of 18 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_wf_view` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 18 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-06-19 |
| **Created** | Sun Sep 14 05:21:53 UTC 2025 |

---

## 1. Business Meaning

`bi_output_wf_view` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_wealth_france_wealth_france_users_data` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_wealth_france_wealth_france_users_data.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 18 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 18 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | GCID | LONG | YES | Direct passthrough from upstream. Formula: `gcid`. (Tier 2 — computed in source) |
| 1 | ClientID | STRING | YES | Direct passthrough from upstream. Formula: `ClientId`. (Tier 2 — computed in source) |
| 2 | ContractNumber | STRING | YES | Direct passthrough from upstream. Formula: `contractNo`. (Tier 2 — computed in source) |
| 3 | ProductCode | STRING | YES | Direct passthrough from upstream. Formula: `productCode`. (Tier 2 — computed in source) |
| 4 | ProductName | STRING | YES | Direct passthrough from upstream. Formula: `productName`. (Tier 2 — computed in source) |
| 5 | SubscriptionDate | DATE | YES | Direct passthrough from upstream. Formula: `subscriptionDate`. (Tier 2 — computed in source) |
| 6 | ContractStatus | STRING | YES | Direct passthrough from upstream. Formula: `contractStatus`. (Tier 2 — computed in source) |
| 7 | ReferenceCurrency | STRING | YES | Direct passthrough from upstream. Formula: `referenceCurrency`. (Tier 2 — computed in source) |
| 8 | SavingValue | FLOAT | YES | Direct passthrough from upstream. Formula: `savingsValue`. (Tier 2 — computed in source) |
| 9 | SavingValueInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `((Bid+Ask)/2) * savingsValue`. (Tier 2 — computed in source) |
| 10 | SavingsValueDate | DATE | YES | Direct passthrough from upstream. Formula: `savingsValueDate`. (Tier 2 — computed in source) |
| 11 | ISIN | STRING | YES | Direct passthrough from upstream. Formula: `isin`. (Tier 2 — computed in source) |
| 12 | Percent | FLOAT | YES | Direct passthrough from upstream. Formula: `percent`. (Tier 2 — computed in source) |
| 13 | Amount | FLOAT | YES | Direct passthrough from upstream. Formula: `amount`. (Tier 2 — computed in source) |
| 14 | AmountInDollar | DOUBLE | YES | Arithmetic combination of upstream columns. Formula: `((Bid+Ask)/2) * amount`. (Tier 2 — computed in source) |
| 15 | NumberOfShares | FLOAT | YES | Direct passthrough from upstream. Formula: `numberOfShares`. (Tier 2 — computed in source) |
| 16 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `currency`. (Tier 2 — computed in source) |
| 17 | ExchangeRate | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `((Bid+Ask)/2)`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_wealth_france_wealth_france_users_data` | Primary | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_wealth_france_wealth_france_users_data.md` |
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN/UNION | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_sub_accounts_accounts.md` |
| `main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_wealth_france_wealth_france_users_data
main.bi_db.bronze_sub_accounts_accounts
main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit
        │
        ▼
main.bi_output.bi_output_wf_view   ←── this object
        │
        ▼
main.experience.rnd_output_experience_clubactivitieseod
main.experience.rnd_output_experience_clubactivitieseod_int
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=18 runtime=18 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_wealth_france_wealth_france_users_data` (wiki: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_wealth_france_wealth_france_users_data.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 1/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.experience.rnd_output_experience_clubactivitieseod`
- `main.experience.rnd_output_experience_clubactivitieseod_int`

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 18 | Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 18/18 | Source: view_definition*
