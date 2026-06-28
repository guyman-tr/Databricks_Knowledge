---
object_fqn: main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
object_type: EXTERNAL
producer_kind: notebook
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
schema: bi_output
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 19
row_count: null
generated_at: '2026-06-19T14:35:51Z'
upstreams:
- main.trading.bronze_etoro_history_position_datafactory
- main.trading.bronze_etoro_trade_instrumentmetadata
- main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
writer:
  kind: notebook
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_regtechops_wash_trading_alerts_daily.py
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_regtechops_wash_trading_alerts_daily.py
concept_count: 0
formula_count: 19
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 19
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_regtechops_wash_trading_alerts_daily

> Table (notebook writer) in `main.bi_output`. 0 business concept(s) in §2; 19 of 19 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_regtechops_wash_trading_alerts_daily` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | meravhu@etoro.com |
| **Row count** | n/a |
| **Column count** | 19 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Mon May 04 11:10:18 UTC 2026 |

---

## 1. Business Meaning

`bi_output_regtechops_wash_trading_alerts_daily` is a table (notebook writer) in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.trading.bronze_etoro_history_position_datafactory` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Position_DataFactory.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 19 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 19 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | snapshot_date | DATE | YES | Arithmetic combination of upstream columns. Formula: `# MAGIC # MAGIC -- Final combined scoring # MAGIC scored_alerts AS ( # MAGIC SELECT # MAGIC CURRENT_DATE()`. (Tier 2 — computed in source) |
| 1 | CID | INT | YES | Computed in source (transform kind not classified). Formula: `# MAGIC COALESCE(w.CID, r.CID)`. (Tier 2 — literal) |
| 2 | InstrumentID | INT | YES | Computed in source (transform kind not classified). Formula: `# MAGIC COALESCE(w.InstrumentID, r.InstrumentID)`. (Tier 2 — literal) |
| 3 | InstrumentDisplayName | STRING | YES | Computed in source (transform kind not classified). Formula: `# MAGIC MAX(InstrumentDisplayName)`. (Tier 2 — literal) |
| 4 | Symbol | STRING | YES | Computed in source (transform kind not classified). Formula: `# MAGIC MAX(Symbol)`. (Tier 2 — literal) |
| 5 | wash_pair_count | INT | YES | Arithmetic combination of upstream columns. Formula: `# MAGIC COUNT(*)`. (Tier 2 — computed in source) |
| 6 | roundtrip_count | INT | YES | Arithmetic combination of upstream columns. Formula: `# MAGIC COUNT(*)`. (Tier 2 — computed in source) |
| 7 | total_volume | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `# MAGIC SUM(buy_amount + sell_amount)`. (Tier 2 — computed in source) |
| 8 | avg_time_between_pairs | DOUBLE | YES | Computed in source (transform kind not classified). Formula: `# MAGIC AVG(time_diff_minutes)`. (Tier 2 — literal) |
| 9 | avg_hold_minutes | DOUBLE | YES | Computed in source (transform kind not classified). Formula: `# MAGIC AVG(hold_duration_minutes)`. (Tier 2 — literal) |
| 10 | first_detected | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `# MAGIC MIN(buy_open_time)`. (Tier 2 — literal) |
| 11 | last_detected | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `# MAGIC MAX(GREATEST(buy_open_time, sell_open_time))`. (Tier 2 — literal) |
| 12 | risk_score | INT | YES | Arithmetic combination of upstream columns. Formula: `# MAGIC CAST(LEAST(100, ROUND( # MAGIC LEAST(40, COALESCE(w.wash_pair_count, 0) * 8) + # MAGIC LEAST(35, COALESCE(r.roundtrip_count, 0) * 5) + # MAGIC LEAST…`. (Tier 2 — computed in source) |
| 13 | risk_level | STRING | YES | Computed flag (CASE expression in source). Formula: `# MAGIC CASE # MAGIC WHEN LEAST(100, ROUND( # MAGIC LEAST(40, COALESCE(w.wash_pair_count, 0) * 8) + # MAGIC LEAST(35, COALESCE(r.roundtrip_count, 0)…`. (Tier 2 — computed in source) |
| 14 | detection_type | STRING | YES | Computed flag (CASE expression in source). Formula: `# MAGIC CASE # MAGIC WHEN COALESCE(w.wash_pair_count, 0) > 0 AND COALESCE(r.roundtrip_count, 0) > 0 THEN 'Wash Trading + Round-Trip' # MAGIC WHEN COALESCE(w.wash_pair_c…`. (Tier 2 — computed in source) |
| 15 | alert_status | STRING | YES | Computed in source (transform kind not classified). Formula: `# MAGIC 'New'`. (Tier 2 — literal) |
| 16 | assigned_to | STRING | YES | Computed in source (transform kind not classified). Formula: `# MAGIC CAST(NULL AS STRING)`. (Tier 2 — literal) |
| 17 | created_at | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `# MAGIC CURRENT_TIMESTAMP()`. (Tier 2 — literal) |
| 18 | updated_at | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `# MAGIC CURRENT_TIMESTAMP()`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.trading.bronze_etoro_history_position_datafactory` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Position_DataFactory.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md` |
| `main.bi_output.bi_output_regtechops_wash_trading_alerts_daily` | JOIN/UNION | `knowledge\UC_generated\bi_output\Tables\bi_output_regtechops_wash_trading_alerts_daily.md` |

### 5.2 Pipeline ASCII Diagram

```
main.trading.bronze_etoro_history_position_datafactory
main.trading.bronze_etoro_trade_instrumentmetadata
main.bi_output.bi_output_regtechops_wash_trading_alerts_daily
        │
        ▼
main.bi_output.bi_output_regtechops_wash_trading_alerts_daily   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=19 runtime=19 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.trading.bronze_etoro_history_position_datafactory` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Position_DataFactory.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 19 | Tiers: 0 T1, 19 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 19/19 | Source: notebook*
