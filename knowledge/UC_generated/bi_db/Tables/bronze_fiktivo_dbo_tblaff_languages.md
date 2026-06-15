---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_languages
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_languages
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:57Z'
upstreams:
- fiktivo.dbo.tblaff_Languages
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_Languages
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_Languages
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_languages

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_Languages`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_languages` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 15 05:15:56 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_Languages` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_Languages`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_Languages`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LanguageID | INT | YES | Primary key. Auto-incrementing identifier for each language entry. Referenced by tblaff_Groups.LanguageID, tblaff_Banners.LanguageID, and tblaff_Affiliates.CommunicationLangID (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 1 | LanguageName | STRING | YES | English name of the language (e.g., "English", "Spanish", "German"). Used in admin UI dropdowns and reports (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 2 | IsCommunicationLanguage | BOOLEAN | YES | Whether this language is available for affiliate email communications. 1 = can be selected as an affiliate's communication preference (104 entries). 0 = used only for banner/landing page targeting (951 entries) (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 3 | LanguageNaturalName | STRING | YES | Native-script name of the language (e.g., "Deutsch", "Francais", "Arabic script"). Displayed in locale selectors. NULL/blank for languages with limited support (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 4 | TLDURL | STRING | YES | Base top-level domain URL for this locale. Routes affiliate tracking links to the correct regional site (e.g., etoro.it for Italian, etoro.fr for French). Defaults to main etoro.com domain (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 5 | DefaultLandingPage | STRING | YES | Custom landing page URL for affiliate traffic in this language. When set, overrides the TLDURL for campaign-specific routing (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 6 | TierTwoLandingPage | STRING | YES | Alternate landing page URL for tier-2 (sub-affiliate) traffic. Allows different conversion funnels for direct vs sub-affiliate traffic (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |
| 7 | Code | STRING | YES | BCP 47/IETF language tag (e.g., "en-gb", "es-es", "zh-cn"). Used for locale matching in tracking URLs and API integrations. Unique constraint ensures no duplicate locale codes (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_Languages` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_Languages
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_languages   ←── this object
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
| LanguageID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| LanguageName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| IsCommunicationLanguage | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| LanguageNaturalName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| TLDURL | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| DefaultLandingPage | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| TierTwoLandingPage | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |
| Code | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Languages.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Languages) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
