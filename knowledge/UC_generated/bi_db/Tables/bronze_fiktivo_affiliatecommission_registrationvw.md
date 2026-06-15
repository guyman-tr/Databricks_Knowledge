---
object_fqn: main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 24
row_count: null
generated_at: '2026-05-19T12:12:55Z'
upstreams:
- fiktivo.AffiliateCommission.RegistrationVW
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md
  source_database: fiktivo
  source_schema: AffiliateCommission
  source_table: RegistrationVW
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/AffiliateCommission/RegistrationVW
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 21
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_fiktivo_affiliatecommission_registrationvw

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.AffiliateCommission.RegistrationVW`). 21 of 24 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 24 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 01 08:19:29 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.AffiliateCommission.RegistrationVW` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md`.

- Lake path: `Bronze/fiktivo/AffiliateCommission/RegistrationVW`
- Copy strategy: `Merge`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `AffiliateCommission.RegistrationVW`
- 21 of 24 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegistrationID | LONG | YES | From Registration. Registration identifier (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 1 | CID | LONG | YES | From RegistrationMetaData. Customer ID (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 2 | OriginalCID | LONG | YES | From RegistrationMetaData. Original customer (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 3 | AffiliateID | INT | YES | From RegistrationMetaData. Referring affiliate (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 4 | AffiliateCampaign | STRING | YES | From RegistrationMetaData. Campaign (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 5 | RegistrationDate | TIMESTAMP | YES | From Registration. Registration timestamp (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 6 | DownloadID | LONG | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 7 | BannerID | INT | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 8 | CountryID | LONG | YES | From Registration. Customer country (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 9 | ProviderID | LONG | YES | From Registration (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 10 | OriginalProviderID | LONG | YES | From Registration (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 11 | RealProviderID | LONG | YES | From Registration (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 12 | FunnelID | INT | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 13 | LabelID | INT | YES | Always NULL (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 14 | PlayerLevelID | INT | YES | From RegistrationMetaData (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 15 | TrackingDate | TIMESTAMP | YES | From Registration. Tracking entry (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 16 | Valid | BOOLEAN | YES | From Registration. Eligibility (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 17 | IsProcessed | BOOLEAN | YES | From Registration. Processing flag (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 18 | ValidFrom | TIMESTAMP | YES | From RegistrationMetaData. Attribution effective (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 19 | etr_y | STRING | YES | Source: fiktivo.AffiliateCommission.RegistrationVW.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | etr_ym | STRING | YES | Source: fiktivo.AffiliateCommission.RegistrationVW.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | etr_ymd | STRING | YES | Source: fiktivo.AffiliateCommission.RegistrationVW.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | UpdateDate | TIMESTAMP | YES | Computed: GREATEST(RegistrationDate, ValidFrom) (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |
| 23 | AdditionalData | STRING | YES | From RegistrationMetaData. Extensible metadata (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.AffiliateCommission.RegistrationVW` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.AffiliateCommission.RegistrationVW
        │
        ▼
main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw   ←── this object
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
| RegistrationID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| CID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| OriginalCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| AffiliateCampaign | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| RegistrationDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| TrackingDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| IsProcessed | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| etr_y | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| UpdateDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |
| AdditionalData | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.RegistrationVW) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 21 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 24/24 | Source: bronze_tier1_inheritance*
