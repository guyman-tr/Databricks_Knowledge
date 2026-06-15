---
object_fqn: main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:54Z'
upstreams:
- fiktivo.AffiliateCommission.CreditCommissionVW
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md
  source_database: fiktivo
  source_schema: AffiliateCommission
  source_table: CreditCommissionVW
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/AffiliateCommission/CreditCommissionVW
  copy_strategy: Merge
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

# bronze_fiktivo_affiliatecommission_creditcommissionvw

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.AffiliateCommission.CreditCommissionVW`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 01 08:18:30 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.AffiliateCommission.CreditCommissionVW` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md`.

- Lake path: `Bronze/fiktivo/AffiliateCommission/CreditCommissionVW`
- Copy strategy: `Merge`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `AffiliateCommission.CreditCommissionVW`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreditID | LONG | YES | From Credit. Credit event identifier (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 1 | AffiliateID | INT | YES | From CreditCommission. Earning affiliate (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 2 | Commission | DOUBLE | YES | From CreditCommission. Commission amount (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 3 | Tier | INT | YES | From CreditCommission. Commission tier (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 4 | Paid | BOOLEAN | YES | From CreditCommission. Payment status (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 5 | PaymentID | INT | YES | From CreditCommission. Payment batch (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 6 | AffiliateTypeID | INT | YES | From CreditCommission. Affiliate type classification (PART-2448) (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |
| 7 | UpdateDate | TIMESTAMP | YES | Computed: GREATEST(PaymentDate, CreditDate) when paid (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.AffiliateCommission.CreditCommissionVW` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.AffiliateCommission.CreditCommissionVW
        │
        ▼
main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw   ←── this object
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
| CreditID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| Commission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| Tier | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| Paid | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| PaymentID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| AffiliateTypeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |
| UpdateDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.AffiliateCommission.CreditCommissionVW) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
