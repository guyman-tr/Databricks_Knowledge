---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:12:56Z'
upstreams:
- fiktivo.dbo.tblaff_AffiliatesGroups
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_AffiliatesGroups
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_AffiliatesGroups
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

# bronze_fiktivo_dbo_tblaff_affiliatesgroups

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_AffiliatesGroups`). 6 of 6 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jun 09 11:14:55 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_AffiliatesGroups` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_AffiliatesGroups`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_AffiliatesGroups`
- 6 of 6 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliatesGroupsID | INT | YES | Primary key. Referenced by tblaff_Affiliates.AffiliatesGroupsID, tblaff_Country.AffiliatesGroupsID, dbo.Channels.AffiliatesGroupsID, and tblaff_AffiliateGroups_Viewers. ID=1 is the "view all" sentinel (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |
| 1 | AffiliatesGroupsName | STRING | YES | Display name of the group (e.g., "Affiliates", "Media", "SEM"). Shown in admin UI dropdowns, reports, and affiliate portal. MASKED (dynamic data masking) in non-privileged contexts (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |
| 2 | AccountManagerName | STRING | YES | Display name of the assigned account manager. MASKED. Denormalized from tblaff_User for quick display. May be blank if no manager assigned (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |
| 3 | AccountManagerEmail | STRING | YES | Email of the assigned account manager. MASKED. Used in Dynamics CRM sync trigger for group manager change notifications (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |
| 4 | AccountManagerImagePath | STRING | YES | URL/path to the account manager's profile photo. Displayed in the affiliate portal alongside the group contact information (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |
| 5 | ManagerUserID | INT | YES | FK to dbo.tblaff_User.UserID. The admin user responsible for this group. 0 or NULL = no dedicated manager. Used in the Dynamics CRM sync trigger (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_AffiliatesGroups` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_AffiliatesGroups
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups   ←── this object
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
| AffiliatesGroupsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |
| AffiliatesGroupsName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |
| AccountManagerName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |
| AccountManagerEmail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |
| AccountManagerImagePath | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |
| ManagerUserID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_AffiliatesGroups) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 6 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
