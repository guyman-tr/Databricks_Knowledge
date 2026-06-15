---
object_fqn: main.bi_output.bi_ouput_v_dim_instrumenttype
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_ouput_v_dim_instrumenttype
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T15:01:29Z'
upstreams:
- main.general.bronze_etoro_dictionary_currencytype
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_ouput_v_dim_instrumenttype.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_ouput_v_dim_instrumenttype.sql
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

# bi_ouput_v_dim_instrumenttype

> View in `main.bi_output`. 0 business concept(s) in §2; 2 of 2 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_ouput_v_dim_instrumenttype` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 2 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | 9 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Nov 11 08:31:11 UTC 2025 |

---

## 1. Business Meaning

`bi_ouput_v_dim_instrumenttype` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_etoro_dictionary_currencytype` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

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
| 1 | InstrumentTypeID | INT | YES | Primary key identifying the asset class. 1=Forex, 2=Commodity, 3=CFD (legacy), 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Foreign key in Dictionary.Currency. See [Currency Type](_glossary.md#currency-type). (Dictionary.CurrencyType) (Tier 1 — inherited from main.general.bronze_etoro_dictionary_currencytype). |
| 1 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `, COALESCE(di.InstrumentType , Name)`. (Tier 2 — from `main.general.bronze_etoro_dictionary_currencytype`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_etoro_dictionary_currencytype` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_etoro_dictionary_currencytype
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
        │
        ▼
main.bi_output.bi_ouput_v_dim_instrumenttype   ←── this object
        │
        ▼
main.bi_output.bi_output_vg_revenue
main.bi_output.bi_output_vg_volume_amount
main.bi_output_stg.vg_ddr_fact_revenue
... (6 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=2 runtime=2 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_etoro_dictionary_currencytype` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CurrencyType.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output.bi_output_vg_revenue`
- `main.bi_output.bi_output_vg_volume_amount`
- `main.bi_output_stg.vg_ddr_fact_revenue`
- `main.etoro_kpi.ddr_pnl_v`
- `main.etoro_kpi.ddr_revenue_v`
- `main.etoro_kpi.ddr_trading_volumes_and_amounts_v`
- `main.etoro_kpi.vg_ddr_revenue`
- `main.etoro_kpi_stg.bi_output_vg_revenue_slim`
- `main.etoro_kpi_stg.ddr_revenue_dor`

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
