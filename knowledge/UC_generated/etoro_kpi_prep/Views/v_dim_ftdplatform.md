---
object_fqn: main.etoro_kpi_prep.v_dim_ftdplatform
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_dim_ftdplatform
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:26:22Z'
upstreams:
- main.bi_db.bronze_moneybusdb_dictionary_accounttypes
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_ftdplatform.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_ftdplatform.sql
concept_count: 0
formula_count: 2
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_dim_ftdplatform

> View in `main.etoro_kpi_prep`. 0 business concept(s) in §2; 2 of 2 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_ftdplatform` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 2 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 4 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 24 06:53:22 UTC 2026 |

---

## 1. Business Meaning

`v_dim_ftdplatform` is a view in `main.etoro_kpi_prep`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md`.

Of its 2 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | FTDPlatformID | INT | YES | Primary key and unique identifier for each account type. Referenced as CreditorTypeID, DebitorTypeID (MoneyBus.Transactions), AccountTypeID (MoneyBus.Withdrawals), DebitAccountTypeID/CreditAccountTypeID (MoneyBus.TransferLimits), and InitiatorAccountTypeId (MoneyBus.TransactionsGroup). Values: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type) for full business definitions. (renamed from `ID`) (Tier 1 — inherited from main.bi_db.bronze_moneybusdb_dictionary_accounttypes). |
| 1 | Name | STRING | YES | Computed flag (CASE expression in source). Formula: `, CASE WHEN FTDPlatformID = 1 THEN 'TradingPlatform' WHEN FTDPlatformID = 2 THEN 'Options' WHEN FTDPlatformID = 3 THEN 'eMoney' WHEN FTDPlatformID = 4 THEN 'MoneyFarm' ELSE Name END`. (Tier 2 — from `main.bi_db.bronze_moneybusdb_dictionary_accounttypes`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_moneybusdb_dictionary_accounttypes
        │
        ▼
main.etoro_kpi_prep.v_dim_ftdplatform   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg._tmp_cds_iban_prep
main.etoro_kpi_prep_stg._tmp_cds_population_moneyfarm
main.etoro_kpi_prep_stg._tmp_cds_population_options
... (1 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=2 runtime=2 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_moneybusdb_dictionary_accounttypes` (wiki: `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.AccountTypes.md`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep_stg._tmp_cds_iban_prep`
- `main.etoro_kpi_prep_stg._tmp_cds_population_moneyfarm`
- `main.etoro_kpi_prep_stg._tmp_cds_population_options`
- `main.etoro_kpi_prep_stg._tmp_cds_population_tp`

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 2 | Tiers: 1 T1, 1 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: view_definition*
