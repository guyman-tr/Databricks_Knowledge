---
object_fqn: main.wallet.bronze_walletdb_wallet_walletpool
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_walletpool
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:08:08Z'
upstreams:
- WalletDB.Wallet.WalletPool
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: WalletPool
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/WalletPool
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_walletpool

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.WalletPool`). 7 of 10 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_walletpool` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 16 07:15:35 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.WalletPool` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md`.

- Lake path: `Bronze/WalletDB/Wallet/WalletPool`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.WalletPool`
- 7 of 10 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 1 | WalletId | STRING | YES | Internal wallet identifier (GUID). The primary business key used across the wallet system. Unique constraint. FK target for Wallet.WalletAddresses, Wallet.ReceivedTransactions, and Wallet.AmlValidations. Also referenced by Wallet.Wallets (logical link, not FK) (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 2 | BlockchainCryptoId | INT | YES | The blockchain this pool wallet was created for. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain network the PublicAddress belongs to (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 3 | ProviderWalletId | STRING | YES | Wallet identifier assigned by the external custody provider (BitGo or CUG). Used for all API interactions with the provider. Format varies by provider (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 4 | PublicAddress | STRING | YES | Blockchain address associated with this wallet. Users send crypto to this address. NULL during initial creation before address generation completes. Format depends on blockchain (e.g., bc1... for BTC, 0x... for ETH) (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 5 | Created | TIMESTAMP | YES | Timestamp when this pool wallet was created. Used for pool age monitoring and FIFO assignment ordering (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 6 | WalletProviderId | INT | YES | Custody provider that holds the keys: 1=BitGo, 2=CUG, 3=None. See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider (Tier 3 — inherited from WalletDB.Wallet.WalletPool). |
| 7 | etr_y | INT | YES | Source: WalletDB.Wallet.WalletPool.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | etr_ym | STRING | YES | Source: WalletDB.Wallet.WalletPool.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.WalletPool.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.WalletPool` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.WalletPool
        │
        ▼
main.wallet.bronze_walletdb_wallet_walletpool   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| ProviderWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| PublicAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| WalletProviderId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPool) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPool.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
