---
object_fqn: main.bi_db.bronze_etoro_trade_liquidityprovidertype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_trade_liquidityprovidertype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:50Z'
upstreams:
- etoro.Trade.LiquidityProviderType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md
  source_database: etoro
  source_schema: Trade
  source_table: LiquidityProviderType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Trade/LiquidityProviderType
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_trade_liquidityprovidertype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Trade.LiquidityProviderType`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_trade_liquidityprovidertype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Jan 30 10:13:22 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Trade.LiquidityProviderType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md`.

- Lake path: `Bronze/etoro/Trade/LiquidityProviderType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Trade.LiquidityProviderType`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LiquidityProviderTypeID | INT | YES | Primary key. Provider type identifier. Value map from live data: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 11=IB. Hedge.AddAccountStatus branches on 3 and 11. (Source: Trade.LiquidityProviderType) (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 1 | Name | STRING | YES | Human-readable provider type name (e.g., eToro, FXCM, BMFN). Used in views and reports (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 2 | TypeSettingsXML | STRING | YES | Pluggable configuration: assembly/class for priceClassInfo, PCSClassInfo, executionClassInfo, HedgingProviderClassInfo. Includes ProviderExecutionSettings (default_lot_size) and OnixsEngineSettings for external providers (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 3 | DbLoginName | STRING | YES | Computed: suser_name(). SQL login that last modified the row. Audit context (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 4 | AppLoginName | STRING | YES | Computed: CONVERT(varchar(500), context_info()). Application context from context_info. Often NULL when not set by caller (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 5 | SysStartTime | TIMESTAMP | YES | System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |
| 6 | SysEndTime | TIMESTAMP | YES | System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current (Tier 1 — inherited from etoro.Trade.LiquidityProviderType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Trade.LiquidityProviderType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Trade.LiquidityProviderType
        │
        ▼
main.bi_db.bronze_etoro_trade_liquidityprovidertype   ←── this object
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
| LiquidityProviderTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| TypeSettingsXML | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.LiquidityProviderType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
