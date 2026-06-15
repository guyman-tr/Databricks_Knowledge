---
object_fqn: main.bi_db.bronze_walletdb_eligibility_travelrulewhitelistedaddresses
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_eligibility_travelrulewhitelistedaddresses
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:13:11Z'
upstreams:
- WalletDB.Eligibility.TravelRuleWhitelistedAddresses
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md
  source_database: WalletDB
  source_schema: Eligibility
  source_table: TravelRuleWhitelistedAddresses
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Eligibility/TravelRuleWhitelistedAddresses
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_eligibility_travelrulewhitelistedaddresses

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Eligibility.TravelRuleWhitelistedAddresses`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_eligibility_travelrulewhitelistedaddresses` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Sun May 25 15:16:11 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Eligibility.TravelRuleWhitelistedAddresses` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md`.

- Lake path: `Bronze/WalletDB/Eligibility/TravelRuleWhitelistedAddresses`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Eligibility.TravelRuleWhitelistedAddresses`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key. Each row represents one verified address-customer-blockchain combination (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 1 | Gcid | LONG | YES | Global Customer ID identifying the customer who proved ownership of this address. Used in the uniqueness check: an address whitelisted for one Gcid cannot be claimed by another. Also used by `AddWhitelistedAddressAndUpdateTravelRuleStatus` to match pending travel rule transactions (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 2 | BlockchainCryptoId | INT | YES | Identifies the blockchain network of the whitelisted address. Values observed: 1=Bitcoin (59%), 2=Ethereum (37%), 18=Cardano (3%), 6 and 19=other chains. Part of the uniqueness constraint alongside Gcid and Address (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 3 | Created | TIMESTAMP | YES | UTC timestamp of when the whitelist entry was created. Set to `GETUTCDATE()` by all three writer procedures on INSERT. Indexed as part of a composite covering index with Gcid, BlockchainCryptoId, and Address (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 4 | Address | STRING | YES | The full blockchain address string that has been verified. Format varies by blockchain: "0x..." for Ethereum, "addr1q..." for Cardano, various formats for Bitcoin. Has a dedicated nonclustered index for fast lookup by `GetTravelRuleWhitelistedAddress`. The uniqueness enforcement logic checks this column across all customers (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 5 | ProofOfOwnership | STRING | YES | The actual proof data - either the cryptographic signature bytes or the signed declaration text. Stored as a large text/blob since cryptographic signatures can be lengthy. Used for compliance audit purposes (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |
| 6 | ProofOfOwnershipTypeId | INT | YES | Method used to verify address ownership. FK to Dictionary.AddressOwnershipProofType: 1=Declaration (legal self-attestation), 2=Signature (cryptographic private key signing). In practice, 100% of current entries use Signature (2). See [Address Ownership Proof Type](../_glossary.md#address-ownership-proof-type) (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Eligibility.TravelRuleWhitelistedAddresses` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Eligibility.TravelRuleWhitelistedAddresses
        │
        ▼
main.bi_db.bronze_walletdb_eligibility_travelrulewhitelistedaddresses   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| BlockchainCryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| ProofOfOwnership | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |
| ProofOfOwnershipTypeId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.TravelRuleWhitelistedAddresses.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.TravelRuleWhitelistedAddresses) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
