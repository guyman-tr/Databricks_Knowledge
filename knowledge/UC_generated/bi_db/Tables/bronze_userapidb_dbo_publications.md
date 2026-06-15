---
object_fqn: main.bi_db.bronze_userapidb_dbo_publications
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_userapidb_dbo_publications
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:13:03Z'
upstreams:
- UserApiDB.dbo.Publications
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md
  source_database: UserApiDB
  source_schema: dbo
  source_table: Publications
  source_repo: DB_Schema
  datalake_path: Bronze/UserApiDB/dbo/Publications
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_userapidb_dbo_publications

> Bronze ingest in `main.bi_db` (1:1 passthrough of `UserApiDB.dbo.Publications`). 9 of 9 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_userapidb_dbo_publications` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 9 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jul 30 23:37:13 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `UserApiDB.dbo.Publications` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md`.

- Lake path: `Bronze/UserApiDB/dbo/Publications`
- Copy strategy: `Override`
- Source database: `UserApiDB` (`DB_Schema`)
- Source schema/table: `dbo.Publications`
- 9 of 9 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Primary key. Legacy Customer ID (not GCID). One publication record per user (Tier 2 — inherited from UserApiDB.dbo.Publications). |
| 1 | Sticky | STRING | YES | User's pinned/sticky message shown at top of their profile feed (Tier 3 — inherited from UserApiDB.dbo.Publications). |
| 2 | AboutMe | STRING | YES | User's "About Me" bio text displayed on their profile page (Tier 3 — inherited from UserApiDB.dbo.Publications). |
| 3 | LanguageCode | STRING | YES | Language code for the publication content (Tier 3 — inherited from UserApiDB.dbo.Publications). |
| 4 | StrategyID | INT | YES | User's declared trading strategy. Implicit FK to Dictionary.Strategies. See [Strategies](_glossary.md#strategies) (Tier 1 — inherited from UserApiDB.dbo.Publications). |
| 5 | Trace | STRING | YES | Computed: JSON object with HostName, AppName, SUserName, SPID, DBName, ObjectName. For audit trail (Tier 1 — inherited from UserApiDB.dbo.Publications). |
| 6 | ValidFrom | TIMESTAMP | YES | System versioning row start (GENERATED ALWAYS AS ROW START) (Tier 1 — inherited from UserApiDB.dbo.Publications). |
| 7 | ValidTo | TIMESTAMP | YES | System versioning row end (GENERATED ALWAYS AS ROW END) (Tier 1 — inherited from UserApiDB.dbo.Publications). |
| 8 | AboutMeShort | STRING | YES | Shortened version of AboutMe for preview/thumbnail display (Tier 1 — inherited from UserApiDB.dbo.Publications). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `UserApiDB.dbo.Publications` | Primary | `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` |

### 4.2 Pipeline ASCII Diagram

```
UserApiDB.dbo.Publications
        │
        ▼
main.bi_db.bronze_userapidb_dbo_publications   ←── this object
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
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| Sticky | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| AboutMe | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| LanguageCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| StrategyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| Trace | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |
| AboutMeShort | upstream wiki `knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/dbo/Tables/dbo.Publications.md` (bronze passthrough) | 1 | (Tier 1 — inherited from UserApiDB.dbo.Publications) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: bronze_tier1_inheritance*
