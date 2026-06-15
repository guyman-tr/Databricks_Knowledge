---
object_fqn: main.wallet.bronze_walletdb_dictionary_conversionstatuses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_dictionary_conversionstatuses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-19T12:08:01Z'
upstreams:
- WalletDB.Dictionary.ConversionStatuses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md
  source_database: WalletDB
  source_schema: Dictionary
  source_table: ConversionStatuses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Dictionary/ConversionStatuses
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_dictionary_conversionstatuses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Dictionary.ConversionStatuses`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_dictionary_conversionstatuses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 13:20:45 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Dictionary.ConversionStatuses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md`.

- Lake path: `Bronze/WalletDB/Dictionary/ConversionStatuses`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Dictionary.ConversionStatuses`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Unique identifier for the conversion status. Values: 1=Pending, 2=Failed, 3=Completed. FK target for Wallet.ConversionStatuses and referenced in conversion transaction queries (Tier 1 — inherited from WalletDB.Dictionary.ConversionStatuses). |
| 1 | Name | STRING | YES | Human-readable status label. Displayed in customer transaction history and used in operational monitoring dashboards (Tier 1 — inherited from WalletDB.Dictionary.ConversionStatuses). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Dictionary.ConversionStatuses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Dictionary.ConversionStatuses
        │
        ▼
main.wallet.bronze_walletdb_dictionary_conversionstatuses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Dictionary.ConversionStatuses) |
| Name | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Dictionary/Tables/Dictionary.ConversionStatuses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Dictionary.ConversionStatuses) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
