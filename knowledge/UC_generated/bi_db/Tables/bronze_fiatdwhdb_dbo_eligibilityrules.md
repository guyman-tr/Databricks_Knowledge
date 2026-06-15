---
object_fqn: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T12:12:51Z'
upstreams:
- FiatDwhDB.dbo.EligibilityRules
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md
  source_database: FiatDwhDB
  source_schema: dbo
  source_table: EligibilityRules
  source_repo: BankingDBs
  datalake_path: Bronze/FiatDwhDB/dbo/EligibilityRules
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiatdwhdb_dbo_eligibilityrules

> Bronze ingest in `main.bi_db` (1:1 passthrough of `FiatDwhDB.dbo.EligibilityRules`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 06 20:16:51 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `FiatDwhDB.dbo.EligibilityRules` (`BankingDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md`.

- Lake path: `Bronze/FiatDwhDB/dbo/EligibilityRules`
- Copy strategy: `Override`
- Source database: `FiatDwhDB` (`BankingDBs`)
- Source schema/table: `dbo.EligibilityRules`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Auto-incrementing surrogate primary key (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 1 | FiatId | INT | YES | Fiat platform instance identifier. Groups rules by deployment context (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 2 | DesignatedRegulationId | INT | YES | Target regulatory jurisdiction. Determines which regulatory framework governs the sub-program for this rule (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 3 | CountryId | INT | YES | Country filter for the rule. Only customers in this country match. References an external country ID system (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 4 | ClubId | INT | YES | eToro club tier filter. Restricts eligibility to customers at a specific club/loyalty level (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 5 | SubProgramId | INT | YES | Target sub-program that eligible customers can access. FK to dbo.SubPrograms: 1=Card Premium UK, 2=Card Standard UK, ..., 16=IBAN Black DKK. See [Sub-Program](../../_glossary.md#sub-program) (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 6 | RolloutPercentage | DECIMAL | YES | Percentage of matching customers to enroll (0.0-100.0). Enables gradual rollout of new sub-programs. 100.0 = fully available (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 7 | RegulationId | INT | YES | Source regulatory jurisdiction of the customer. Used to match customers by their current regulation (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 8 | UpdateTime | TIMESTAMP | YES | Timestamp when this rule was last configured/deployed (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 9 | LastTimeOverride | TIMESTAMP | YES | Timestamp of the most recent bulk refresh/override of this rule. Updated when AddEligibilityRules runs (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |
| 10 | Priority | INT | YES | Priority rank for rule evaluation. When multiple rules match, lowest number wins. Default 0 (highest priority) (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `FiatDwhDB.dbo.EligibilityRules` | Primary | `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` |

### 4.2 Pipeline ASCII Diagram

```
FiatDwhDB.dbo.EligibilityRules
        │
        ▼
main.bi_db.bronze_fiatdwhdb_dbo_eligibilityrules   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| FiatId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| DesignatedRegulationId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| CountryId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| ClubId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| SubProgramId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| RolloutPercentage | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| RegulationId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| UpdateTime | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| LastTimeOverride | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |
| Priority | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.EligibilityRules.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.EligibilityRules) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
