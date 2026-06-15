---
object_fqn: main.bi_db.bronze_fiktivo_affiliatecommission_creditvw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_affiliatecommission_creditvw
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 29
row_count: null
generated_at: '2026-05-19T12:12:54Z'
upstreams:
- fiktivo.AffiliateCommission.CreditVW
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md
  source_database: fiktivo
  source_schema: AffiliateCommission
  source_table: CreditVW
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/AffiliateCommission/CreditVW
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 26
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_fiktivo_affiliatecommission_creditvw

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.AffiliateCommission.CreditVW`). 26 of 29 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_affiliatecommission_creditvw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 29 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 01 08:18:53 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.AffiliateCommission.CreditVW` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md`.

- Lake path: `Bronze/fiktivo/AffiliateCommission/CreditVW`
- Copy strategy: `Merge`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `AffiliateCommission.CreditVW`
- 26 of 29 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreditID | LONG | YES | From Credit. Credit event identifier (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 1 | CreditDate | TIMESTAMP | YES | From Credit. Event timestamp (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 2 | CID | LONG | YES | From RegistrationMetaData. Customer ID (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 3 | AffiliateCampaign | STRING | YES | From RegistrationMetaData. Campaign tracking (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 4 | CreditTypeID | INT | YES | From Credit. 1=Deposit, 4/5=Chargeback (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 5 | AffiliateID | INT | YES | From RegistrationMetaData. Referring affiliate (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 6 | Amount | DOUBLE | YES | From Credit. Credit amount (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 7 | BannerID | INT | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 8 | IsFirstDeposit | BOOLEAN | YES | From Credit. FTD flag (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 9 | DownloadID | LONG | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 10 | ProviderID | LONG | YES | From Credit. Provider (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 11 | OriginalProviderID | LONG | YES | From Credit. Original provider (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 12 | RealProviderID | LONG | YES | From Credit. Execution entity (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 13 | CountryID | LONG | YES | From Credit. Customer country (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 14 | FunnelID | INT | YES | From RegistrationMetaData. Marketing funnel (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 15 | LabelID | INT | YES | Always NULL. Backward compatibility (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 16 | PlayerLevelID | INT | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 17 | Valid | BOOLEAN | YES | From Credit. Commission eligibility (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 18 | OriginalCID | LONG | YES | From RegistrationMetaData. Original customer (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 19 | TrackingDate | TIMESTAMP | YES | From Credit. Tracking entry time (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 20 | IsProcessed | BOOLEAN | YES | From Credit. Processing flag (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 21 | ValidFrom | TIMESTAMP | YES | From RegistrationMetaData. Attribution effective date (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 22 | etr_y | STRING | YES | Source: fiktivo.AffiliateCommission.CreditVW.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 23 | etr_ym | STRING | YES | Source: fiktivo.AffiliateCommission.CreditVW.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 24 | etr_ymd | STRING | YES | Source: fiktivo.AffiliateCommission.CreditVW.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 25 | UpdateDate | TIMESTAMP | YES | Computed: GREATEST(CreditDate, ValidFrom) (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 26 | AdditionalData | STRING | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 27 | CommissionSource | STRING | YES | From Credit. Commission calculation source (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |
| 28 | ProductID | STRING | YES | From Credit. Product identifier (ISA MoneyFarm) (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.AffiliateCommission.CreditVW` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.AffiliateCommission.CreditVW
        │
        ▼
main.bi_db.bronze_fiktivo_affiliatecommission_creditvw   ←── this object
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
| CreditID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| CreditDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| CID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| AffiliateCampaign | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| CreditTypeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| Amount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| IsFirstDeposit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| OriginalCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| TrackingDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| IsProcessed | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| etr_y | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| UpdateDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| AdditionalData | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| CommissionSource | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |
| ProductID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditVW) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 26 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 29/29 | Source: bronze_tier1_inheritance*
