---
object_fqn: main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:46Z'
upstreams:
- etoro.Hedge.ExposureCircuitBreakerThresholds
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md
  source_database: etoro
  source_schema: Hedge
  source_table: ExposureCircuitBreakerThresholds
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/ExposureCircuitBreakerThresholds
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

# bronze_etoro_hedge_exposurecircuitbreakerthresholds

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.ExposureCircuitBreakerThresholds`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Jan 02 12:14:16 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.ExposureCircuitBreakerThresholds` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md`.

- Lake path: `Bronze/etoro/Hedge/ExposureCircuitBreakerThresholds`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.ExposureCircuitBreakerThresholds`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | The instrument this circuit breaker applies to. Part of composite PK. No FK constraint - implicit reference to Trade.Instrument (Tier 2 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 1 | IsOverHedged | BOOLEAN | YES | Direction flag. 1=over-hedged circuit breaker (excess hedge above required), 0=under-hedged circuit breaker (deficit hedge below required). Together with InstrumentID forms the composite PK, allowing distinct thresholds per direction (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 2 | CircuitBreakerAlertThresholdUSD | DECIMAL | YES | USD exposure amount at which a soft alert is triggered. When the direction-specific exposure exceeds this value, an alert is generated but execution continues. Money type (accurate to $0.0001) (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 3 | CircuitBreakerTriggerThresholdUSD | DECIMAL | YES | USD exposure amount at which the circuit breaker trips. When exceeded, hedge execution for this instrument halts. Should be >= CircuitBreakerAlertThresholdUSD. Money type (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 4 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 5 | AppLoginName | STRING | YES | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 6 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |
| 7 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for current rows. History in History.ExposureCircuitBreakerThresholds (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.ExposureCircuitBreakerThresholds` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.ExposureCircuitBreakerThresholds
        │
        ▼
main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds   ←── this object
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
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| IsOverHedged | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| CircuitBreakerAlertThresholdUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| CircuitBreakerTriggerThresholdUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ExposureCircuitBreakerThresholds) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
