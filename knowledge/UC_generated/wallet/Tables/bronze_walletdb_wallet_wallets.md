---
object_fqn: main.wallet.bronze_walletdb_wallet_wallets
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_wallets
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:08:08Z'
upstreams:
- WalletDB.Wallet.Wallets
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: Wallets
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/Wallets
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_wallet_wallets

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.Wallets`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_wallets` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:20:41 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.Wallets` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md`.

- Lake path: `Bronze/WalletDB/Wallet/Wallets`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.Wallets`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 1 | WalletId | STRING | YES | Internal wallet identifier (GUID). Unique constraint. The universal business key used across the entire system. FK target for Wallet.SentTransactions, Wallet.Conversions, Wallet.Payments, Wallet.Redemptions, and Wallet.WalletAssets. Matches the WalletId in Wallet.WalletPool from which this wallet was assigned (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 2 | Gcid | LONG | YES | Global Customer ID of the wallet owner. For system wallets (types 1-4, 6-7), this is a system/service account ID. For customer wallets (type 5), this is the real user. Indexed for per-customer lookups (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 3 | BlockchainCryptoId | INT | YES | The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Combined with Gcid and WalletTypeId for unique customer wallet constraint (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 4 | WalletTypeId | INT | YES | Operational purpose: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 5 | IsActive | BOOLEAN | YES | Whether this wallet is currently operational. 1=active, 0=deactivated (funds locked, no new transactions). Set to 0 by Wallet.DeactivateWallet (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 6 | Occurred | TIMESTAMP | YES | Timestamp when this wallet was created/assigned to the customer (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 7 | BeginDate | TIMESTAMP | YES | System-versioned temporal column (ROW START). Tracks when this version of the row became current (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 8 | EndDate | TIMESTAMP | YES | System-versioned temporal column (ROW END). Default 9999-12-31 for current rows (Tier 3 — inherited from WalletDB.Wallet.Wallets). |
| 9 | IsActivated | BOOLEAN | YES | Whether the wallet has completed blockchain activation. 1=fully activated, 0=pending activation (awaiting on-chain confirmation). Most wallets are immediately activated (Tier 3 — inherited from WalletDB.Wallet.Wallets). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.Wallets` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.Wallets
        │
        ▼
main.wallet.bronze_walletdb_wallet_wallets   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| WalletTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| BeginDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| EndDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |
| IsActivated | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.Wallets.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.Wallets) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
