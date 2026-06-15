---
object_fqn: main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Wallet.BlockchainCryptoProviders
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: BlockchainCryptoProviders
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/BlockchainCryptoProviders
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

# bronze_walletdb_wallet_blockchaincryptoproviders

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.BlockchainCryptoProviders`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:21:59 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.BlockchainCryptoProviders` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md`.

- Lake path: `Bronze/WalletDB/Wallet/BlockchainCryptoProviders`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.BlockchainCryptoProviders`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders). |
| 1 | BlockchainCryptoId | INT | YES | The blockchain network this mapping applies to. FK to Wallet.BlockchainCryptos.Id. Values: 1=BTC, 2=ETH, 3=BCH, 4=XRP, 6=LTC, 8=ETC, 18=ADA, 19=DOGE, 21=XLM, 23=EOS, 27=TRX, 64=SOL (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders). |
| 2 | WalletProviderId | INT | YES | Top-level wallet custody provider: 1=BitGo (institutional multi-sig custody), 2=CUG (Crypto Unified Gateway, eToro internal), 3=None (internal/virtual operations). See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders). |
| 3 | CryptoCoinProviderid | INT | YES | Specific coin provider implementation class for this blockchain/provider combination. Maps to the technical API adapter: 1=BitGoBlockchainProviderV2, 2=BitGoEthereumProviderV2, 3=BitgoRippleProviderV2, 4=BitGoStellarProviderV2, 5=BitGoEOSProviderV2, 6=CUGBlockchainProvider, 7=BitGoTronProviderV2, 8=BitGoEthereumClassicProviderV2, 9=CUGAccountBasedBlockchainProvider. See [Crypto Coin Provider](../../_glossary.md#crypto-coin-provider). FK to Dictionary.CryptoCoinProviders (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders). |
| 4 | Occurred | TIMESTAMP | YES | Timestamp when this provider mapping was created. Enables tracking when blockchains were onboarded to specific providers (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.BlockchainCryptoProviders` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.BlockchainCryptoProviders
        │
        ▼
main.wallet.bronze_walletdb_wallet_blockchaincryptoproviders   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders) |
| WalletProviderId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders) |
| CryptoCoinProviderid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.BlockchainCryptoProviders.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.BlockchainCryptoProviders) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
