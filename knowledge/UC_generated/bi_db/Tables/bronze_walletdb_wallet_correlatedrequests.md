---
object_fqn: main.bi_db.bronze_walletdb_wallet_correlatedrequests
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_wallet_correlatedrequests
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:13:11Z'
upstreams:
- WalletDB.Wallet.CorrelatedRequests
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: CorrelatedRequests
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/CorrelatedRequests
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_correlatedrequests

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Wallet.CorrelatedRequests`). 5 of 8 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_wallet_correlatedrequests` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 28 08:41:07 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.CorrelatedRequests` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md`.

- Lake path: `Bronze/WalletDB/Wallet/CorrelatedRequests`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.CorrelatedRequests`
- 5 of 8 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests). |
| 1 | CorrelatedRequestsTypeId | INT | YES | Type of correlation: 1=Bounceback (only type currently used). See [Correlated Request Type](../../_glossary.md#correlated-request-type). Implicit FK to Dictionary.CorrelatedRequestsTypes (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests). |
| 2 | ParentRequestCorrelationId | STRING | YES | CorrelationId of the original (parent) request that triggered the child. For bouncebacks, this is the received transaction's CorrelationId from Wallet.Requests (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests). |
| 3 | ChildRequestCorrelationId | STRING | YES | CorrelationId of the triggered (child) request. For bouncebacks, this is the send-back transaction's CorrelationId from Wallet.Requests (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests). |
| 4 | Created | TIMESTAMP | YES | Timestamp when this correlation was established (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests). |
| 5 | etr_y | INT | YES | Source: WalletDB.Wallet.CorrelatedRequests.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ym | STRING | YES | Source: WalletDB.Wallet.CorrelatedRequests.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.CorrelatedRequests.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.CorrelatedRequests` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.CorrelatedRequests
        │
        ▼
main.bi_db.bronze_walletdb_wallet_correlatedrequests   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests) |
| CorrelatedRequestsTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests) |
| ParentRequestCorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests) |
| ChildRequestCorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CorrelatedRequests) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CorrelatedRequests.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
