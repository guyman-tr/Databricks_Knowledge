---
object_fqn: main.bi_db.bronze_etoro_trade_fund
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_trade_fund
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T12:12:49Z'
upstreams:
- etoro.Trade.Fund
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md
  source_database: etoro
  source_schema: Trade
  source_table: Fund
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Trade/Fund
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_trade_fund

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Trade.Fund`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_trade_fund` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Mar 26 18:17:24 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Trade.Fund` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md`.

- Lake path: `Bronze/etoro/Trade/Fund`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Trade.Fund`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundID | INT | YES | Primary key. Surrogate identifier for the fund. Referenced by Trade.FundInterval, Trade.FundIntervalAllocation, and fee/backtest procedures (Tier 1 — inherited from etoro.Trade.Fund). |
| 1 | FundName | STRING | YES | Display name of the fund. Set from Customer.CustomerStatic.UserName when Job_GenerateFundAllocation creates a fund. Shown in fund details and API responses (Tier 1 — inherited from etoro.Trade.Fund). |
| 2 | FundAccountID | INT | YES | FK to Customer.CustomerStatic.CID. The customer account that holds the fund's positions. Used to check "is CID a fund?" (Confluence DCS-627). Join key for GetFundMetaData, GetFundCidsBulk (Tier 1 — inherited from etoro.Trade.Fund). |
| 3 | FundOwnerID | INT | YES | FK to Customer.CustomerStatic.CID. The entity that owns/manages the fund. Job_GenerateFundAllocation looks up FundID by FundOwnerID; when null, creates new fund. Typically equals FundAccountID at creation (Tier 1 — inherited from etoro.Trade.Fund). |
| 4 | IsPublic | BOOLEAN | YES | 1 = fund is publicly discoverable; 0 = private. Returned by GetFundMetaData. Controls visibility in fund listing and copy flows (Tier 1 — inherited from etoro.Trade.Fund). |
| 5 | MinCopyAmount | DECIMAL | YES | Minimum investment amount (in account currency) required to copy into this fund. Job_GenerateFundAllocation uses 5000 for new funds; sample data shows 100-5000. Enforced by application (Tier 1 — inherited from etoro.Trade.Fund). |
| 6 | RefreshIntervalMonths | INT | YES | Rebalance interval in months. Job_GenerateFundAllocation uses this to compute Trade.FundInterval.PlannedEnd: adds this many months to PlannedStart. Sample: 1=monthly, 2=bimonthly, 3=quarterly (Tier 1 — inherited from etoro.Trade.Fund). |
| 7 | CreateDate | TIMESTAMP | YES | When the fund row was created. Set by default (Tier 1 — inherited from etoro.Trade.Fund). |
| 8 | LastUpdateDate | TIMESTAMP | YES | Last modification timestamp. Updated by application or procedures when fund config changes (Tier 1 — inherited from etoro.Trade.Fund). |
| 9 | FundType | INT | YES | FK to Dictionary.FundType.FundTypeID. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for older funds. See Dictionary.FundType (Tier 1 — inherited from etoro.Trade.Fund). |
| 10 | HasCrypto | BOOLEAN | YES | 1 = fund may hold crypto instruments; 0 = fund excludes crypto. Default 1. Returned by GetFundMetaData. Used for instrument filtering and risk rules (Tier 1 — inherited from etoro.Trade.Fund). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Trade.Fund` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Trade.Fund
        │
        ▼
main.bi_db.bronze_etoro_trade_fund   ←── this object
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
| FundID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| FundName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| FundAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| FundOwnerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| IsPublic | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| MinCopyAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| RefreshIntervalMonths | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| LastUpdateDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| FundType | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |
| HasCrypto | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Fund.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Trade.Fund) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
