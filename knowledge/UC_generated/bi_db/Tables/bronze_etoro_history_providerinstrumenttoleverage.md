---
object_fqn: main.bi_db.bronze_etoro_history_providerinstrumenttoleverage
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_providerinstrumenttoleverage
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.ProviderInstrumentToLeverage
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md
  source_database: etoro
  source_schema: History
  source_table: ProviderInstrumentToLeverage
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/ProviderInstrumentToLeverage
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

# bronze_etoro_history_providerinstrumenttoleverage

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.ProviderInstrumentToLeverage`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_providerinstrumenttoleverage` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 12 09:19:09 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.ProviderInstrumentToLeverage` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md`.

- Lake path: `Bronze/etoro/History/ProviderInstrumentToLeverage`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.ProviderInstrumentToLeverage`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | VersionID | INT | YES | Auto-incrementing row version identifier. Clustered PK. NOT FOR REPLICATION prevents identity gaps on replication targets. Provides a stable row key for joining (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 1 | ProviderID | INT | YES | The price/execution provider for which this leverage option applies. Implicit FK to provider lookup (same as Trade.ProviderToInstrument.ProviderID) (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 2 | InstrumentID | INT | YES | The financial instrument for which this leverage tier is available. Implicit FK to instrument lookup. HPIL_INSTRUMENT index supports per-instrument queries (Tier 2 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 3 | LeverageID | INT | YES | Identifies the leverage tier (e.g., 1:5, 1:10, 1:100). Implicit FK to leverage lookup (Dictionary.Leverage or Trade.Leverage). HPIL_LEVERAGE index supports per-leverage-tier queries (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 4 | IsDefault | BOOLEAN | YES | 1 = this is the default leverage tier presented to customers for this instrument. Only one tier per active (ProviderID, InstrumentID) pair should be IsDefault=1 at any time (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 5 | Percentage | INT | YES | Margin percentage associated with this leverage tier. Observed value: 0. May represent a margin override percentage (0 = use system default) or may be populated differently in older rows (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 6 | ValidFrom | TIMESTAMP | YES | Application-set timestamp when this leverage tier became available for this provider-instrument pair. Not UTC-guaranteed - local server datetime. Written by the application when adding a leverage tier (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |
| 7 | ValidTo | TIMESTAMP | YES | Application-set timestamp when this leverage tier was deactivated. Sentinel '3000-01-01 00:00:00.000' = currently active. Set to current timestamp when a tier is removed. HPIL_PROVIDERINSTRUMENTLEVERAGE index supports active-tier queries (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.ProviderInstrumentToLeverage` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.ProviderInstrumentToLeverage
        │
        ▼
main.bi_db.bronze_etoro_history_providerinstrumenttoleverage   ←── this object
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
| VersionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| LeverageID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| IsDefault | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| Percentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.ProviderInstrumentToLeverage) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
