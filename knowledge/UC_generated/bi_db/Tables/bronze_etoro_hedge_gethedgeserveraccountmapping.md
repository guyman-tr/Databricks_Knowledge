---
object_fqn: main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:12:46Z'
upstreams:
- etoro.Hedge.GetHedgeServerAccountMapping
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md
  source_database: etoro
  source_schema: Hedge
  source_table: GetHedgeServerAccountMapping
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Hedge/GetHedgeServerAccountMapping
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 5
  unverified_columns: 0
---

# bronze_etoro_hedge_gethedgeserveraccountmapping

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Hedge.GetHedgeServerAccountMapping`). 0 of 5 columns inherited from Tier 1 source wiki; 5 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Jan 02 12:15:01 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Hedge.GetHedgeServerAccountMapping` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md`.

- Lake path: `Bronze/etoro/Hedge/GetHedgeServerAccountMapping`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Hedge.GetHedgeServerAccountMapping`
- 0 of 5 columns inherited; 5 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LiquidityAccountID | INT | YES | Source: etoro.Hedge.GetHedgeServerAccountMapping.LiquidityAccountID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 1 | LiquidityAccountName | STRING | YES | Source: etoro.Hedge.GetHedgeServerAccountMapping.LiquidityAccountName. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 2 | LiquidityProviderName | STRING | YES | Source: etoro.Hedge.GetHedgeServerAccountMapping.LiquidityProviderName. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 3 | HedgeServerID | INT | YES | Source: etoro.Hedge.GetHedgeServerAccountMapping.HedgeServerID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 4 | InstrumentID | INT | YES | Source: etoro.Hedge.GetHedgeServerAccountMapping.InstrumentID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Hedge.GetHedgeServerAccountMapping` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Hedge.GetHedgeServerAccountMapping
        │
        ▼
main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping   ←── this object
        │
        ▼
main.bi_dealing.bi_output_dealing_duco_eod
main.bi_dealing.bi_output_dealing_duco_trades
main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
... (1 more downstream)
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
| LiquidityAccountID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` but column `LiquidityAccountID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| LiquidityAccountName | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` but column `LiquidityAccountName` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| LiquidityProviderName | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` but column `LiquidityProviderName` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| HedgeServerID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` but column `HedgeServerID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| InstrumentID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Views/Hedge.GetHedgeServerAccountMapping.md` but column `InstrumentID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 5 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
