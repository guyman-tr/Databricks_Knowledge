---
object_fqn: main.wallet.bronze_walletdb_staking_stakingtransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_staking_stakingtransactions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Staking.StakingTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md
  source_database: WalletDB
  source_schema: Staking
  source_table: StakingTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Staking/StakingTransactions
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 6
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_staking_stakingtransactions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Staking.StakingTransactions`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_staking_stakingtransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:17:00 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Staking.StakingTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md`.

- Lake path: `Bronze/WalletDB/Staking/StakingTransactions`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Staking.StakingTransactions`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |
| 1 | ExternalStakingAddress | STRING | YES | The blockchain address of the staking pool where assets were sent. For ETH, an Ethereum address (0x-prefixed). Denormalized from Staking.StakingExternalAddress to preserve historical address even if the active pool changes. Passed as a parameter to InsertStakingTransaction (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |
| 2 | StakingId | LONG | YES | The staking operation this transaction belongs to. FK to Staking.Staking.Id. 1:1 relationship - each staking operation has exactly one transaction record. Used by Staking.StakingData view to join fees into the reporting dataset (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |
| 3 | EtoroFee | DECIMAL | YES | eToro's service fee for processing the staking delegation, in the staked crypto's units. Currently 0 across all records - staking transfers are fee-free for users (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |
| 4 | BlockchainEstFee | DECIMAL | YES | Estimated blockchain network fee (gas fee) for the staking transaction, in the staked crypto's units. Currently 0 across all records - blockchain fees absorbed by eToro (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |
| 5 | Occurred | TIMESTAMP | YES | Timestamp when this transaction record was created. Closely follows the Staking.Staking.Occurred timestamp (typically within 1 second) (Tier 1 — inherited from WalletDB.Staking.StakingTransactions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Staking.StakingTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Staking.StakingTransactions
        │
        ▼
main.wallet.bronze_walletdb_staking_stakingtransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |
| ExternalStakingAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |
| StakingId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |
| EtoroFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |
| BlockchainEstFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingTransactions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
