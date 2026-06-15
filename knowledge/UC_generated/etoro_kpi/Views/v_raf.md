---
object_fqn: main.etoro_kpi.v_raf
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.v_raf
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 31
row_count: null
generated_at: '2026-05-19T15:20:41Z'
upstreams:
- main.experience.bronze_rafcompensations_customer_raftrackingprocessed
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.general.bronze_etoro_dictionary_playerlevel
- main.general.bronze_etoro_dictionary_regulation
- main.general.bronze_etoro_dictionary_gurustatus
- main.general.bronze_etoro_dictionary_country
- main.bi_db.bronze_etoro_customer_customermoney
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities
- main.etoro_kpi.ddr_aum_v
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf.sql
concept_count: 2
formula_count: 31
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 31
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_raf

> View in `main.etoro_kpi`. 2 business concept(s) in §2; 31 of 31 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_raf` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | nogaro@etoro.com |
| **Row count** | n/a |
| **Column count** | 31 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 13 12:29:00 UTC 2026 |

---

## 1. Business Meaning

`v_raf` is a view in `main.etoro_kpi` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 31 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 31 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `ReferringIsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `ReferringIsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `ReferringIsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf.sql` etoro_kpi.sql L29-L29
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 Dim lookup via alias `C1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `R.ReferringCID = C1.RealCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/v_raf.sql` L40,L41
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

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
| Filter on discriminator flags | Use `ReferringIsPI = 1`-style filters on the precomputed flag columns (`ReferringIsPI`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `R.ReferringCID = C1.RealCID` | Lookup via alias `C1` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReferringCID | LONG | YES | Direct passthrough from upstream. Formula: `ReferringCID`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 1 | ReferredCID | LONG | YES | Direct passthrough from upstream. Formula: `ReferredCID`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 2 | ReferringGCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 3 | ReferredGCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 4 | ReferringCompensationAmount | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `ReferringCompensationAmount / 100.0`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 5 | ReferredCompensationAmount | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `ReferredCompensationAmount / 100.0`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 6 | RafStatusID | INT | YES | Direct passthrough from upstream. Formula: `RafStatusID`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 7 | RafStatusName | STRING | YES | Direct passthrough from upstream. Formula: `RafStatusName`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 8 | CompensationDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `CompensationDate`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 9 | ProcessingDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `ProcessingDate`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 10 | FraudReason | STRING | YES | Direct passthrough from upstream. Formula: `FraudReason`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 11 | IsProcessed | INT | YES | Direct passthrough from upstream. Formula: `IsProcessed`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 12 | ReferringOrigPlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 13 | ReferringCalcPlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `CalcPlayerLevelID`. (Tier 2 — from `main.experience.bronze_rafcompensations_customer_raftrackingprocessed`) |
| 14 | ReferringPlayerLevelName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_playerlevel`) |
| 15 | ReferredOrigPlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 16 | ReferredPlayerLevelName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_playerlevel`) |
| 17 | ReferringRegulationID | INT | YES | Direct passthrough from upstream. Formula: `RegulationID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 18 | ReferredRegulationID | INT | YES | Direct passthrough from upstream. Formula: `RegulationID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 19 | ReferringRegulationName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_regulation`) |
| 20 | ReferredRegulationName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_regulation`) |
| 21 | ReferringIsPI | INT | NO | `ReferringIsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `CASE WHEN GuruStatusID > 1 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 22 | ReferringGuruStatusName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_gurustatus`) |
| 23 | ReferringCountryID | INT | YES | Direct passthrough from upstream. Formula: `CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 24 | ReferringCountry | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_country`) |
| 25 | ReferredCountryID | INT | YES | Direct passthrough from upstream. Formula: `CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 26 | ReferredCountry | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_country`) |
| 27 | ReferringRealizedEquity | DECIMAL | YES | Direct passthrough from upstream. Formula: `RealizedEquity`. (Tier 2 — from `main.bi_db.bronze_etoro_customer_customermoney`) |
| 28 | ReferredRealizedEquity | DECIMAL | YES | Direct passthrough from upstream. Formula: `RealizedEquity`. (Tier 2 — from `main.bi_db.bronze_etoro_customer_customermoney`) |
| 29 | ReferringTotalInvestedAmount | DECIMAL | YES | Direct passthrough from upstream. Formula: `TotalPositionsAmount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities`) |
| 30 | ReferredTotalInvestedAmount | DECIMAL | YES | Direct passthrough from upstream. Formula: `TotalPositionsAmount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.general.bronze_etoro_dictionary_playerlevel` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerLevel.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |
| `main.general.bronze_etoro_dictionary_gurustatus` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.GuruStatus.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |
| `main.bi_db.bronze_etoro_customer_customermoney` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Liabilities.md` |
| `main.etoro_kpi.ddr_aum_v` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ddr_aum_v.md` |

### 5.2 Pipeline ASCII Diagram

```
main.experience.bronze_rafcompensations_customer_raftrackingprocessed
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.general.bronze_etoro_dictionary_playerlevel
... (6 more upstream(s))
        │
        ▼
main.etoro_kpi.v_raf   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=31 runtime=31 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.experience.bronze_rafcompensations_customer_raftrackingprocessed` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 8/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 31 | Tiers: 0 T1, 31 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 31/31 | Source: view_definition*
