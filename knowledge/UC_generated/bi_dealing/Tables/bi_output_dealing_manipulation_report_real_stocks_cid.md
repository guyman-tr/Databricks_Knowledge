---
object_fqn: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid
object_type: EXTERNAL
producer_kind: notebook
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid
schema: bi_dealing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:48:06Z'
upstreams:
- main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm
- main.trading.bronze_etoro_trade_instrumentmetadata
- main.bi_dealing_stg.tmp_instrumentmetadata_snapshot
- main.dealing.candles_get_spreaded_price_candle60min_splitted
- main.dwh.dim_position
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
writer:
  kind: notebook
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_manipulation_report_real_stocks_cid.py
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/bi_output_dealing_manipulation_report_real_stocks_cid.py
concept_count: 0
formula_count: 0
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 21
---

# bi_output_dealing_manipulation_report_real_stocks_cid

> Table (notebook writer) in `main.bi_dealing`. 0 business concept(s) in §2; 0 of 21 columns documented from anchored evidence; 21 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | matansa@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Wed Apr 29 00:53:09 UTC 2026 |

---

## 1. Business Meaning

`bi_output_dealing_manipulation_report_real_stocks_cid` is a table (notebook writer) in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 13 object(s), listed in §5 Lineage.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |

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
| 1 | Date | STRING | YES | Transform `unknown` for column `Date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 1 | CID | INT | YES | Transform `unknown` for column `CID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 2 | UserName | STRING | YES | Transform `unknown` for column `UserName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 3 | Country | STRING | YES | Transform `unknown` for column `Country` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 4 | Manager | STRING | YES | Transform `unknown` for column `Manager` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 5 | Regulation | STRING | YES | Transform `unknown` for column `Regulation` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 6 | Club | STRING | YES | Transform `unknown` for column `Club` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 7 | InstrumentID | INT | YES | Transform `unknown` for column `InstrumentID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 8 | InstrumentDisplayName | STRING | YES | Transform `unknown` for column `InstrumentDisplayName` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 9 | InstrumentType | STRING | YES | Transform `unknown` for column `InstrumentType` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 10 | NumberOfTrades | LONG | YES | Transform `unknown` for column `NumberOfTrades` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 11 | AllTrades | LONG | YES | Transform `unknown` for column `AllTrades` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 12 | AvgDailyOpen | DECIMAL | YES | Transform `unknown` for column `AvgDailyOpen` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 13 | Volume | LONG | YES | Transform `unknown` for column `Volume` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 14 | Units | DECIMAL | YES | Transform `unknown` for column `Units` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 15 | PercentOfAvg30Days | DECIMAL | YES | Transform `unknown` for column `PercentOfAvg30Days` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 16 | PercentOfTotalTrades | DECIMAL | YES | Transform `unknown` for column `PercentOfTotalTrades` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 17 | UpdateDate | TIMESTAMP | YES | Transform `unknown` for column `UpdateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 18 | etr_y | STRING | YES | Transform `unknown` for column `etr_y` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 19 | etr_ym | STRING | YES | Transform `unknown` for column `etr_ym` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 20 | etr_ymd | STRING | YES | Transform `unknown` for column `etr_ymd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md` |
| `main.bi_dealing_stg.tmp_instrumentmetadata_snapshot` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dealing.candles_get_spreaded_price_candle60min_splitted` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |

### 5.2 Pipeline ASCII Diagram

```
main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm
main.trading.bronze_etoro_trade_instrumentmetadata
main.bi_dealing_stg.tmp_instrumentmetadata_snapshot
... (11 more upstream(s))
        │
        ▼
main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.experience.vw_silver_xignite_fundamentalsdailyrange_ttm` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 13 additional object(s)
- **Wiki coverage**: 10/13 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 0 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 21 U | Elements: 21/21 | Source: notebook*
