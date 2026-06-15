---
object_fqn: main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.ReceivedTransactionStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: ReceivedTransactionStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/ReceivedTransactionStatuses
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

# bronze_walletdb_wallet_receivedtransactionstatuses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.ReceivedTransactionStatuses`). 5 of 8 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:09:44 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.ReceivedTransactionStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md`.

- Lake path: `Bronze/WalletDB/Wallet/ReceivedTransactionStatuses`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.ReceivedTransactionStatuses`
- 5 of 8 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing event identifier (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses). |
| 1 | ReceivedTransactionId | LONG | YES | The received transaction this status belongs to. FK to Wallet.ReceivedTransactions.Id (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses). |
| 2 | StatusId | INT | YES | Processing status. Uses the same Dictionary.TransactionStatus values as sent transactions but in the context of receive processing (0=Pending processing, 1=Confirmed/credited, etc.) (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses). |
| 3 | Occurred | TIMESTAMP | YES | Timestamp of this processing step (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses). |
| 4 | DetailsJson | STRING | YES | JSON payload with step-specific context (AML results, error details, processing metadata) (Tier 3 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses). |
| 5 | etr_y | INT | YES | Source: WalletDB.Wallet.ReceivedTransactionStatuses.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ym | STRING | YES | Source: WalletDB.Wallet.ReceivedTransactionStatuses.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.ReceivedTransactionStatuses.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.ReceivedTransactionStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.ReceivedTransactionStatuses
        │
        ▼
main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses) |
| ReceivedTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses) |
| StatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses) |
| DetailsJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ReceivedTransactionStatuses) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ReceivedTransactionStatuses.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
