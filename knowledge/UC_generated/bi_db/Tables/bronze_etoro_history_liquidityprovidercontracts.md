---
object_fqn: main.bi_db.bronze_etoro_history_liquidityprovidercontracts
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_liquidityprovidercontracts
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.LiquidityProviderContracts
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md
  source_database: etoro
  source_schema: History
  source_table: LiquidityProviderContracts
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/LiquidityProviderContracts
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_history_liquidityprovidercontracts

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.LiquidityProviderContracts`). 12 of 12 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_liquidityprovidercontracts` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 17 09:13:44 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.LiquidityProviderContracts` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md`.

- Lake path: `Bronze/etoro/History/LiquidityProviderContracts`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.LiquidityProviderContracts`
- 12 of 12 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ContractID | INT | YES | Auto-incremented contract identifier (IDENTITY in active table). Each new contract gets a unique sequential ID. Used in audit trail (History.AuditHistory) as a reference. Not a composite key component - the PK is (InstrumentID, LiquidityProviderID, ExchangeID) (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 1 | LiquidityProviderID | INT | YES | ID of the liquidity provider. FK to Trade.LiquidityProviderType in active table. Identifies which external LP (broker, exchange connection, internalizer) this contract covers (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 2 | InstrumentID | INT | YES | Financial instrument ID. FK to Trade.Instrument in active table. Identifies which financial instrument this LP-exchange contract covers (Tier 2 — inherited from etoro.History.LiquidityProviderContracts). |
| 3 | FromDate | TIMESTAMP | YES | Start date of the LP-instrument contract. When the contract became effective. FromDate = ToDate on many rows indicates a contract that was created and immediately superseded (trigger artifact or same-day replacement) (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 4 | ToDate | TIMESTAMP | YES | End date of the LP-instrument contract. When the contract was replaced or terminated. ToDate = 2100-01-01 00:00:00 = open-ended contract with no planned expiry. The default in active table is '2100-01-01' (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 5 | Ticker | STRING | YES | The LP's symbol/ticker for this instrument. Used to map eToro instrument IDs to the LP's own identifiers in price feeds and order routing. Formats observed: Bloomberg equity tickers ("AAPL US@NBSC Equity"), simple symbols ("BA"), numeric IDs ("1016586"). NULL if no ticker assigned (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 6 | ExchangeID | INT | YES | Exchange through which this LP contract routes. FK to Price.Exchange in active table. DEFAULT 1 (the primary/default exchange). All observed rows: ExchangeID=1 (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 7 | RateConversionFactor | DECIMAL | YES | Multiplicative factor applied to prices from this LP for this instrument. DEFAULT 1.0 (no conversion). Non-1 values indicate instruments where the LP quotes in different units (e.g., pence vs pounds, cents vs dollars) or requires a fixed price scaling. NULL if not applicable (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 8 | DbLoginName | STRING | YES | Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is a computed column; stored here as a snapshot. Identifies which DB login modified the contract (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 9 | AppLoginName | STRING | YES | Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 10 | SysStartTime | TIMESTAMP | YES | Start of the validity window for this history row. Set by SQL Server temporal engine. For INSERT artifacts: SysStartTime = SysEndTime. For genuine updates: the timestamp when the previous contract state became current (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |
| 11 | SysEndTime | TIMESTAMP | YES | End of the validity window for this history row. Set to the UTC time of the UPDATE/DELETE that closed this version. CLUSTERED INDEX leads with SysEndTime for optimal temporal query performance (Tier 1 — inherited from etoro.History.LiquidityProviderContracts). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.LiquidityProviderContracts` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.LiquidityProviderContracts
        │
        ▼
main.bi_db.bronze_etoro_history_liquidityprovidercontracts   ←── this object
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
| ContractID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| LiquidityProviderID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| FromDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| ToDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| Ticker | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| ExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| RateConversionFactor | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.LiquidityProviderContracts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.LiquidityProviderContracts) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
