---
object_fqn: main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:47Z'
upstreams:
- etoro.History.ExposureCircuitBreakerThresholds
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md
  source_database: etoro
  source_schema: History
  source_table: ExposureCircuitBreakerThresholds
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/ExposureCircuitBreakerThresholds
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_history_exposurecircuitbreakerthresholds

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.ExposureCircuitBreakerThresholds`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 19 11:16:12 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.ExposureCircuitBreakerThresholds` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md`.

- Lake path: `Bronze/etoro/History/ExposureCircuitBreakerThresholds`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.ExposureCircuitBreakerThresholds`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | Trading instrument identifier. Matches the InstrumentID in the source table `Hedge.ExposureCircuitBreakerThresholds` PK (InstrumentID, IsOverHedged). Multiple rows with the same InstrumentID+IsOverHedged represent successive threshold configuration versions. Implicit FK to Trade.Instrument - no constraint in this history table per SQL Server temporal history table conventions (Tier 2 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 1 | IsOverHedged | BOOLEAN | YES | The hedging direction this threshold row governs. 1 = over-hedged direction (circuit breaker for when the instrument has more hedge than needed, excess long exposure), 0 = under-hedged direction (circuit breaker for when the instrument has less hedge than needed, excess short/open exposure). Forms the second component of the source table's composite PK - each instrument has exactly two threshold rows, one per direction (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 2 | CircuitBreakerAlertThresholdUSD | DECIMAL | YES | USD exposure amount at which an alert notification fires. First tier of the two-tier circuit breaker system. When live instrument exposure (over-hedged or under-hedged depending on IsOverHedged) exceeds this amount, the risk/hedging monitoring system generates an alert for operator attention. Always less than CircuitBreakerTriggerThresholdUSD. All values in USD regardless of instrument currency (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 3 | CircuitBreakerTriggerThresholdUSD | DECIMAL | YES | USD exposure amount at which the circuit breaker actually trips, potentially halting further hedging or execution for this instrument. Second tier of the two-tier system. Monitor.AlertForDealingMarketDataConfigurationManager validates that this value does not exceed $10,000,000 for tradable, publicly visible instruments (FeedID=1, Tradable=1, VisibleInternallyOnly=0). Exceeding the $10M limit generates a monitoring alert (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 4 | DbLoginName | STRING | YES | SQL Server login name (suser_name()) of the database session that made the configuration change captured in this version. Computed column in Hedge.ExposureCircuitBreakerThresholds, materialized into this history table at version creation time. Identifies the operator or service account that changed the threshold. NULL if the session context was not set (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 5 | AppLoginName | STRING | YES | Application-level login from SQL Server context_info() at time of change. Computed column in Hedge.ExposureCircuitBreakerThresholds as CONVERT(varchar(500), context_info()). Populated by application services that set context_info before modifying threshold configuration. NULL if the calling application did not set context_info (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 6 | SysStartTime | TIMESTAMP | YES | UTC timestamp when this row version became active in Hedge.ExposureCircuitBreakerThresholds. GENERATED ALWAYS AS ROW START in the source table. Records when the threshold configuration was set. Due to the INSERT trigger pattern (Section 2.2), the initial-creation version has SysStartTime very slightly before SysEndTime (milliseconds apart for the trigger-forced no-op update). Subsequent versions have longer validity windows (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |
| 7 | SysEndTime | TIMESTAMP | YES | UTC timestamp when this row version was superseded by a new threshold configuration. GENERATED ALWAYS AS ROW END in the source table. CLUSTERED index leading column for efficient temporal range scans by time window. SysEndTime close to SysStartTime (milliseconds apart) marks rows created by the INSERT trigger capture pattern (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.ExposureCircuitBreakerThresholds` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.ExposureCircuitBreakerThresholds
        │
        ▼
main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| IsOverHedged | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| CircuitBreakerAlertThresholdUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| CircuitBreakerTriggerThresholdUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ExposureCircuitBreakerThresholds) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
