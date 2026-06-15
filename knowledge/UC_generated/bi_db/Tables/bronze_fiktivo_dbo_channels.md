---
object_fqn: main.bi_db.bronze_fiktivo_dbo_channels
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_channels
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:12:55Z'
upstreams:
- fiktivo.dbo.Channels
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md
  source_database: fiktivo
  source_schema: dbo
  source_table: Channels
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/Channels
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_channels

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.Channels`). 5 of 5 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_channels` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Aug 14 08:12:47 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.Channels` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md`.

- Lake path: `Bronze/fiktivo/dbo/Channels`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.Channels`
- 5 of 5 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | INT | YES | Primary key. References dbo.tblaff_Affiliates. One channel entry per affiliate (Tier 1 — inherited from fiktivo.dbo.Channels). |
| 1 | AffiliatesGroupsID | INT | YES | The affiliate's group ID. Denormalized from tblaff_Affiliates.AffiliatesGroupsID (Tier 1 — inherited from fiktivo.dbo.Channels). |
| 2 | MarketingExpenseID | LONG | YES | Marketing expense channel ID. Denormalized from tblaff_Affiliates.MarketingExpenseID (Tier 1 — inherited from fiktivo.dbo.Channels). |
| 3 | MarketingExpenseName | STRING | YES | Display name of the marketing expense channel. Denormalized from tblaff_MarketingExpense.MarketingExpenseName (Tier 1 — inherited from fiktivo.dbo.Channels). |
| 4 | AffiliatesGroupsName | STRING | YES | Display name of the affiliate group. Denormalized from tblaff_AffiliatesGroups.AffiliatesGroupsName (Tier 1 — inherited from fiktivo.dbo.Channels). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.Channels` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.Channels
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_channels   ←── this object
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
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.Channels) |
| AffiliatesGroupsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.Channels) |
| MarketingExpenseID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.Channels) |
| MarketingExpenseName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.Channels) |
| AffiliatesGroupsName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.Channels.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.Channels) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 5 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
