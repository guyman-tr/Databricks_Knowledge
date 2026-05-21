---
object_fqn: main.etoro_kpi_prep.v_instrument_conversion_rates_dwh
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_instrument_conversion_rates_dwh
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:26:25Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_instrument_conversion_rates_dwh.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_instrument_conversion_rates_dwh.sql
concept_count: 2
formula_count: 12
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 12
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_instrument_conversion_rates_dwh

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 12 of 12 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_instrument_conversion_rates_dwh` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 12 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 12 15:11:42 UTC 2026 |

---

## 1. Business Meaning

`v_instrument_conversion_rates_dwh` is a view in `main.etoro_kpi_prep` that composes 1 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 12 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 12 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `Pair` → `gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_instrument` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `Pair.InstrumentID = LatestP.InstrumentID     AND LatestP.DateID = ds.DateID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_instrument_conversion_rates_dwh.sql` L79,L85,L93
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`

### 2.2 Filter on scope `LatestDailyPrices`: `rn = 1`
**What**: `WHERE` clause at the top of scope `LatestDailyPrices` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `rn`
**Rules**:
- `rn = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_instrument_conversion_rates_dwh.sql` L29

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_instrument`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Pair.InstrumentID = LatestP.InstrumentID     AND LatestP.DateID = ds.DateID` | Lookup via alias `Pair` |

### 3.4 Gotchas

- Scope `LatestDailyPrices` applies `rn = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- FIX: shift DateID forward by 1 day to align with Synapse convention -- End-of-day-N price is assigned to DateID N+1 CAST(DATE_FORMAT(DATE_ADD(etr_ymd, 1), 'yyyyMMdd') AS INT) AS Dat…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 1 | etr_ymd | DATE | YES | Function call computed in source. Formula: `DATE_ADD(etr_ymd, 1)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 2 | InstrumentID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 3 | SellCurrency | STRING | YES | Direct passthrough from upstream. Formula: `SellCurrency`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 4 | InstrumentTypeID | INT | YES | Direct passthrough from upstream. Formula: `InstrumentTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 5 | InstrumentType | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentType`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 6 | Name | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 7 | InstrumentDisplayName | STRING | YES | Direct passthrough from upstream. Formula: `InstrumentDisplayName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`) |
| 8 | ConversionRate_Buy_Spreaded | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CAST(CASE WHEN SellCurrencyID = 1 THEN 1.00 WHEN BuyCurrencyID = 1 THEN 1.00 / RateBidSpreaded WHEN (BuyCurrencyID != 1 AND SellCurrencyID != 1) …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 9 | ConversionRate_Sell_Spreaded | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CAST(CASE WHEN SellCurrencyID = 1 THEN 1.00 WHEN BuyCurrencyID = 1 THEN 1.00 / RateAskSpreaded WHEN (BuyCurrencyID != 1 AND SellCurrencyID != 1) …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 10 | ConversionRate_Buy | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CAST(CASE WHEN SellCurrencyID = 1 THEN 1.00 WHEN BuyCurrencyID = 1 THEN 1.00 / RateBid WHEN (BuyCurrencyID != 1 AND SellCurrencyID != 1) …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |
| 11 | ConversionRate_Sell | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `CAST(CASE WHEN SellCurrencyID = 1 THEN 1.00 WHEN BuyCurrencyID = 1 THEN 1.00 / RateAsk WHEN (BuyCurrencyID != 1 AND SellCurrencyID != 1) …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
        │
        ▼
main.etoro_kpi_prep.v_instrument_conversion_rates_dwh   ←── this object
        │
        ▼
main.etoro_kpi_prep_stg.v_ddr_mimo_emoney
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=12 runtime=12 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep_stg.v_ddr_mimo_emoney`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 12 | Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 12/12 | Source: view_definition*
