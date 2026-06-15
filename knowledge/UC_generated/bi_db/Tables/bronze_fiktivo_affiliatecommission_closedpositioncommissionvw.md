---
object_fqn: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:53Z'
upstreams:
- fiktivo.AffiliateCommission.ClosedPositionCommissionVW
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md
  source_database: fiktivo
  source_schema: AffiliateCommission
  source_table: ClosedPositionCommissionVW
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/AffiliateCommission/ClosedPositionCommissionVW
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_affiliatecommission_closedpositioncommissionvw

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.AffiliateCommission.ClosedPositionCommissionVW`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | unknown |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 03 07:00:45 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.AffiliateCommission.ClosedPositionCommissionVW` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md`.

- Lake path: `Bronze/fiktivo/AffiliateCommission/ClosedPositionCommissionVW`
- Copy strategy: `Merge`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `AffiliateCommission.ClosedPositionCommissionVW`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClosedPositionID | LONG | YES | From ClosedPosition. Position identifier (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 1 | AffiliateID | INT | YES | From ClosedPositionCommission. Earning affiliate (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 2 | Commission | DOUBLE | YES | From ClosedPositionCommission. Commission amount (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 3 | Tier | INT | YES | From ClosedPositionCommission. Commission tier (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 4 | Paid | BOOLEAN | YES | From ClosedPositionCommission. Payment status (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 5 | PaymentID | INT | YES | From ClosedPositionCommission. Payment batch (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |
| 6 | UpdateDate | TIMESTAMP | YES | Computed: GREATEST(PaymentDate, CommissionDate) when paid; CommissionDate when unpaid. For CDC watermarks (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.AffiliateCommission.ClosedPositionCommissionVW` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.AffiliateCommission.ClosedPositionCommissionVW
        │
        ▼
main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw   ←── this object
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
| ClosedPositionID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| Commission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| Tier | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| Paid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| PaymentID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |
| UpdateDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.ClosedPositionCommissionVW) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
