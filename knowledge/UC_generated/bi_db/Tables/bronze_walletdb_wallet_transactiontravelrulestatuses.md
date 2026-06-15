---
object_fqn: main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:13:12Z'
upstreams:
- WalletDB.Wallet.TransactionTravelRuleStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: TransactionTravelRuleStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/TransactionTravelRuleStatuses
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_transactiontravelrulestatuses

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Wallet.TransactionTravelRuleStatuses`). 5 of 8 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 28 06:16:58 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.TransactionTravelRuleStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md`.

- Lake path: `Bronze/WalletDB/Wallet/TransactionTravelRuleStatuses`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.TransactionTravelRuleStatuses`
- 5 of 8 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing event identifier (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses). |
| 1 | TransactionTravelRuleInformationId | LONG | YES | Parent Travel Rule record. FK to Wallet.TransactionTravelRuleInformation.Id (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses). |
| 2 | TravelRuleStatusId | INT | YES | Status: 0=PendingManualApproval, 1=Approved, 2=Canceled, 3=PendingMissingInformation, 4=MissingInformationAdded, 5=MustCancel. See [Travel Rule Status](../../_glossary.md#travel-rule-status) (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses). |
| 3 | Occurred | TIMESTAMP | YES | Timestamp of status transition (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses). |
| 4 | DetailsJson | STRING | YES | JSON with status-specific details (approval notes, missing info details) (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses). |
| 5 | etr_y | INT | YES | Source: WalletDB.Wallet.TransactionTravelRuleStatuses.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | etr_ym | STRING | YES | Source: WalletDB.Wallet.TransactionTravelRuleStatuses.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.TransactionTravelRuleStatuses.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.TransactionTravelRuleStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.TransactionTravelRuleStatuses
        │
        ▼
main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses) |
| TransactionTravelRuleInformationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses) |
| TravelRuleStatusId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses) |
| DetailsJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleStatuses) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
