---
object_fqn: main.bi_db.bronze_etoro_price_exchange
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_price_exchange
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:12:49Z'
upstreams:
- etoro.Price.Exchange
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md
  source_database: etoro
  source_schema: Price
  source_table: Exchange
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Price/Exchange
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

# bronze_etoro_price_exchange

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Price.Exchange`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_price_exchange` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 29 17:11:57 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Price.Exchange` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md`.

- Lake path: `Bronze/etoro/Price/Exchange`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Price.Exchange`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ExchangeID | INT | YES | Primary key. Integer identifier assigned manually (not IDENTITY). Organizes by data-provider context: 1-2 = Xignite virtual; 3-47 = standard exchanges; 48-67 = JPM codes; 68+ = additional venues. Referenced by Trade.LiquidityProviderContracts.ExchangeID and Trade.InstrumentMetaData.ExchangeID (Tier 1 — inherited from etoro.Price.Exchange). |
| 1 | Name | STRING | YES | Short exchange code name (up to 16 chars). Used in operations tooling and GetTickerInfo output. Not always an ISO standard code - some are IB-specific (IDEALPRO, ISLAND, SMART) or vendor-specific (DEFAULT_EXCHANGE) (Tier 1 — inherited from etoro.Price.Exchange). |
| 2 | Description | STRING | YES | Human-readable full exchange name. Some have minor typos from original data entry (e.g., "Eurpoe CHIX", "Exchnage"). Displayed in internal tooling and monitoring dashboards (Tier 1 — inherited from etoro.Price.Exchange). |
| 3 | Mic | STRING | YES | Market Identifier Code (ISO 10383). Standard 4-character exchange identifier used by Bloomberg, regulatory reporting, and feed routing. Some non-standard values exist for virtual venues (DEFEXC, GLBEXC) and broker-specific identifiers (SMRT, IDLP, JPM 2-letter codes) (Tier 1 — inherited from etoro.Price.Exchange). |
| 4 | CountryID | INT | YES | FK to Dictionary.Country. Geographic country of the exchange. CountryID=0 for exchanges without a resolved country mapping (JPM codes, some virtual venues). Key country IDs: 219=USA, 218=UK, 79=Germany, 74=France, 102=Italy, 196=Sweden, 197=Switzerland (Tier 1 — inherited from etoro.Price.Exchange). |
| 5 | DbLoginName | STRING | YES | Computed: SQL Server login of last row modifier. Auto-set on every DML (Tier 1 — inherited from etoro.Price.Exchange). |
| 6 | AppLoginName | STRING | YES | Computed: application identity from context_info(). Populated when the calling service sets context_info before DML (Tier 1 — inherited from etoro.Price.Exchange). |
| 7 | SysStartTime | TIMESTAMP | YES | Temporal row validity start. Auto-managed by SQL Server system versioning (Tier 1 — inherited from etoro.Price.Exchange). |
| 8 | SysEndTime | TIMESTAMP | YES | Temporal row validity end. Historical versions in History.Exchange (Tier 1 — inherited from etoro.Price.Exchange). |
| 9 | Ric | STRING | YES | Reuters/Refinitiv exchange suffix appended to RIC tickers (e.g., AAPL.N where N = NYSE). NULL for exchanges not available on Reuters/Refinitiv or where RIC routing is not used. Used by GetTickerInfo to build complete Reuters ticker strings for liquidity provider feeds (Tier 1 — inherited from etoro.Price.Exchange). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Price.Exchange` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Price.Exchange
        │
        ▼
main.bi_db.bronze_etoro_price_exchange   ←── this object
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
| ExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| Description | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| Mic | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |
| Ric | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.Exchange.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Price.Exchange) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
