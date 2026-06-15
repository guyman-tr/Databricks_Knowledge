---
object_fqn: main.wallet.bronze_walletdb_wallet_customerwalletsview
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_customerwalletsview
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:08:05Z'
upstreams:
- WalletDB.Wallet.CustomerWalletsView
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: CustomerWalletsView
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/CustomerWalletsView
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_customerwalletsview

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.CustomerWalletsView`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_customerwalletsview` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 22 18:38:32 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.CustomerWalletsView` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md`.

- Lake path: `Bronze/WalletDB/Wallet/CustomerWalletsView`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.CustomerWalletsView`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | STRING | YES | The wallet's universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system - referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups. From Wallet.Wallets.WalletId (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 1 | Gcid | LONG | YES | Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 2 | CryptoId | INT | YES | The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: `WHERE Gcid = @gcid AND CryptoId = @cryptoId`. From Wallet.WalletAssets.CryptoId (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 3 | Address | STRING | YES | Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 4 | BlockchainProviderWalletId | STRING | YES | External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId. Format is provider-specific (typically a hex hash for BitGo) (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 5 | Occurred | TIMESTAMP | YES | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 6 | WalletTypeId | INT | YES | Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes. From Wallet.Wallets.WalletTypeId (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 7 | IsActive | BOOLEAN | YES | Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by view). From Wallet.Wallets.IsActive (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 8 | Status | INT | YES | Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in view: `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END`. 99.6% of rows are Status=0 (Tier 2 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 9 | WalletRecordId | LONG | YES | Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 10 | BlockchainCryptoId | INT | YES | The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain). From Wallet.Wallets.BlockchainCryptoId (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 11 | WalletProviderId | INT | YES | Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider. From Wallet.WalletPool.WalletProviderId (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |
| 12 | IsActivated | BOOLEAN | YES | Whether the wallet has completed initial blockchain activation. 1=activated (fully operational), 0=pending activation. The Status column is derived from this value. From Wallet.Wallets.IsActivated (Tier 3 — inherited from WalletDB.Wallet.CustomerWalletsView). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.CustomerWalletsView` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.CustomerWalletsView
        │
        ▼
main.wallet.bronze_walletdb_wallet_customerwalletsview   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| BlockchainProviderWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| WalletTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| Status | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| WalletRecordId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| WalletProviderId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |
| IsActivated | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.CustomerWalletsView) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
