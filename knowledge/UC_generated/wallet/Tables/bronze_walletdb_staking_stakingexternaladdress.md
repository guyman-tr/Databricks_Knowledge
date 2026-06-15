---
object_fqn: main.wallet.bronze_walletdb_staking_stakingexternaladdress
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_staking_stakingexternaladdress
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:08:03Z'
upstreams:
- WalletDB.Staking.StakingExternalAddress
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md
  source_database: WalletDB
  source_schema: Staking
  source_table: StakingExternalAddress
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Staking/StakingExternalAddress
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

# bronze_walletdb_staking_stakingexternaladdress

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Staking.StakingExternalAddress`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_staking_stakingexternaladdress` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 16:00:08 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Staking.StakingExternalAddress` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md`.

- Lake path: `Bronze/WalletDB/Staking/StakingExternalAddress`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Staking.StakingExternalAddress`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Auto-incrementing surrogate key. Used as RecordId in Wallet.Checksums for address integrity verification (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress). |
| 1 | ExternalAddress | STRING | YES | The blockchain address of eToro's staking pool. For ETH, this is an Ethereum address (0x-prefixed, 42 chars). This is the destination address for staking transfers. Read by Staking.GetStakingExternalAddress and validated by the checksum procedures (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress). |
| 2 | CryptoId | INT | YES | The cryptocurrency this staking address serves. FK to Wallet.CryptoTypes.CryptoID. Currently only 2 (ETH). Part of the unique constraint ensuring one active address per crypto (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress). |
| 3 | IsActive | BOOLEAN | YES | Whether this address is the currently active staking pool for its crypto. 1=active (used for new staking transfers), 0=retired (kept for audit). Default 1 for new addresses. Filtered by GetStakingExternalAddress and part of unique index (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress). |
| 4 | EffectiveFrom | TIMESTAMP | YES | Timestamp when this address became the active staking pool. Defaults to UTC now on insert. Used for audit trail when addresses are rotated (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Staking.StakingExternalAddress` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Staking.StakingExternalAddress
        │
        ▼
main.wallet.bronze_walletdb_staking_stakingexternaladdress   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress) |
| ExternalAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress) |
| EffectiveFrom | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Staking/Tables/Staking.StakingExternalAddress.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Staking.StakingExternalAddress) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
