---
object_fqn: main.bi_dealing.v_hschangesummarylog_yesterday_email_csv
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_dealing.v_hschangesummarylog_yesterday_email_csv
schema: bi_dealing
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:48:17Z'
upstreams:
- main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_dealing/_discovery/source_code/v_hschangesummarylog_yesterday_email_csv.sql
  source_code_snapshot: knowledge/UC_generated/bi_dealing/_discovery/source_code/v_hschangesummarylog_yesterday_email_csv.sql
concept_count: 0
formula_count: 6
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 2
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_hschangesummarylog_yesterday_email_csv

> View in `main.bi_dealing`. 0 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.v_hschangesummarylog_yesterday_email_csv` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | arielka@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Dec 22 07:48:40 UTC 2025 |

---

## 1. Business Meaning

`v_hschangesummarylog_yesterday_email_csv` is a view in `main.bi_dealing`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md`.

Of its 6 columns: 4 inherit byte-for-byte from upstream wikis (Tier 1), 2 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | ID | LONG | YES | Surrogate primary key. Returned by scope_identity() from PositionsHedgeServerChangeSummaryLogInsert and passed as OperationSummaryID to MovePositionsHedgeServers/MovePositionsHedgeServersByRerouteService. Referenced by Trade.PositionsHedgeServerChangeLog.OperationSummaryID (FK) (Tier 1 — inherited from main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog). |
| 1 | StartTime | TIMESTAMP | YES | UTC timestamp when the reroute operation began. Set at INSERT via getutcdate() in PositionsHedgeServerChangeSummaryLogInsert. Marks the start of the batch (Tier 1 — inherited from main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog). |
| 2 | EndTime | TIMESTAMP | YES | UTC timestamp when the reroute operation completed. Initially NULL; updated by MovePositionsHedgeServers and MovePositionsHedgeServersByRerouteService on successful COMMIT. Difference from StartTime indicates operation duration (Tier 1 — inherited from main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog). |
| 3 | Comments | STRING | YES | Free-text description of the operation (e.g., operator name, reason). Supplied by caller to PositionsHedgeServerChangeSummaryLogInsert. Used by Monitor.AlertForDealingExecutionConfigurationManager when alerting on large batches (>1000 positions) (Tier 1 — inherited from main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog). |
| 4 | etr_ymd | STRING | YES | Direct passthrough from upstream. Formula: `run_date`. (Tier 2 — from `run_date`) |
| 5 | UpdateDate | TIMESTAMP | NO | Literal constant set in this object. Formula: `current_timestamp()`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog
        │
        ▼
main.bi_dealing.v_hschangesummarylog_yesterday_email_csv   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` (wiki: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 6 | Tiers: 4 T1, 2 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
