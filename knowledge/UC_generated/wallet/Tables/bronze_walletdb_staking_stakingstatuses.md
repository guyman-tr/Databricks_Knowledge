---
object_fqn: main.wallet.bronze_walletdb_staking_stakingstatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_staking_stakingstatuses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:08:03Z'
upstreams:
- WalletDB.Staking.StakingStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md
  source_database: WalletDB
  source_schema: Staking
  source_table: StakingStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Staking/StakingStatuses
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

# bronze_walletdb_staking_stakingstatuses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Staking.StakingStatuses`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_staking_stakingstatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:16:45 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Staking.StakingStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md`.

- Lake path: `Bronze/WalletDB/Staking/StakingStatuses`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Staking.StakingStatuses`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key. Monotonically increasing, used to establish event ordering when Occurred timestamps collide (Tier 1 — inherited from WalletDB.Staking.StakingStatuses). |
| 1 | StakingId | LONG | YES | The staking operation this status event belongs to. FK to Staking.Staking.Id. Each staking operation has 2+ status rows (Pending + terminal). Used by StakingData view's ROW_NUMBER() PARTITION for latest-status extraction (Tier 1 — inherited from WalletDB.Staking.StakingStatuses). |
| 2 | StakingStatusId | INT | YES | The status being applied. FK to Dictionary.StakingStatuses.Id: 1=Pending, 2=Failed, 3=Completed. See [Staking Status](../../_glossary.md#staking-status). Filtered by GetStakingTotals (WHERE StakingStatusId=3) for completed-only aggregation (Tier 1 — inherited from WalletDB.Staking.StakingStatuses). |
| 3 | DetailsJson | STRING | YES | Optional JSON payload for status-specific details (e.g., error messages for Failed status). Currently unused - all 4,419 rows have NULL. Column exists for extensibility (Tier 1 — inherited from WalletDB.Staking.StakingStatuses). |
| 4 | Occurred | TIMESTAMP | YES | Timestamp of this status transition. Defaults to UTC now. Used by StakingData view to determine the latest status per staking (ORDER BY Occurred DESC in ROW_NUMBER window). The time difference between Pending and Completed Occurred values indicates blockchain processing duration (Tier 1 — inherited from WalletDB.Staking.StakingStatuses). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Staking.StakingStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Staking.StakingStatuses
        │
        ▼
main.wallet.bronze_walletdb_staking_stakingstatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingStatuses) |
| StakingId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingStatuses) |
| StakingStatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingStatuses) |
| DetailsJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingStatuses) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingStatuses) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
