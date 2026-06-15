---
object_fqn: main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.HedgeServerToLiquidityAccount
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md
  source_database: etoro
  source_schema: History
  source_table: HedgeServerToLiquidityAccount
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/HedgeServerToLiquidityAccount
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

# bronze_etoro_history_hedgeservertoliquidityaccount

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.HedgeServerToLiquidityAccount`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Dec 31 08:17:26 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.HedgeServerToLiquidityAccount` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md`.

- Lake path: `Bronze/etoro/History/HedgeServerToLiquidityAccount`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.HedgeServerToLiquidityAccount`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HedgeServerID | INT | YES | The hedging engine server instance. FK to Trade.HedgeServer(HedgeServerID). One server can have multiple liquidity accounts. NONCLUSTERED index on source for fast lookup of all accounts per server. 12 distinct servers in history (Tier 2 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 1 | LiquidityAccountID | INT | YES | The external liquidity provider account used for hedge execution. FK to Trade.LiquidityAccounts(LiquidityAccountID). PK in source - each liquidity account belongs to exactly one hedge server. Used by History.HedgeFailInfo to resolve the account when recording failures (Tier 2 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 2 | AltRatesLiquidityAccountID | INT | YES | Optional alternative liquidity account used for rate/price data (distinct from execution). FK to Trade.LiquidityAccounts(LiquidityAccountID). NULL in all 42 observed history rows - reserved for multi-rate scenarios (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 3 | DbLoginName | STRING | YES | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Observed values: domain accounts ("TRAD\dotanva", "TRAD\Noah", "TRAD\ranlev", "TRAD\rivkaya") and "DevTradingSTG" for direct SQL (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 4 | AppLoginName | STRING | YES | Application context from context_info() at time of change. Format: "username;ConfigurationManager\0\0..." with null-byte padding (context_info written as Unicode from a .NET application). The tool name after the semicolon is "ConfigurationManager" (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 5 | SysStartTime | TIMESTAMP | YES | UTC timestamp when this server-to-account mapping version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. Earliest observed: 2021-09-13 (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount). |
| 6 | SysEndTime | TIMESTAMP | YES | UTC timestamp when this mapping version was superseded. CLUSTERED index leading column. Source DEFAULT='9999-12-31'. Latest observed: 2026-02-25 (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.HedgeServerToLiquidityAccount` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.HedgeServerToLiquidityAccount
        │
        ▼
main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount   ←── this object
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
| HedgeServerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| LiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| AltRatesLiquidityAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.HedgeServerToLiquidityAccount) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
