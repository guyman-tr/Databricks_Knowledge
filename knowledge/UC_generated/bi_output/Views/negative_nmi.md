---
object_fqn: main.bi_output.negative_nmi
object_type: MATERIALIZED_VIEW
producer_kind: sp_or_sql
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.negative_nmi
schema: bi_output
framework: uc-pipeline-doc
table_type: MATERIALIZED_VIEW
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T15:01:54Z'
upstreams:
- main.general.bronze_etoro_history_credit
- main.trading.bronze_etoro_history_position_datafactory
- main.trading.silver_etoro_trade_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
writer:
  kind: sp_or_sql
  path: knowledge/UC_generated/bi_output/_discovery/source_code/negative_nmi.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/negative_nmi.sql
concept_count: 1
formula_count: 5
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 5
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# negative_nmi

> Table (sp/sql writer) in `main.bi_output`. 1 business concept(s) in §2; 5 of 5 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.negative_nmi` |
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Owner** | olegab@etoro.com |
| **Row count** | n/a |
| **Column count** | 5 |
| **Concepts** | 1 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Feb 20 20:40:54 UTC 2025 |

---

## 1. Business Meaning

`negative_nmi` is a table (SP/SQL writer) in `main.bi_output` that composes 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.general.bronze_etoro_history_credit` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md`. Additional upstreams: 3 object(s), listed in §5 Lineage.

Of its 5 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 5 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `imd` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `P0.InstrumentID = imd.InstrumentID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/negative_nmi.sql` L50
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `P0.InstrumentID = imd.InstrumentID` | Lookup via alias `imd` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SymbolFull | STRING | YES | Direct passthrough from upstream. Formula: `SymbolFull`. (Tier 2 — computed in source) |
| 1 | InstrumentDisplayName | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentDisplayName`. (Tier 2 — computed in source) |
| 2 | MoneyIn | DECIMAL | YES | Cast of upstream column. Formula: `CAST(MoneyIn AS Decimal(12, 2))`. (Tier 2 — computed in source) |
| 3 | MoneyOut | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `SUM( CASE WHEN CreditTypeID = 4 THEN Payment * -1 ELSE 0 END )`. (Tier 2 — from `main.general.bronze_etoro_history_credit`) |
| 4 | NetMoneyIn | DECIMAL | YES | Cast of upstream column. Formula: `CAST((MoneyIn + MoneyOut) AS Decimal(12, 2))`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.general.bronze_etoro_history_credit` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md` |
| `main.trading.bronze_etoro_history_position_datafactory` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Position_DataFactory.md` |
| `main.trading.silver_etoro_trade_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

### 5.2 Pipeline ASCII Diagram

```
main.general.bronze_etoro_history_credit
main.trading.bronze_etoro_history_position_datafactory
main.trading.silver_etoro_trade_position
... (1 more upstream(s))
        │
        ▼
main.bi_output.negative_nmi   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=5 runtime=5 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.general.bronze_etoro_history_credit` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md`)
- **JOIN/UNION upstreams**: 3 additional object(s)
- **Wiki coverage**: 2/3 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 1 | Formulas: 5 | Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: sp_or_sql*
