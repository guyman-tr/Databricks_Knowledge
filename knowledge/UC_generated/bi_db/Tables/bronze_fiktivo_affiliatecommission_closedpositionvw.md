---
object_fqn: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 28
row_count: null
generated_at: '2026-05-19T12:12:54Z'
upstreams:
- fiktivo.AffiliateCommission.ClosedPositionVW
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md
  source_database: fiktivo
  source_schema: AffiliateCommission
  source_table: ClosedPositionVW
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/AffiliateCommission/ClosedPositionVW
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 25
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_fiktivo_affiliatecommission_closedpositionvw

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.AffiliateCommission.ClosedPositionVW`). 25 of 28 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | unknown |
| **Row count** | n/a |
| **Column count** | 28 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 03 06:57:35 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.AffiliateCommission.ClosedPositionVW` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md`.

- Lake path: `Bronze/fiktivo/AffiliateCommission/ClosedPositionVW`
- Copy strategy: `Merge`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `AffiliateCommission.ClosedPositionVW`
- 25 of 28 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClosedPositionID | LONG | YES | From ClosedPosition. Unique position identifier (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 1 | CommissionDate | TIMESTAMP | YES | From ClosedPosition. When commission was calculated (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 2 | Amount | DECIMAL | YES | From ClosedPosition. Gross commission-eligible amount (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 3 | HedgeCommission | DECIMAL | YES | From ClosedPosition. Hedge commission component (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 4 | CID | LONG | YES | From RegistrationMetaData. Customer ID (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 5 | OriginalCID | LONG | YES | From RegistrationMetaData. Original customer in copy-trading (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 6 | AffiliateID | INT | YES | From RegistrationMetaData. Referring affiliate (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 7 | AffiliateCampaign | STRING | YES | From RegistrationMetaData. Campaign tracking string (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 8 | ProviderID | LONG | YES | From ClosedPosition. Current provider (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 9 | OriginalProviderID | LONG | YES | From ClosedPosition. Original provider (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 10 | RealProviderID | LONG | YES | From ClosedPosition. Execution entity (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 11 | CountryID | LONG | YES | From ClosedPosition. Customer country (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 12 | NetProfit | DOUBLE | YES | From ClosedPosition. Position profit/loss (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 13 | FunnelID | INT | YES | From RegistrationMetaData. Marketing funnel (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 14 | LabelID | INT | YES | Always NULL. Column preserved for backward compatibility with legacy consumers (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 15 | PlayerLevelID | INT | YES | From RegistrationMetaData. Player level classification (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 16 | DownloadID | LONG | YES | From RegistrationMetaData. Download tracking (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 17 | LotCount | DECIMAL | YES | From ClosedPosition. Position size in lots (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 18 | BannerID | INT | YES | From RegistrationMetaData. Banner reference (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 19 | Valid | BOOLEAN | YES | From ClosedPosition. Commission eligibility (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 20 | TrackingDate | TIMESTAMP | YES | From ClosedPosition. Tracking system entry time (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 21 | IsProcessed | BOOLEAN | YES | From ClosedPosition. Processing completion flag (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 22 | ValidFrom | TIMESTAMP | YES | From RegistrationMetaData. When current attribution became effective (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 23 | etr_y | STRING | YES | Source: fiktivo.AffiliateCommission.ClosedPositionVW.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 24 | etr_ym | STRING | YES | Source: fiktivo.AffiliateCommission.ClosedPositionVW.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 25 | etr_ymd | STRING | YES | Source: fiktivo.AffiliateCommission.ClosedPositionVW.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 26 | UpdateDate | TIMESTAMP | YES | Computed: GREATEST(CommissionDate, ValidFrom). Latest change timestamp for CDC consumers (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |
| 27 | AdditionalData | STRING | YES | From RegistrationMetaData. Extensible metadata (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.AffiliateCommission.ClosedPositionVW` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.AffiliateCommission.ClosedPositionVW
        │
        ▼
main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw   ←── this object
        │
        ▼
main.bi_output.bi_output_marketing_affiliate_payments_report_closed_position
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
| ClosedPositionID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| CommissionDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| Amount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| HedgeCommission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| CID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| OriginalCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| AffiliateCampaign | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| ProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| OriginalProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| RealProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| NetProfit | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| LabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| DownloadID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| LotCount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| BannerID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| Valid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| TrackingDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| IsProcessed | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| etr_y | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| UpdateDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |
| AdditionalData | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionVW) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 25 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 28/28 | Source: bronze_tier1_inheritance*
