---
object_fqn: main.wallet.bronze_walletdb_wallet_requeststatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_requeststatuses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.RequestStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: RequestStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/RequestStatuses
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

# bronze_walletdb_wallet_requeststatuses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.RequestStatuses`). 5 of 8 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_requeststatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:17:02 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.RequestStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md`.

- Lake path: `Bronze/WalletDB/Wallet/RequestStatuses`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.RequestStatuses`
- 5 of 8 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing event identifier. The highest Id for a given RequestId represents the most recent status. Used in composite unique index with RequestId for ordering (Tier 3 — inherited from WalletDB.Wallet.RequestStatuses). |
| 1 | RequestId | LONG | YES | The request this status event belongs to. FK to Wallet.Requests.Id. Multiple status rows exist per request (event-sourced pattern). Indexed for efficient per-request lookups (Tier 3 — inherited from WalletDB.Wallet.RequestStatuses). |
| 2 | RequestStatusId | INT | YES | The status the request transitioned to: 0=Start, 1=Done, 2=Error, 3=ExecuterEnqueued, 4=ReadByExecuter, 5=TransactionSentToBlockChain, 6=TransactionConfirmed, 7=TransactionVerified, 8=AmlEnqueued, 9=ReadByAml, 16=TemporaryError, 25-27=ManualApproval flow, 28-42=extended statuses. See [Request Status](../../_glossary.md#request-status). FK to Dictionary.RequestStatuses (Tier 3 — inherited from WalletDB.Wallet.RequestStatuses). |
| 3 | Timestamp | TIMESTAMP | YES | When this status transition occurred. Used for SLA monitoring, processing time calculations, and chronological ordering. Indexed descending for recent-event queries (Tier 3 — inherited from WalletDB.Wallet.RequestStatuses). |
| 4 | DetailsJson | STRING | YES | JSON payload with status-specific context. For ExecuterEnqueued: saga key, full request payload including amounts, addresses, AML/TravelRule data. For TransactionSentToBlockChain: blockchain transaction hash. For Done: correlation ID. NULL for simple transitions (Tier 3 — inherited from WalletDB.Wallet.RequestStatuses). |
| 5 | etr_y | INT | YES | Source: WalletDB.Wallet.RequestStatuses.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ym | STRING | YES | Source: WalletDB.Wallet.RequestStatuses.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.RequestStatuses.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.RequestStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.RequestStatuses
        │
        ▼
main.wallet.bronze_walletdb_wallet_requeststatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.RequestStatuses) |
| RequestId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.RequestStatuses) |
| RequestStatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.RequestStatuses) |
| Timestamp | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.RequestStatuses) |
| DetailsJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.RequestStatuses) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.RequestStatuses.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
