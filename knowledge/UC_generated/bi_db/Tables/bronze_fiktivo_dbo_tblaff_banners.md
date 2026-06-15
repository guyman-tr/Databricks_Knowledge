---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_banners
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_banners
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:12:56Z'
upstreams:
- fiktivo.dbo.tblaff_Banners
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_Banners
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_Banners
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 21
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_banners

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_Banners`). 21 of 21 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_banners` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 21 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 15 05:15:25 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_Banners` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_Banners`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_Banners`
- 21 of 21 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | BannerID | INT | YES | Primary key. Referenced by tblaff_GroupBanners, tblaff_MediaTagBanner, and commission event tables (tblaff_Sales.BannerID, etc.) for conversion attribution (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 1 | CategoryID | INT | YES | References [dbo.tblaff_Categories](dbo.tblaff_Categories.md).CategoryID. Content category of the banner (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 2 | Type | INT | YES | References [dbo.tblaff_BannerTypes](dbo.tblaff_BannerTypes.md).BannerTypeID. Media format: 1=GIF, 2=Flash, 3=Text, 4=Rotating, 5=Links, 6=Widgets, 7=Videos, 8=Articles, 9=White Labels, 10=Mailers, 11=Education, 12=Logos (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 3 | BannerName | STRING | YES | Display name of the banner asset for admin and affiliate portal listing (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 4 | ImageURL | STRING | YES | URL to the banner image/asset file. For GIF/Flash banners, points to the creative file (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 5 | TargetURL | STRING | YES | Click-through URL. Where users are directed when they click the banner. Typically includes tracking parameters (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 6 | AltText | STRING | YES | HTML alt text for the banner image. Used for accessibility and SEO (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 7 | Width | INT | YES | Banner width in pixels. Standard IAB sizes (728, 300, 160, etc.). 0 = variable/responsive (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 8 | Height | INT | YES | Banner height in pixels. 0 = variable/responsive (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 9 | PerSale | BOOLEAN | YES | Banner optimized for sale/deposit conversion tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 10 | PerLead | BOOLEAN | YES | Banner optimized for lead generation tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 11 | PerClick | BOOLEAN | YES | Banner optimized for click-based tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 12 | NotesToAffiliate | STRING | YES | Instructions or notes for affiliates about how to best use this banner (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 13 | AdvancedBanner | BOOLEAN | YES | Whether this banner uses advanced/custom HTML instead of a standard image. 1 = custom AdCode content (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 14 | AdCode | STRING | YES | Custom HTML/JavaScript ad code for advanced banners (AdvancedBanner=1). Affiliates paste this code directly into their sites (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 15 | TargetWindow | STRING | YES | HTML target window for the click-through link (e.g., "_blank", "_self", "_top") (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 16 | LanguageID | INT | YES | References [dbo.tblaff_Languages](dbo.tblaff_Languages.md).LanguageID. Locale of the banner content. Default 1 (English) (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 17 | BrandID | INT | YES | References [dbo.tblaff_Brands](dbo.tblaff_Brands.md).BrandID. Brand/entity for regulatory targeting (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 18 | Priority | INT | YES | Display priority/sort order for banners within the same category. Lower values may appear first (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 19 | IsArchived | BOOLEAN | YES | Archive flag. 1 = hidden from affiliate selection. 0 = active (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |
| 20 | Trace | STRING | YES | Computed audit column. JSON with session metadata (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_Banners` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_Banners
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_banners   ←── this object
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
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| CategoryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| Type | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| BannerName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| ImageURL | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| TargetURL | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| AltText | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| Width | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| Height | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| PerSale | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| PerLead | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| PerClick | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| NotesToAffiliate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| AdvancedBanner | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| AdCode | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| TargetWindow | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| LanguageID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| BrandID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| Priority | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| IsArchived | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |
| Trace | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Banners.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Banners) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 21 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: bronze_tier1_inheritance*
