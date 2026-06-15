---
object_fqn: main.wallet.bronze_walletdb_wallet_travelruleaddresses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_travelruleaddresses
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T12:08:07Z'
upstreams:
- WalletDB.Wallet.TravelRuleAddresses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: TravelRuleAddresses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/TravelRuleAddresses
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

# bronze_walletdb_wallet_travelruleaddresses

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.TravelRuleAddresses`). 13 of 13 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_travelruleaddresses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 13 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:23:01 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.TravelRuleAddresses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md`.

- Lake path: `Bronze/WalletDB/Wallet/TravelRuleAddresses`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.TravelRuleAddresses`
- 13 of 13 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing PK. FK target for Wallet.TravelRuleSends (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 1 | WalletId | STRING | YES | Customer wallet this address belongs to. FK to Wallet.WalletPool.WalletId (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 2 | ToAddress | STRING | YES | The whitelisted external blockchain address (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 3 | TravelRuleAddressTypeId | INT | YES | Address type: 1=Private (self-hosted), 2=Hosted (VASP). See [Travel Rule Address Type](../../_glossary.md#travel-rule-address-type). FK to Dictionary.TravelRuleAddressType (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 4 | SelfAccount | BOOLEAN | YES | Whether the beneficiary is the same person as the sender: 1=self-transfer, 0=third-party transfer. Affects compliance requirements (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 5 | HostingCompany | STRING | YES | Name of the VASP hosting the destination address (from Wallet.HostingCompanies list). NULL for private/self-hosted addresses (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 6 | Name | STRING | YES | Beneficiary's full name. MASKED for PII protection. NULL for self-transfers (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 7 | CountryAlpha3Code | STRING | YES | Beneficiary's country (ISO 3166 alpha-3). MASKED (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 8 | State | STRING | YES | Beneficiary's state/province. MASKED (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 9 | City | STRING | YES | Beneficiary's city. MASKED (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 10 | Address | STRING | YES | Beneficiary's street address. MASKED (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 11 | Zipcode | STRING | YES | Beneficiary's postal code. MASKED (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |
| 12 | Created | TIMESTAMP | YES | Timestamp when this address was whitelisted (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.TravelRuleAddresses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.TravelRuleAddresses
        │
        ▼
main.wallet.bronze_walletdb_wallet_travelruleaddresses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| ToAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| TravelRuleAddressTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| SelfAccount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| HostingCompany | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| Name | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| CountryAlpha3Code | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| State | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| City | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| Zipcode | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TravelRuleAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TravelRuleAddresses) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 13 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: bronze_tier1_inheritance*
