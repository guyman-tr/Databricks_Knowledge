---
object_fqn: main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:12:50Z'
upstreams:
- etoro.Trade.ProviderInstrumentToLeverage
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md
  source_database: etoro
  source_schema: Trade
  source_table: ProviderInstrumentToLeverage
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Trade/ProviderInstrumentToLeverage
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_trade_providerinstrumenttoleverage

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Trade.ProviderInstrumentToLeverage`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Aug 17 12:14:58 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Trade.ProviderInstrumentToLeverage` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md`.

- Lake path: `Bronze/etoro/Trade/ProviderInstrumentToLeverage`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Trade.ProviderInstrumentToLeverage`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | INT | YES | FK to Trade.Provider. Part of PK. Identifies execution provider (e.g., 1=Tradonomi) (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 1 | InstrumentID | INT | YES | FK to Trade.Instrument (via ProviderToInstrument). Part of PK. Identifies tradeable instrument (Tier 2 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 2 | LeverageID | INT | YES | FK to Dictionary.Leverage. Part of PK. Leverage tier (1=1x, 2=5x, 3=10x, 5=50x, 6=100x, 7=200x, 8=400x, 9=2x, 10=30x, 11=20x) (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 3 | IsDefault | BOOLEAN | YES | 1=default leverage for this provider-instrument (offered when user does not specify), 0=available but not default. ProviderInstrumentLeverageAdd/Edit set IsDefault=0 for others when adding with 1 (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 4 | Percentage | INT | YES | Display or allocation weight. Sample shows 0 (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 5 | LeverageType | INT | YES | Leverage category. Default 1 (retail). Part of PK. May distinguish professional/restricted tiers (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 6 | DbLoginName | STRING | YES | Computed: suser_name(). Current DB login for audit (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 7 | AppLoginName | STRING | YES | Computed: CONVERT(varchar(500), context_info()). Application context (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 8 | SysStartTime | TIMESTAMP | YES | System-versioning row start. GENERATED ALWAYS AS ROW START (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |
| 9 | SysEndTime | TIMESTAMP | YES | System-versioning row end. GENERATED ALWAYS AS ROW END. History in History.TradeProviderInstrumentToLeverage (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Trade.ProviderInstrumentToLeverage` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Trade.ProviderInstrumentToLeverage
        │
        ▼
main.bi_db.bronze_etoro_trade_providerinstrumenttoleverage   ←── this object
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
| ProviderID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| LeverageID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| IsDefault | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| Percentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| LeverageType | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderInstrumentToLeverage.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.ProviderInstrumentToLeverage) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
