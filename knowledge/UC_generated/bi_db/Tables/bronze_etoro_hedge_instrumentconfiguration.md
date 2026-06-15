---
object_fqn: main.bi_db.bronze_etoro_hedge_instrumentconfiguration
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_instrumentconfiguration
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 14
row_count: null
generated_at: '2026-05-19T12:12:46Z'
upstreams:
- etoro.Hedge.InstrumentConfiguration
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md
  source_database: etoro
  source_schema: Hedge
  source_table: InstrumentConfiguration
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/InstrumentConfiguration
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 14
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_hedge_instrumentconfiguration

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.InstrumentConfiguration`). 14 of 14 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_instrumentconfiguration` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 14 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jul 09 04:16:14 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.InstrumentConfiguration` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md`.

- Lake path: `Bronze/etoro/Hedge/InstrumentConfiguration`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.InstrumentConfiguration`
- 14 of 14 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | Primary key and FK to Trade.Instrument(InstrumentID). One row per instrument. All 10,468 instruments have exactly one configuration row. Futures instruments appear in the 200,000+ range; standard equities in 1-100,749 (Tier 2 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 1 | MinOrderSizeForExecutionInEToroUnits | DECIMAL | YES | Minimum hedge order size before execution is attempted. Orders below this value are skipped. 0 = no minimum (5,039 instruments). Non-zero values range up to 83,334 units; average ~42 for equities, ~2 for futures. Read by `GetInstrumentMinOrderSizeForHBC` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 2 | HBCDealSizeThresholdAlertInEToroUnits | INT | YES | HBC (Hedge Bot Controller) warning threshold in eToro units. Orders at or above this size trigger an alert log entry but still execute. Most equity instruments set to 2,000,000. Range 0-20,000,000 in data. Read by `GetInstrumentConfiguration` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 3 | HBCMaxDealSizeThresholdRejectInEToroUnits | INT | YES | HBC hard rejection threshold in eToro units. Orders at or above this size are refused outright - no execution occurs. Typically equal to or higher than the alert threshold. Range 0-9,999,999 in data. Read by `GetInstrumentConfiguration` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 4 | ManualMaxDealSizeInEToroUnits | INT | YES | Maximum deal size permitted via the manual order execution path (distinct from automated HBC path). No NULL values in data (0 null rows). Most instruments set to 200,000 (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 5 | SpreadReturnFactor | DECIMAL | YES | Multiplier applied to spread calculations. DEFAULT 1; all 10,468 rows have value 1.0000 - this column is currently uniform and appears reserved for future per-instrument spread adjustment. Read by `GetAllInstrumentConfigurations` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 6 | CircuitBreakerLimit | DECIMAL | YES | Hard cumulative exposure limit. When reached, the circuit breaker halts hedge execution for this instrument. NULL=not configured (5,441 rows); 0=disabled (4,954 rows); 100,000=active (73 rows). Read by `GetCircuitBreakerInstrumentThresholds` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 7 | CircuitBreakerWarningLimit | DECIMAL | YES | Soft cumulative exposure limit. When reached, generates a warning before the hard limit triggers. Typically equal to or less than CircuitBreakerLimit. NULL or 0 when circuit breaker not configured. Read by `GetCircuitBreakerInstrumentThresholds` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 8 | DbLoginName | STRING | YES | Computed audit column. SQL Server login executing the DML via `suser_name()` (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 9 | AppLoginName | STRING | YES | Computed audit column. Application identity from `CONTEXT_INFO()`. NULL when not set (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 10 | SysStartTime | TIMESTAMP | YES | Temporal period start. UTC timestamp when this row version became active. Managed by SQL Server SYSTEM_VERSIONING (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 11 | SysEndTime | TIMESTAMP | YES | Temporal period end. 9999-12-31 for all current rows. Historical versions in History.HedgeInstrumentConfiguration (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 12 | RestrictManualActions | INT | YES | Flag to restrict manual hedge actions for this instrument. DEFAULT 0; all 10,468 rows have value 0 - this column is currently uniform and appears reserved for future per-instrument manual action restriction (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |
| 13 | LotSizeForView | DECIMAL | YES | Lot size normalization factor for display/reporting purposes. DEFAULT 1; all 10,468 rows have value 1.0000 - currently uniform across all instruments (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.InstrumentConfiguration` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.InstrumentConfiguration
        │
        ▼
main.bi_db.bronze_etoro_hedge_instrumentconfiguration   ←── this object
        │
        ▼
main.bi_dealing.bi_output_dealing_pi_tradinglimitations_clicksize
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
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| MinOrderSizeForExecutionInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| HBCDealSizeThresholdAlertInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| HBCMaxDealSizeThresholdRejectInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| ManualMaxDealSizeInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| SpreadReturnFactor | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| CircuitBreakerLimit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| CircuitBreakerWarningLimit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| RestrictManualActions | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |
| LotSizeForView | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.InstrumentConfiguration) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 14 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 14/14 | Source: bronze_tier1_inheritance*
