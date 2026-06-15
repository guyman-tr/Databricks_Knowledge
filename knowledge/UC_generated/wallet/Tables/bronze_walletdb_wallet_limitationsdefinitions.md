---
object_fqn: main.wallet.bronze_walletdb_wallet_limitationsdefinitions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_limitationsdefinitions
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:08:05Z'
upstreams:
- WalletDB.Wallet.LimitationsDefinitions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: LimitationsDefinitions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/LimitationsDefinitions
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

# bronze_walletdb_wallet_limitationsdefinitions

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.LimitationsDefinitions`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_limitationsdefinitions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:20:26 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.LimitationsDefinitions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md`.

- Lake path: `Bronze/WalletDB/Wallet/LimitationsDefinitions`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.LimitationsDefinitions`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate primary key. Referenced by LimitExceeds when recording which rule was breached (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 1 | DefinitionJson | STRING | YES | Full structured definition of the limit rule consumed by the evaluation service. Contains threshold values, period windows, and any additional rule parameters not captured in scalar columns (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 2 | LastChanged | TIMESTAMP | YES | UTC timestamp of the most recent modification to this limit definition. Tracks when operations last adjusted this rule (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 3 | LastChangedBy | STRING | YES | Identity (username or service account) that last modified this row. Provides an audit trail for limit configuration changes (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 4 | IsActive | BOOLEAN | YES | 1=limit rule is currently evaluated; 0=retired/deactivated. Only active rules are applied during transaction validation (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 5 | LimitClassificationId | INT | YES | Enforcement mode: 1=Soft (alert only), 2=Hard (block transaction). FK to Dict.LimitClassifications (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 6 | LimitTypeId | INT | YES | Threshold direction: 1=Min (amount must be >= threshold), 2=Max (amount must be <= threshold). FK to Dict.LimitTypes (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 7 | LimitTargetId | INT | YES | Evaluation scope target: 1=User (per customer), 2=Global (platform-wide). FK to Dict.LimitTargets (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 8 | TransactionTypeId | INT | YES | The transaction type this limit governs. FK to Dict.TransactionTypes (e.g., Send, Receive, Buy) (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 9 | CryptoId | INT | YES | Specific cryptocurrency this rule applies to. NULL when rule is defined at category level (see CryptoCategoryName). FK to Wallet.CryptoTypes (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 10 | CryptoCategoryName | STRING | YES | Named category of cryptocurrencies this rule applies to (e.g., "Stablecoins"). Used when the rule covers a group rather than a single asset. Mutually exclusive with CryptoId per convention (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 11 | LimitScopeId | INT | YES | Aggregation scope: 1=Single (applies to individual transaction), 2=Periodic (applies to rolling sum over a time window). FK to Dict.LimitScopes (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |
| 12 | LimitActionId | INT | YES | Action taken on breach: 1=Enforce (apply the limit), 2=Alert (notify only). FK to Dict.LimitActions (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.LimitationsDefinitions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.LimitationsDefinitions
        │
        ▼
main.wallet.bronze_walletdb_wallet_limitationsdefinitions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| DefinitionJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LastChanged | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LastChangedBy | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| IsActive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LimitClassificationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LimitTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LimitTargetId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| TransactionTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| CryptoCategoryName | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LimitScopeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |
| LimitActionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.LimitationsDefinitions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.LimitationsDefinitions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
