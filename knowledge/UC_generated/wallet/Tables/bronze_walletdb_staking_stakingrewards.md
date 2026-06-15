---
object_fqn: main.wallet.bronze_walletdb_staking_stakingrewards
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_staking_stakingrewards
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:08:03Z'
upstreams:
- WalletDB.Staking.StakingRewards
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md
  source_database: WalletDB
  source_schema: Staking
  source_table: StakingRewards
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Staking/StakingRewards
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

# bronze_walletdb_staking_stakingrewards

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Staking.StakingRewards`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_staking_stakingrewards` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:17:17 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Staking.StakingRewards` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md`.

- Lake path: `Bronze/WalletDB/Staking/StakingRewards`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Staking.StakingRewards`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 1 | StakingIncomeId | LONG | YES | External income identifier from the reward calculation system. Used as idempotency key by InsertStakingReward (`EXISTS` check prevents duplicate inserts). Indexed by `idx_StakingIncomeId` for fast lookups (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 2 | CryptoId | INT | YES | The cryptocurrency for which the reward was earned. FK to Wallet.CryptoTypes.CryptoID. Currently all records are CryptoId=2 (ETH). Part of the unique constraint (CryptoId, WalletId, StakingMonthId). Resolved from Wallet.CustomerWalletsView by InsertStakingReward if NULL (backward compatibility) (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 3 | WalletId | STRING | YES | The wallet receiving the staking reward. FK to Wallet.Wallets.WalletId. Part of the unique constraint. Used with Gcid from Wallet.CustomerWalletsView for per-user reward lookups in GetStakingRewardList (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 4 | StakingMonthId | INT | YES | The staking period month in YYYYMM format (e.g., 202306 = June 2023). Part of the unique constraint ensuring one reward per wallet per crypto per month. Ranges from 202106 to 202306 in current data (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 5 | MonthlyReward | DECIMAL | YES | The amount of crypto earned as staking reward for this month, in the asset's native units (e.g., 0.01172 ETH). Summed by Staking.GetStakingTotals for total rewards per wallet. Must exceed ~$1 USD equivalent to be distributed (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 6 | MonthlyYieldPercentage | DECIMAL | YES | The overall staking pool yield percentage for this month. Recent records show 0, suggesting yield tracking may have been externalized (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 7 | UserYieldPercentage | DECIMAL | YES | The user's share of the pool yield, based on their eToro club tier. Recent records show 0, suggesting calculation moved upstream. Per Confluence, yield varies by club level (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 8 | IncomeDate | TIMESTAMP | YES | The date/time when the reward was calculated or distributed. Multiple rewards in the same batch share the same IncomeDate (e.g., all June 2023 rewards have 2023-06-18T07:58:54) (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |
| 9 | Occurred | TIMESTAMP | YES | Timestamp when this reward record was inserted into the database. Slightly after IncomeDate due to processing time (Tier 1 — inherited from WalletDB.Staking.StakingRewards). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Staking.StakingRewards` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Staking.StakingRewards
        │
        ▼
main.wallet.bronze_walletdb_staking_stakingrewards   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| StakingIncomeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| StakingMonthId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| MonthlyReward | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| MonthlyYieldPercentage | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| UserYieldPercentage | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| IncomeDate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingRewards.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingRewards) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
