---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 25
row_count: null
generated_at: '2026-05-19T12:12:57Z'
upstreams:
- fiktivo.dbo.tblaff_eCost
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_eCost
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_eCost
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 25
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_ecost

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_eCost`). 25 of 25 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_ecost` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 25 |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 16 07:40:03 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_eCost` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_eCost`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_eCost`
- 25 of 25 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | eCostID | INT | YES | Primary key. Unique identifier for each eCost event. NOT FOR REPLICATION. Referenced by tblaff_eCost_Commissions.eCostID via trigger-enforced FK (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 1 | CUSTOMER_ID | STRING | YES | Customer identifier from the trading platform (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 2 | ORDER_DATE | TIMESTAMP | YES | Timestamp of the eCost event. Clustered index column (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 3 | AffiliateeCostAccepted | BOOLEAN | YES | Attribution flag. 1=accepted for commission, 0=not attributed (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 4 | IPAddress | STRING | YES | Customer's IP address (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 5 | Browser | STRING | YES | Customer's user agent (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 6 | Valid | BOOLEAN | YES | Validation flag. 1=valid for commission, 0=rejected (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 7 | Reason | STRING | YES | Rejection reason when Valid=0 (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 8 | BannerID | INT | YES | Marketing banner. References dbo.tblaff_Banners [done] (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 9 | DaysToConvert | FLOAT | YES | Days between affiliate click and this event (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 10 | Optional1 | STRING | YES | Sub-affiliate tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 11 | Optional2 | STRING | YES | Secondary tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 12 | Optional3 | LONG | YES | Original CID or extended tracking ID (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 13 | Real | BOOLEAN | YES | Whether from a real (funded) or demo account. 1=real, NULL/0=demo (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 14 | DownloadID | LONG | YES | App download event ID (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 15 | ProviderID | LONG | YES | Currently attributed affiliate provider (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 16 | OriginalProviderID | LONG | YES | First affiliate that acquired this customer (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 17 | CountryID | LONG | YES | Customer's country. References dbo.tblaff_Country [done]. Nullable unlike other event tables (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 18 | DID | LONG | YES | Download tracking ID (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 19 | FID | LONG | YES | Funnel tracking ID (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 20 | RealProviderID | LONG | YES | Leaf-level provider after IB hierarchy resolution (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 21 | Comment | STRING | YES | Free-text comment about this specific expense event. Used for line-item annotations (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 22 | eCostHistoryID | INT | YES | Parent eCost agreement. References dbo.tblaff_eCostHistory.eCostHistoryID. 0=no agreement linkage (ad-hoc) (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 23 | FunnelID | INT | YES | Marketing funnel identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |
| 24 | LabelID | INT | YES | Marketing label/campaign identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_eCost` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_eCost
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_ecost   ←── this object
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
| eCostID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| CUSTOMER_ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| ORDER_DATE | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| AffiliateeCostAccepted | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Browser | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Reason | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| DaysToConvert | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Optional1 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Optional2 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Optional3 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Real | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| DID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| FID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| Comment | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| eCostHistoryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_eCost) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 25 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 25/25 | Source: bronze_tier1_inheritance*
