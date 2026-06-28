---
object_fqn: main.bi_output.nmi_by_portfoliopi_new
object_type: MATERIALIZED_VIEW
producer_kind: sp_or_sql
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.nmi_by_portfoliopi_new
schema: bi_output
framework: uc-pipeline-doc
table_type: MATERIALIZED_VIEW
format: null
column_count: 7
row_count: null
generated_at: '2026-06-19T14:36:00Z'
upstreams:
- main.bi_db.bronze_etoro_dwh_v_historymirrorhourly
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.general.bronze_etoro_backoffice_customer
- main.general.bronze_etoro_customer_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
writer:
  kind: sp_or_sql
  path: knowledge/UC_generated/bi_output/_discovery/source_code/nmi_by_portfoliopi_new.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/nmi_by_portfoliopi_new.sql
concept_count: 3
formula_count: 7
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 7
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# nmi_by_portfoliopi_new

> Table (sp/sql writer) in `main.bi_output`. 3 business concept(s) in §2; 7 of 7 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.nmi_by_portfoliopi_new` |
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Owner** | olegab@etoro.com |
| **Row count** | n/a |
| **Column count** | 7 |
| **Concepts** | 3 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Thu Feb 20 20:43:00 UTC 2025 |

---

## 1. Business Meaning

`nmi_by_portfoliopi_new` is a table (SP/SQL writer) in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_v_historymirrorhourly.md`. Additional upstreams: 4 object(s), listed in §5 Lineage.

Of its 7 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 7 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `CopyType` discriminator: `AccountTypeID = 9` → set to '         ' else '  '
**What**: Computed flag on `CopyType` set to `'         '` when the predicates below hold, else `'  '`.
**Columns Involved**: `CopyType`
**Rules**:
- `AccountTypeID = 9`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/nmi_by_portfoliopi_new.sql` bi_output.sql L19-L22

### 2.2 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc.CountryID = cc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/nmi_by_portfoliopi_new.sql` L63
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.3 Dim lookup via alias `bm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `bc.ManagerID = bm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/nmi_by_portfoliopi_new.sql` L65
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `CopyType = 1`-style filters on the precomputed flag columns (`CopyType`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_country`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `dc.CountryID = cc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `bc.ManagerID = bm.ManagerID` | Lookup via alias `bm` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ParentCID | INT | YES | Direct passthrough from upstream. Formula: `mirror.ParentCID`. (Tier 2 — computed in source) |
| 1 | CopyType | STRING | YES | `CopyType` discriminator: `AccountTypeID = 9` → set to '         ' else '  '. Formula: `ParentUserName,case when AccountTypeID = 9 then 'Portfolio' else 'PI' END`. (Tier 2 — from `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly`) |
| 2 | UserName | STRING | YES | Direct passthrough from upstream. Formula: `mirror.ParentUserName`. (Tier 2 — computed in source) |
| 3 | Region | STRING | YES | Direct passthrough from upstream. Formula: `Region`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 4 | MoneyIn | DECIMAL | YES | Cast of upstream column. Formula: `CAST (MoneyIn AS Decimal (12, 2)) MoneyIn`. (Tier 2 — computed in source) |
| 5 | MoneyOut | DECIMAL | YES | Cast of upstream column. Formula: `CAST (MoneyOut AS Decimal (12, 2)) MoneyOut`. (Tier 2 — computed in source) |
| 6 | NetMoneyIn | DECIMAL | YES | Cast of upstream column. Formula: `CAST ((MoneyIn + MoneyOut) AS Decimal (12, 2)) NetMoneyIn`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | Primary | `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_v_historymirrorhourly.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.general.bronze_etoro_backoffice_customer` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Customer.md` |
| `main.general.bronze_etoro_customer_customer_masked` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_etoro_dwh_v_historymirrorhourly
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
main.general.bronze_etoro_backoffice_customer
... (2 more upstream(s))
        │
        ▼
main.bi_output.nmi_by_portfoliopi_new   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=7 runtime=7 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` (wiki: `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_v_historymirrorhourly.md`)
- **JOIN/UNION upstreams**: 4 additional object(s)
- **Wiki coverage**: 4/4 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 3 | Formulas: 7 | Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: sp_or_sql*
