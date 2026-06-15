---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_leads
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_leads
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 25
row_count: null
generated_at: '2026-05-19T12:12:57Z'
upstreams:
- fiktivo.dbo.tblaff_Leads
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_Leads
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_Leads
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

# bronze_fiktivo_dbo_tblaff_leads

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_Leads`). 25 of 25 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_leads` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 25 |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 16 07:40:28 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_Leads` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_Leads`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_Leads`
- 25 of 25 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LeadID | INT | YES | Primary key. Unique identifier for each lead event. NOT FOR REPLICATION. Referenced by tblaff_Leads_Commissions.LeadID via trigger-enforced FK (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 1 | CUSTOMER_ID | STRING | YES | Customer identifier from the trading platform (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 2 | ORDER_DATE | TIMESTAMP | YES | Timestamp when the lead was generated. Clustered index column (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 3 | AffiliateSaleAccepted | BOOLEAN | YES | Attribution flag (legacy name from shared codebase). 1=lead attributed to an affiliate, 0=not attributed (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 4 | IPAddress | STRING | YES | Customer's IP address. Fraud detection and geo-verification (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 5 | Browser | STRING | YES | Customer's user agent string (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 6 | Valid | BOOLEAN | YES | Validation flag. 1=qualified lead, 0=rejected (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 7 | Reason | STRING | YES | Rejection reason when Valid=0 (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 8 | BannerID | INT | YES | Marketing banner. References dbo.tblaff_Banners [done] (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 9 | DaysToConvert | FLOAT | YES | Days between affiliate click and lead generation (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 10 | Optional1 | STRING | YES | Sub-affiliate tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 11 | Optional2 | STRING | YES | Secondary tracking parameter (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 12 | Optional3 | LONG | YES | Original CID or extended tracking ID. Has NC index (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 13 | Real | BOOLEAN | YES | Whether the lead is from a real (funded) or demo account. 1=real, NULL/0=demo or unknown (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 14 | DownloadID | LONG | YES | App download event ID (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 15 | ProviderID | LONG | YES | Currently attributed affiliate provider (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 16 | OriginalProviderID | LONG | YES | First affiliate that acquired this customer (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 17 | CountryID | LONG | YES | Customer's country. References dbo.tblaff_Country [done] (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 18 | DID | LONG | YES | Download tracking ID (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 19 | FID | LONG | YES | Funnel tracking ID (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 20 | RealProviderID | LONG | YES | Leaf-level provider after IB hierarchy resolution (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 21 | FunnelID | INT | YES | Marketing funnel identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 22 | LabelID | INT | YES | Marketing label/campaign identifier (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 23 | PlayerLevelID | INT | YES | Customer tier at event time (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |
| 24 | ClubID | INT | YES | Customer club membership (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_Leads` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_Leads
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_leads   ←── this object
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
| LeadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| CUSTOMER_ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| ORDER_DATE | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| AffiliateSaleAccepted | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Browser | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Reason | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| DaysToConvert | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Optional1 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Optional2 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Optional3 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| Real | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| DID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| FID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |
| ClubID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Leads) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 25 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 25/25 | Source: bronze_tier1_inheritance*
