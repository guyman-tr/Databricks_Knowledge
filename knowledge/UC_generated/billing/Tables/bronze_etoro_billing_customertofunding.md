---
object_fqn: main.billing.bronze_etoro_billing_customertofunding
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_customertofunding
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 14
row_count: null
generated_at: '2026-05-18T10:58:31Z'
upstreams:
- etoro.Billing.CustomerToFunding
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md
  source_database: etoro
  source_schema: Billing
  source_table: CustomerToFunding
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/CustomerToFunding
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 14
  unverified_columns: 0
---

# bronze_etoro_billing_customertofunding

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.CustomerToFunding`). 0 of 14 columns inherited from Tier 1 source wiki; 14 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_customertofunding` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 14 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Mar 11 13:50:16 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.CustomerToFunding` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md`.

- Lake path: `Bronze/etoro/Billing/CustomerToFunding`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.CustomerToFunding`
- 0 of 14 columns inherited; 14 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Source: etoro.Billing.CustomerToFunding.CID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 1 | FundingID | INT | YES | Source: etoro.Billing.CustomerToFunding.FundingID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 2 | Occurred | TIMESTAMP | YES | Source: etoro.Billing.CustomerToFunding.Occurred. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 3 | DepositTypeID | INT | YES | Source: etoro.Billing.CustomerToFunding.DepositTypeID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 4 | ReasonID | INT | YES | Source: etoro.Billing.CustomerToFunding.ReasonID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | LastUsedDate | TIMESTAMP | YES | Source: etoro.Billing.CustomerToFunding.LastUsedDate. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | CustomerFundingStatusID | INT | YES | Source: etoro.Billing.CustomerToFunding.CustomerFundingStatusID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | IsBlocked | BOOLEAN | YES | Source: etoro.Billing.CustomerToFunding.IsBlocked. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | IsRefundExcluded | BOOLEAN | YES | Source: etoro.Billing.CustomerToFunding.IsRefundExcluded. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | ManagerID | INT | YES | Source: etoro.Billing.CustomerToFunding.ManagerID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | BlockedAt | TIMESTAMP | YES | Source: etoro.Billing.CustomerToFunding.BlockedAt. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | BlockedDescription | STRING | YES | Source: etoro.Billing.CustomerToFunding.BlockedDescription. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | IsVerified | BOOLEAN | YES | Source: etoro.Billing.CustomerToFunding.IsVerified. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | BlockManagerID | INT | YES | Source: etoro.Billing.CustomerToFunding.BlockManagerID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.CustomerToFunding` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.CustomerToFunding
        │
        ▼
main.billing.bronze_etoro_billing_customertofunding   ←── this object
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
| CID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `CID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| FundingID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `FundingID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| Occurred | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `Occurred` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| DepositTypeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `DepositTypeID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ReasonID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `ReasonID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| LastUsedDate | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `LastUsedDate` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| CustomerFundingStatusID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `CustomerFundingStatusID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| IsBlocked | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `IsBlocked` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| IsRefundExcluded | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `IsRefundExcluded` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ManagerID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `ManagerID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| BlockedAt | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `BlockedAt` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| BlockedDescription | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `BlockedDescription` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| IsVerified | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `IsVerified` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| BlockManagerID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CustomerToFunding.md` but column `BlockManagerID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 14 T5, 0 U | Elements: 14/14 | Source: bronze_tier1_inheritance*
