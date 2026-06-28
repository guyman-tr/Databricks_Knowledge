---
object_fqn: main.bi_output.vg_fullbincodelist
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_fullbincodelist
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: '2026-06-19T14:36:07Z'
upstreams:
- main.general.bronze_etoro_dictionary_countrybin
- main.general.bronze_etoro_dictionary_country
- main.general.bronze_etoro_dictionary_cardtype
- main.billing.bronze_etoro_billing_badbin
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fullbincodelist.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_fullbincodelist.sql
concept_count: 0
formula_count: 7
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 3
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_fullbincodelist

> View in `main.bi_output`. 0 business concept(s) in §2; 7 of 7 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_fullbincodelist` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 7 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Tue Apr 14 13:41:23 UTC 2026 |

---

## 1. Business Meaning

`vg_fullbincodelist` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_etoro_dictionary_countrybin` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 7 columns: 4 inherit byte-for-byte from upstream wikis (Tier 1), 3 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | bin_code | INT | YES | Bank Identification Number — first 6 or 8 digits of the card number that identify the issuing bank and card product. From CountryBin6 (6-digit legacy) or CountryBin8 (8-digit modern). (renamed from `BinCode`) (Tier 1 — inherited from main.general.bronze_etoro_dictionary_countrybin). |
| 1 | issuing_country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_country`) |
| 2 | issuer_name | STRING | YES | Name of the bank that issued the card. Used in BackOffice reporting and payment routing decisions. (renamed from `IssuingBank`) (Tier 1 — inherited from main.general.bronze_etoro_dictionary_countrybin). |
| 3 | card_type | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_cardtype`) |
| 4 | card_subtype | STRING | YES | Sub-classification within the card type (e.g., debit, credit, corporate). (renamed from `CardSubType`) (Tier 1 — inherited from main.general.bronze_etoro_dictionary_countrybin). |
| 5 | aft_support | BOOLEAN | YES | Whether this BIN supports Account Funding Transactions (AFT) — Visa's protocol for pulling funds from a card to fund an account. Used in withdrawal-to-card routing. (renamed from `SupportsAFT`) (Tier 1 — inherited from main.general.bronze_etoro_dictionary_countrybin). |
| 6 | is_bad_bin | BOOLEAN | NO | Computed flag (CASE expression in source). Formula: `CASE WHEN BinFrom IS NOT NULL THEN TRUE ELSE FALSE END`. (Tier 2 — from `main.billing.bronze_etoro_billing_badbin`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_etoro_dictionary_countrybin` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.general.bronze_etoro_dictionary_cardtype` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md` |
| `main.billing.bronze_etoro_billing_badbin` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_etoro_dictionary_countrybin
main.general.bronze_etoro_dictionary_country
main.general.bronze_etoro_dictionary_cardtype
... (1 more upstream(s))
        │
        ▼
main.bi_output.vg_fullbincodelist   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=7 runtime=7 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_etoro_dictionary_countrybin` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Views/Dictionary.CountryBin.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 3/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 7 | Tiers: 4 T1, 3 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: view_definition*
