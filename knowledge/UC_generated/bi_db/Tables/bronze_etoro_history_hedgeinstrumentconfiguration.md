---
object_fqn: main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 14
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.HedgeInstrumentConfiguration
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md
  source_database: etoro
  source_schema: History
  source_table: HedgeInstrumentConfiguration
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/HedgeInstrumentConfiguration
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

# bronze_etoro_history_hedgeinstrumentconfiguration

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.HedgeInstrumentConfiguration`). 14 of 14 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 14 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jul 09 08:17:52 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.HedgeInstrumentConfiguration` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md`.

- Lake path: `Bronze/etoro/History/HedgeInstrumentConfiguration`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.HedgeInstrumentConfiguration`
- 14 of 14 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | The financial instrument whose hedge configuration is recorded. PK in source (not IDENTITY). FK to Trade.Instrument. One row per instrument in the current table (Tier 2 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 1 | MinOrderSizeForExecutionInEToroUnits | DECIMAL | YES | Minimum order size (in eToro's internal unit denomination) required for this instrument to be routed to a liquidity provider for hedging. Source DEFAULT=1. High precision (19,5) supports fractional-unit instruments like crypto (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 2 | HBCDealSizeThresholdAlertInEToroUnits | INT | YES | HBC (Hedge Book Control) alert threshold in eToro units. Single hedge orders exceeding this size trigger an operator alert. Source DEFAULT=30,000,000. The HBC system protects liquidity providers from oversized orders (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 3 | HBCMaxDealSizeThresholdRejectInEToroUnits | INT | YES | HBC reject threshold in eToro units. Single hedge orders exceeding this size are automatically rejected by the HBC system. Source DEFAULT=30,000,000. Alert threshold is typically lower than or equal to reject threshold (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 4 | ManualMaxDealSizeInEToroUnits | INT | YES | Optional override for maximum deal size on manually-submitted hedge orders. NULL means the standard HBC thresholds apply. When set, provides a tighter constraint for manual operations than the automated threshold (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 5 | SpreadReturnFactor | DECIMAL | YES | Multiplier applied in spread return calculations. Source DEFAULT=1. 1.0 = full market spread applies to the customer; values approaching 0 indicate greater spread subsidization. Affects customer cost of trading (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 6 | CircuitBreakerLimit | DECIMAL | YES | The exposure or deviation threshold at which the circuit breaker trips and hedging is suspended for this instrument. NULL for instruments without circuit breaker protection. High precision (14,4) for large exposure values (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 7 | CircuitBreakerWarningLimit | DECIMAL | YES | Warning threshold below the full circuit breaker limit. Triggers operator alerts before the circuit breaker trips. NULL when not configured (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 8 | DbLoginName | STRING | YES | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Identifies which service account made the configuration change (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 9 | AppLoginName | STRING | YES | Application context from context_info() at time of change. Computed column in source, materialized here. May identify the operator email or service that triggered the update (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 10 | SysStartTime | TIMESTAMP | YES | UTC timestamp when this instrument configuration version became active. For INSERT-trigger-captured rows, equals SysEndTime (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 11 | SysEndTime | TIMESTAMP | YES | UTC timestamp when this version was superseded. CLUSTERED index leading column (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 12 | RestrictManualActions | INT | YES | Flag controlling whether manual hedging operations are permitted for this instrument. Source DEFAULT=0 (unrestricted). Non-zero values block manual open/close actions via management tools (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |
| 13 | LotSizeForView | DECIMAL | YES | Display denominator for converting eToro internal units to conventional lot sizes for reporting and UI display. Source DEFAULT=1. Example: setting to 100,000 displays FX positions in standard lots. Does not affect execution (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.HedgeInstrumentConfiguration` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.HedgeInstrumentConfiguration
        │
        ▼
main.bi_db.bronze_etoro_history_hedgeinstrumentconfiguration   ←── this object
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
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| MinOrderSizeForExecutionInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| HBCDealSizeThresholdAlertInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| HBCMaxDealSizeThresholdRejectInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| ManualMaxDealSizeInEToroUnits | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| SpreadReturnFactor | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| CircuitBreakerLimit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| CircuitBreakerWarningLimit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| RestrictManualActions | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |
| LotSizeForView | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeInstrumentConfiguration.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeInstrumentConfiguration) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 14 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 14/14 | Source: bronze_tier1_inheritance*
