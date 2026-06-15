---
object_fqn: main.wallet.bronze_walletdb_wallet_conversionstatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_conversionstatuses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Wallet.ConversionStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: ConversionStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/ConversionStatuses
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 6
  unverified_columns: 0
---

# bronze_walletdb_wallet_conversionstatuses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.ConversionStatuses`). 4 of 10 columns inherited from Tier 1 source wiki; 6 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_conversionstatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Mar 01 10:35:02 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.ConversionStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md`.

- Lake path: `Bronze/WalletDB/Wallet/ConversionStatuses`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.ConversionStatuses`
- 4 of 10 columns inherited; 6 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing event identifier (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses). |
| 1 | ConversionId | LONG | YES | Parent conversion. FK to Wallet.Conversions.Id (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses). |
| 2 | ConversionStatusId | INT | YES | Status: 1=Pending, 2=Failed, 3=Completed. See [Conversion Status](../../_glossary.md#conversion-status). FK to Dictionary.ConversionStatuses (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses). |
| 3 | Occurred | TIMESTAMP | YES | Timestamp of this status transition (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses). |
| 4 | etr_y2 | STRING | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_y2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | etr_ym2 | STRING | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_ym2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ymd2 | STRING | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_ymd2. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_y | INT | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | etr_ym | STRING | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.ConversionStatuses.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.ConversionStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.ConversionStatuses
        │
        ▼
main.wallet.bronze_walletdb_wallet_conversionstatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses) |
| ConversionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses) |
| ConversionStatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.ConversionStatuses) |
| etr_y2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_y2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_ym2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd2 | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_ymd2` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.ConversionStatuses.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 6 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
