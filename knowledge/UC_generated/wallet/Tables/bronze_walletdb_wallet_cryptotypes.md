---
object_fqn: main.wallet.bronze_walletdb_wallet_cryptotypes
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_cryptotypes
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 31
row_count: null
generated_at: '2026-05-19T12:08:05Z'
upstreams:
- WalletDB.Wallet.CryptoTypes
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: CryptoTypes
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/CryptoTypes
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 31
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_cryptotypes

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.CryptoTypes`). 31 of 31 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_cryptotypes` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 31 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:20:11 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.CryptoTypes` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md`.

- Lake path: `Bronze/WalletDB/Wallet/CryptoTypes`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.CryptoTypes`
- 31 of 31 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CryptoID | INT | YES | Unique identifier for this crypto asset. Manually assigned (not IDENTITY). Referenced as FK by Wallet.SentTransactions, Wallet.ReceivedTransactions, Wallet.WalletBalances, Wallet.WalletAssets, Wallet.Conversions, Wallet.Payments, Wallet.AmlProviderContracts, Wallet.CryptoMarketRatesMappings, Wallet.PromotionTags, and many stored procedures. The most widely-referenced PK in the schema (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 1 | Name | STRING | YES | Ticker symbol (e.g., BTC, ETH, USDT, LINK). Used for API parameter matching and internal identification (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 2 | MinReqAccounts | INT | YES | Minimum number of accounts/signers required for wallet operations on this crypto. Related to multi-signature wallet configuration (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 3 | MinUnit | DECIMAL | YES | Minimum transferable unit (satoshi-equivalent) for this crypto. Defines the smallest amount that can be sent (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 4 | Status | INT | YES | Legacy status field. Superseded by CryptoActivityStatus for business logic. Maintained for backward compatibility (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 5 | MinReqVerifications | INT | YES | Minimum number of blockchain confirmations required before a received transaction is considered confirmed. Varies by blockchain (e.g., BTC needs more confirmations than ETH) (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 6 | MaxVerificationTimeMinutes | LONG | YES | Maximum time in minutes to wait for blockchain confirmations before timing out a transaction. Used for monitoring stuck transactions (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 7 | Occurred | TIMESTAMP | YES | Timestamp when this crypto asset was added to the system (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 8 | IsActive | BOOLEAN | YES | Secondary activation toggle. 1=active, 0=disabled. Works alongside CryptoActivityStatus to control asset availability. Most active assets have IsActive=1 (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 9 | CryptoActivityStatus | INT | YES | Availability level for wallet operations: 0=NotActive, 1=ComingSoon, 2=Available (173 assets), 3=AvailableRedeemOnly (XRP only). See [Crypto Activity Status](../../_glossary.md#crypto-activity-status). FK to Dictionary.CryptoActivityStatuses (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 10 | BalanceAssetName | STRING | YES | Asset name as known by the balance/custody provider (e.g., BitGo's internal asset identifier). May differ from the display name (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 11 | WebHookVerifications | INT | YES | Number of webhook-based verification callbacks required from the blockchain provider before confirming a transaction (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 12 | StartMonitoringDelaySeconds | INT | YES | Delay in seconds before starting to monitor a newly submitted transaction. Default 120s allows the blockchain network to propagate the transaction (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 13 | BalanceThreshold | DECIMAL | YES | Minimum balance threshold below which a wallet is considered effectively empty. Used for balance checks and dust amount detection (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 14 | InitialFeeUnits | DECIMAL | YES | Base fee units charged per transaction for this crypto. 0 means no initial fee (blockchain fee only) (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 15 | BlockchainExplorerFormat | STRING | YES | URL format string for generating blockchain explorer links (e.g., "https://blockchain.com/btc/tx/{txId}"). Used in UI to link transactions to explorer pages (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 16 | IsEtoroHandlingFee | BOOLEAN | YES | Whether eToro charges an additional handling fee on top of blockchain network fees for this crypto. 1=yes, 0/NULL=no (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 17 | BlockchainCryptoId | INT | YES | The blockchain network this crypto asset runs on. For native coins, maps 1:1 (BTC->1, ETH->2). For ERC-20 tokens, all point to 2 (Ethereum). FK to Wallet.BlockchainCryptos.Id (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 18 | AssetTypeId | INT | YES | Asset classification: 1=Coin (12 native blockchain coins), 2=ERC20 (162 Ethereum tokens). See [Asset Type](../../_glossary.md#asset-type). FK to Dictionary.AssetTypes (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 19 | SymbolFull | STRING | YES | Full ticker symbol used in API responses and market data integration. Usually identical to Name (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 20 | DisplayName | STRING | YES | Human-readable asset name shown in the UI (e.g., "Bitcoin", "Ethereum", "Cardano"). More descriptive than the ticker symbol (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 21 | AvatarUrl | STRING | YES | URL to the crypto asset's logo/icon image. Used in the wallet UI for visual identification (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 22 | Precision | INT | YES | Number of decimal places used when displaying amounts of this crypto. BTC/ETH=6, XLM=7, EOS=4. Controls UI formatting (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 23 | TagName | STRING | YES | Name of the secondary address field required by some blockchains (e.g., "Destination Tag" for XRP, "Memo" for XLM). NULL for blockchains that don't require a tag (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 24 | InstrumentId | INT | YES | Links to the eToro trading platform's instrument for this crypto (e.g., BTC=100000, ETH=100001). Used for market rate lookups and position valuation. Implicit reference to Wallet.Instruments.InstrumentId (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 25 | AssetBlockchainAddress | STRING | YES | Smart contract address for ERC-20 tokens on the Ethereum blockchain. NULL for native coins. Used to identify the token when interacting with the Ethereum network (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 26 | OrderIndex | INT | YES | Controls display order in the wallet UI. Lower values appear first (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 27 | CryptoCategoryName | STRING | YES | Category classification for the crypto asset (e.g., "DeFi", "Payment", "Meme"). Used for UI grouping and filtering (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 28 | StakingDisplayName | STRING | YES | Display name specifically for staking context (e.g., "Cardano Staking"). NULL for non-stakeable assets (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 29 | StakingAvatarUrl | STRING | YES | Logo URL for the staking variant. May differ from the regular avatar (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |
| 30 | StakingSymbolFull | STRING | YES | Ticker symbol for staking context. NULL for non-stakeable assets (Tier 3 — inherited from WalletDB.Wallet.CryptoTypes). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.CryptoTypes` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.CryptoTypes
        │
        ▼
main.wallet.bronze_walletdb_wallet_cryptotypes   ←── this object
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
| CryptoID | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| Name | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| MinReqAccounts | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| MinUnit | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| Status | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| MinReqVerifications | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| MaxVerificationTimeMinutes | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| CryptoActivityStatus | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| BalanceAssetName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| WebHookVerifications | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| StartMonitoringDelaySeconds | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| BalanceThreshold | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| InitialFeeUnits | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| BlockchainExplorerFormat | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| IsEtoroHandlingFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| AssetTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| SymbolFull | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| DisplayName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| AvatarUrl | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| Precision | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| TagName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| InstrumentId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| AssetBlockchainAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| OrderIndex | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| CryptoCategoryName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| StakingDisplayName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| StakingAvatarUrl | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |
| StakingSymbolFull | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CryptoTypes) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 31 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 31/31 | Source: bronze_tier1_inheritance*
