---
object_fqn: main.bi_db.bronze_walletdb_eligibility_statusmap
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_eligibility_statusmap
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:13:11Z'
upstreams:
- WalletDB.Eligibility.StatusMap
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md
  source_database: WalletDB
  source_schema: Eligibility
  source_table: StatusMap
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Eligibility/StatusMap
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_walletdb_eligibility_statusmap

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Eligibility.StatusMap`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_eligibility_statusmap` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Dec 17 17:16:41 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Eligibility.StatusMap` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md`.

- Lake path: `Bronze/WalletDB/Eligibility/StatusMap`
- Copy strategy: `Override`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Eligibility.StatusMap`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Surrogate primary key identifying each unique combination in the resolution matrix. 20 rows total (4 group values x 5 customer values including NULL). Referenced by Eligibility.AllowedUpdateStatusMap via StatusMapId FK (Tier 1 — inherited from WalletDB.Eligibility.StatusMap). |
| 1 | GroupValue | INT | YES | Group-level eligibility status derived from the customer's country, account tier, or other group attributes. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the "AllowedUsingWalletStatus" from InfraSetting, per HLD. See [Eligibility Statuses](../_glossary.md#eligibility-statuses) (Tier 1 — inherited from WalletDB.Eligibility.StatusMap). |
| 2 | CustomerValue | INT | YES | Customer-level eligibility override, set individually via BackOffice or API. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. NULL means no customer-level override exists - the group status applies directly. Per HLD: "AllowedUsingWalletStatusCustomerLevel." (Tier 1 — inherited from WalletDB.Eligibility.StatusMap). |
| 3 | Status | INT | YES | Resolved effective eligibility status after applying conflict resolution between GroupValue and CustomerValue. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the final status returned by `Eligibility.GetResolvedAllowedUsingWalletStatus` and consumed by all services that validate crypto access (Tier 1 — inherited from WalletDB.Eligibility.StatusMap). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Eligibility.StatusMap` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Eligibility.StatusMap
        │
        ▼
main.bi_db.bronze_walletdb_eligibility_statusmap   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.StatusMap) |
| GroupValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.StatusMap) |
| CustomerValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.StatusMap) |
| Status | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Eligibility/Tables/Eligibility.StatusMap.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Eligibility.StatusMap) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
