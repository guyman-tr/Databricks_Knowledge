---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:12:58Z'
upstreams:
- fiktivo.dbo.tblaff_Leads_Commissions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_Leads_Commissions
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_Leads_Commissions
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

# bronze_fiktivo_dbo_tblaff_leads_commissions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_Leads_Commissions`). 9 of 9 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 9 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 04:17:13 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_Leads_Commissions` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_Leads_Commissions`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_Leads_Commissions`
- 9 of 9 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Auto-incrementing primary key. NOT FOR REPLICATION (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 1 | LeadID | INT | YES | References tblaff_Leads.LeadID. Trigger enforces RI (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 2 | AffiliateID | INT | YES | The affiliate receiving this commission. Trigger enforces RI against tblaff_Affiliates (Tier 2 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 3 | Commission | DOUBLE | YES | Lead commission amount for this tier (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 4 | Tier | INT | YES | Commission tier level: 1-5 (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 5 | Paid | BOOLEAN | YES | Payment status: 0 = unpaid, 1 = paid (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 6 | PaymentID | INT | YES | References tblaff_PaymentHistory.PaymentID when paid (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 7 | SubAffiliateID | STRING | YES | Sub-affiliate tracking tag. Updatable by UpdateSubAffiliateID (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |
| 8 | eCost | DOUBLE | YES | Effective cost to the platform for this lead event. Enables ROI calculation: Commission/eCost. NULL when eCost tracking is not configured (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_Leads_Commissions` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_Leads_Commissions
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| LeadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| Commission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| Tier | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| Paid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| PaymentID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| SubAffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |
| eCost | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads_Commissions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: bronze_tier1_inheritance*
