---
object_fqn: main.bi_db.bronze_walletdb_wallet_walletpoolattributes
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_wallet_walletpoolattributes
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:13:12Z'
upstreams:
- WalletDB.Wallet.WalletPoolAttributes
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: WalletPoolAttributes
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/WalletPoolAttributes
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

# bronze_walletdb_wallet_walletpoolattributes

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Wallet.WalletPoolAttributes`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_wallet_walletpoolattributes` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jun 22 18:15:55 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.WalletPoolAttributes` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md`.

- Lake path: `Bronze/WalletDB/Wallet/WalletPoolAttributes`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.WalletPoolAttributes`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes). |
| 1 | WalletPoolId | LONG | YES | The pool wallet this attribute record belongs to. FK to Wallet.WalletPool.Id. Unique constraint - one attributes record per pool wallet (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes). |
| 2 | ReservedAmount | DECIMAL | YES | Amount of crypto that must remain in the wallet as a blockchain-mandated minimum reserve. Cannot be withdrawn by the user. Common for XRP (1.2) and XLM (1.0) (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes). |
| 3 | Occurred | TIMESTAMP | YES | Timestamp when this attributes record was created (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes). |
| 4 | CreationFee | DECIMAL | YES | Fee paid to create this wallet on the blockchain. NULL for blockchains without on-chain wallet creation fees. Relevant for account-based blockchains like EOS (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.WalletPoolAttributes` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.WalletPoolAttributes
        │
        ▼
main.bi_db.bronze_walletdb_wallet_walletpoolattributes   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes) |
| WalletPoolId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes) |
| ReservedAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes) |
| CreationFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.WalletPoolAttributes.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.WalletPoolAttributes) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
