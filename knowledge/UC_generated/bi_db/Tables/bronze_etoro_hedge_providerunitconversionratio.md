---
object_fqn: main.bi_db.bronze_etoro_hedge_providerunitconversionratio
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_providerunitconversionratio
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:12:47Z'
upstreams:
- etoro.Hedge.ProviderUnitConversionRatio
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md
  source_database: etoro
  source_schema: Hedge
  source_table: ProviderUnitConversionRatio
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/ProviderUnitConversionRatio
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_hedge_providerunitconversionratio

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.ProviderUnitConversionRatio`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_providerunitconversionratio` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 04:18:35 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.ProviderUnitConversionRatio` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md`.

- Lake path: `Bronze/etoro/Hedge/ProviderUnitConversionRatio`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.ProviderUnitConversionRatio`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LiquidityProviderID | INT | YES | FK to Trade.LiquidityProviderType(LiquidityProviderTypeID). Named "LiquidityProviderID" but references the provider type table. Part of composite PK. 10 distinct providers configured (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio). |
| 1 | InstrumentID | INT | YES | The instrument this ratio applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint in DDL). 5,215 distinct instruments (Tier 2 — inherited from etoro.Hedge.ProviderUnitConversionRatio). |
| 2 | UnitConversionRatio | DOUBLE | YES | Multiplier converting eToro internal units to provider-native order quantity. providerQty = eToroUnits * UnitConversionRatio. Range 0.001-10,000 in current data. ISNULL defaults to 1.0 in GetProviderUnitConversion (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio). |
| 3 | LotSize | DECIMAL | YES | Standard lot size for this provider/instrument, used for lot-boundary rounding. DEFAULT 1 = no lot rounding. Range 0.00001-3,000. ISNULL defaults to 1000 (Forex) or 1 (other) in GetProviderUnitConversion. Not tracked by ASM audit triggers (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.ProviderUnitConversionRatio` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.ProviderUnitConversionRatio
        │
        ▼
main.bi_db.bronze_etoro_hedge_providerunitconversionratio   ←── this object
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
| LiquidityProviderID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio) |
| UnitConversionRatio | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio) |
| LotSize | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Hedge.ProviderUnitConversionRatio) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
