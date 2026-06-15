---
object_fqn: main.wallet.bronze_walletdb_wallet_senttransactionoutputs
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_senttransactionoutputs
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 14
row_count: null
generated_at: '2026-05-19T12:08:06Z'
upstreams:
- WalletDB.Wallet.SentTransactionOutputs
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: SentTransactionOutputs
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/SentTransactionOutputs
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_senttransactionoutputs

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.SentTransactionOutputs`). 11 of 14 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_senttransactionoutputs` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 14 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:10:52 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.SentTransactionOutputs` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md`.

- Lake path: `Bronze/WalletDB/Wallet/SentTransactionOutputs`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.SentTransactionOutputs`
- 11 of 14 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing key starting at 0 (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 1 | SentTransactionId | LONG | YES | Parent sent transaction. FK to Wallet.SentTransactions.Id. Multiple outputs per transaction possible (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 2 | ToAddress | STRING | YES | Destination blockchain address for this output (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 3 | Amount | DECIMAL | YES | Amount of crypto sent to this output address (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 4 | EtoroFees | DECIMAL | YES | eToro service fee allocated to this output (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 5 | BlockchainFees | DECIMAL | YES | Network fee allocated to this output. NULL when fee is at transaction level (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 6 | SourceId | LONG | YES | Business entity ID this output originated from. For redemptions, this is the PositionId (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 7 | SourceIdType | INT | YES | Type of SourceId: 0=PositionId. See [Transaction Output Source ID Type](../../_glossary.md#transaction-output-source-id-type) (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 8 | Occurred | TIMESTAMP | YES | Timestamp of this output record creation (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 9 | IsEtoroFee | BOOLEAN | YES | Whether this output represents an eToro fee payment rather than a value transfer. 1=fee output, 0/NULL=value output (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 10 | NormalizedToAddress | STRING | YES | Computed PERSISTED column stripping protocol prefix and query parameters from ToAddress (Tier 3 — inherited from WalletDB.Wallet.SentTransactionOutputs). |
| 11 | etr_y | INT | YES | Source: WalletDB.Wallet.SentTransactionOutputs.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | etr_ym | STRING | YES | Source: WalletDB.Wallet.SentTransactionOutputs.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.SentTransactionOutputs.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.SentTransactionOutputs` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.SentTransactionOutputs
        │
        ▼
main.wallet.bronze_walletdb_wallet_senttransactionoutputs   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| SentTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| ToAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| EtoroFees | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| BlockchainFees | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| SourceId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| SourceIdType | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| IsEtoroFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| NormalizedToAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.SentTransactionOutputs) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.SentTransactionOutputs.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 14/14 | Source: bronze_tier1_inheritance*
