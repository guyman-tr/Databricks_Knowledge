---
object_fqn: main.bi_db.bronze_walletdb_wallet_termsandconditions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_wallet_termsandconditions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:13:12Z'
upstreams:
- WalletDB.Wallet.TermsAndConditions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: TermsAndConditions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/TermsAndConditions
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

# bronze_walletdb_wallet_termsandconditions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Wallet.TermsAndConditions`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_wallet_termsandconditions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Dec 09 08:16:32 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.TermsAndConditions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md`.

- Lake path: `Bronze/WalletDB/Wallet/TermsAndConditions`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.TermsAndConditions`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Auto-incrementing surrogate primary key. Referenced by Wallet.CustomerTermsAndConditions to record which version a user accepted (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |
| 1 | Version | STRING | YES | Version identifier string (e.g., "V1", "V2", "V3"). Combined with TypeId forms a unique business key. Sequential versioning allows easy comparison of acceptance currency (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |
| 2 | Url | STRING | YES | URL to the PDF document containing the full T&C text. Hosted on eToro domains (etorox.com, etoro.com). Used to present the document to users for review before acceptance (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |
| 3 | Occured | TIMESTAMP | YES | Timestamp when this T&C version was published/inserted. Note: column name contains a typo ("Occured" instead of "Occurred"). Used to determine the chronological order of T&C versions (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |
| 4 | TypeId | INT | YES | Legal entity type identifier that scopes this T&C version. Different eToro entities (eToroX, eToroUS, eToroEU, etc.) may have jurisdiction-specific terms. Part of unique constraint with Version. Implicit reference to the eToro legal entity system (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |
| 5 | LinksJson | STRING | YES | JSON object containing associated legal links: feesAndLimitsUrl, termsOfUseUrl, sendTransactionWarningLink, customerSupport. These links are displayed in the wallet UI alongside the T&C acceptance prompt. Schema is consistent across versions (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.TermsAndConditions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.TermsAndConditions
        │
        ▼
main.bi_db.bronze_walletdb_wallet_termsandconditions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |
| Version | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |
| Url | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |
| Occured | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |
| TypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |
| LinksJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TermsAndConditions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TermsAndConditions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
