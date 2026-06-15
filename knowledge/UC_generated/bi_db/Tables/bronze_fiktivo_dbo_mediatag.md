---
object_fqn: main.bi_db.bronze_fiktivo_dbo_mediatag
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_mediatag
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:12:55Z'
upstreams:
- fiktivo.dbo.MediaTag
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md
  source_database: fiktivo
  source_schema: dbo
  source_table: MediaTag
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/MediaTag
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

# bronze_fiktivo_dbo_mediatag

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.MediaTag`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_mediatag` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jun 10 13:16:56 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.MediaTag` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md`.

- Lake path: `Bronze/fiktivo/dbo/MediaTag`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.MediaTag`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TagID | INT | YES | Auto-incrementing identifier. Clustered index key for physical ordering (Tier 1 — inherited from fiktivo.dbo.MediaTag). |
| 1 | TagName | STRING | YES | Primary key. Unique tag identifier used in tracking URLs and campaign attribution (e.g., "summer_2024_banner_a") (Tier 1 — inherited from fiktivo.dbo.MediaTag). |
| 2 | TranslationKey | STRING | YES | Localization key for displaying the tag name in multiple languages in the affiliate portal UI (Tier 1 — inherited from fiktivo.dbo.MediaTag). |
| 3 | Trace | STRING | YES | Computed audit column. JSON with session metadata (HostName, AppName, SUserName, SPID) (Tier 1 — inherited from fiktivo.dbo.MediaTag). |
| 4 | ValidFrom | TIMESTAMP | YES | System-versioning period start. Tracks when this tag definition became active (Tier 1 — inherited from fiktivo.dbo.MediaTag). |
| 5 | ValidTo | TIMESTAMP | YES | System-versioning period end. '9999-12-31' for current rows (Tier 1 — inherited from fiktivo.dbo.MediaTag). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.MediaTag` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.MediaTag
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_mediatag   ←── this object
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
| TagID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |
| TagName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |
| TranslationKey | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |
| Trace | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.MediaTag.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.MediaTag) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
