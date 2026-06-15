---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 18
row_count: null
generated_at: '2026-05-19T12:12:57Z'
upstreams:
- fiktivo.dbo.tblaff_FirstPositions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_FirstPositions
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_FirstPositions
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 18
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_firstpositions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_FirstPositions`). 18 of 18 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 18 |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 16 07:40:45 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_FirstPositions` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_FirstPositions`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_FirstPositions`
- 18 of 18 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FirstPositionID | INT | YES | Primary key. Unique identifier for each first position event. NOT FOR REPLICATION. Referenced by tblaff_FirstPositions_Commissions via explicit FK (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 1 | ORDER_DATE | TIMESTAMP | YES | Timestamp when the first position was opened (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 2 | GRAND_TOTAL | DOUBLE | YES | Monetary value/size of the first trade (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 3 | AffiliateFirstPositionAccepted | BOOLEAN | YES | Attribution flag. 1=accepted for commission, 0=not attributed (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 4 | Valid | BOOLEAN | YES | Validation flag. 1=valid, 0=rejected (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 5 | BannerID | INT | YES | Marketing banner. References dbo.tblaff_Banners [done] (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 6 | DaysToConvert | FLOAT | YES | Days between affiliate click and first position (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 7 | Optional1 | STRING | YES | Sub-affiliate tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 8 | Optional2 | STRING | YES | Secondary tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 9 | OriginalCID | LONG | YES | Original customer ID. Clustered index column - primary lookup pattern for deduplication (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 10 | DownloadID | LONG | YES | App download event ID (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 11 | ProviderID | LONG | YES | Currently attributed affiliate provider (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 12 | OriginalProviderID | LONG | YES | First affiliate that acquired this customer (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 13 | CountryID | LONG | YES | Customer's country. References dbo.tblaff_Country [done] (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 14 | RealProviderID | LONG | YES | Leaf-level provider after IB hierarchy resolution (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 15 | FunnelID | INT | YES | Marketing funnel identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 16 | LabelID | INT | YES | Marketing label/campaign identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |
| 17 | PlayerLevelID | INT | YES | Customer tier at event time (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_FirstPositions` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_FirstPositions
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions   ←── this object
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
| FirstPositionID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| ORDER_DATE | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| GRAND_TOTAL | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| AffiliateFirstPositionAccepted | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| DaysToConvert | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| Optional1 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| Optional2 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| OriginalCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_FirstPositions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 18 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 18/18 | Source: bronze_tier1_inheritance*
