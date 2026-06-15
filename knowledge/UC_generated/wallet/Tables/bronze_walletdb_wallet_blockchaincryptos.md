---
object_fqn: main.wallet.bronze_walletdb_wallet_blockchaincryptos
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_blockchaincryptos
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Wallet.BlockchainCryptos
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: BlockchainCryptos
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/BlockchainCryptos
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_blockchaincryptos

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.BlockchainCryptos`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_blockchaincryptos` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:21:43 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.BlockchainCryptos` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md`.

- Lake path: `Bronze/WalletDB/Wallet/BlockchainCryptos`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.BlockchainCryptos`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Unique blockchain network identifier. Manually assigned (not IDENTITY) to maintain stable IDs across environments. Referenced by Wallet.CryptoTypes, Wallet.Wallets, Wallet.WalletPool, and Wallet.BlockchainCryptoProviders as BlockchainCryptoId. Gaps exist in sequence (e.g., 5, 7 missing) - likely reserved IDs for blockchains that were planned but not launched (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos). |
| 1 | Name | STRING | YES | Standard ticker symbol for the blockchain (e.g., BTC, ETH, XRP, SOL). Unique constraint enforced by IX_Wallet_BlockchainCryptos__Name. Used for human-readable identification and API parameter matching (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos). |
| 2 | Occurred | TIMESTAMP | YES | Timestamp when this blockchain was added to the system. Original blockchains (BTC, ETH, BCH, XRP, LTC, XLM) all share the same date (2019-06-11), indicating the initial platform launch batch. Newer chains have later dates tracking their go-live (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos). |
| 3 | CryptoCoinProviderId | INT | YES | Blockchain provider implementation used for this chain: 1=BitGoBlockchainProviderV2 (UTXO chains like BTC, LTC, BCH, also SOL, ADA, DOGE, TRX, ETC), 2=BitGoEthereumProviderV2 (ETH/ERC-20), 3=BitgoRippleProviderV2 (XRP), 4=BitGoStellarProviderV2 (XLM), 5=BitGoEOSProviderV2 (EOS). See [Crypto Coin Provider](../../_glossary.md#crypto-coin-provider). FK to Dictionary.CryptoCoinProviders (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos). |
| 4 | AddressPattern | STRING | YES | Regex pattern for validating blockchain addresses before any transaction. Each blockchain has a unique pattern matching its address format. The default `(.*?)` accepts all strings (used when provider handles validation). Updated when chains add new address formats (e.g., Bitcoin SegWit) (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.BlockchainCryptos` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.BlockchainCryptos
        │
        ▼
main.wallet.bronze_walletdb_wallet_blockchaincryptos   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos) |
| Name | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos) |
| CryptoCoinProviderId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos) |
| AddressPattern | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptos.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptos) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
