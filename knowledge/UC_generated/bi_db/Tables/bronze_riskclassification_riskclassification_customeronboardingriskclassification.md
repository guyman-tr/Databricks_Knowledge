---
object_fqn: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 5
row_count: null
generated_at: '2026-05-19T12:13:01Z'
upstreams:
- RiskClassification.RiskClassification.CustomerOnboardingRiskClassification
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md
  source_database: RiskClassification
  source_schema: RiskClassification
  source_table: CustomerOnboardingRiskClassification
  source_repo: ComplianceDBs
  datalake_path: Bronze/RiskClassification/RiskClassification/CustomerOnboardingRiskClassification
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 1
  unverified_columns: 0
---

# bronze_riskclassification_riskclassification_customeronboardingriskclassification

> Bronze ingest in `main.bi_db` (1:1 passthrough of `RiskClassification.RiskClassification.CustomerOnboardingRiskClassification`). 4 of 5 columns inherited from Tier 1 source wiki; 1 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 5 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Feb 11 10:31:36 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `RiskClassification.RiskClassification.CustomerOnboardingRiskClassification` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md`.

- Lake path: `Bronze/RiskClassification/RiskClassification/CustomerOnboardingRiskClassification`
- Copy strategy: `Override`
- Source database: `RiskClassification` (`ComplianceDBs`)
- Source schema/table: `RiskClassification.CustomerOnboardingRiskClassification`
- 4 of 5 columns inherited; 1 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Global Customer ID. PK. One row per customer who has completed the onboarding risk assessment. Same customer identifier used across all eToro systems (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification). |
| 1 | Score | DECIMAL | YES | Weighted composite onboarding risk score. Continuous decimal value representing the sum of all parameter WeightedScores. Higher values indicate higher risk. Common values: 4.5-5.0 (low), 10.0-11.5 (medium), 13.0-14.5 (elevated). Not on the 0/50/100 scale of the legacy dbo.T_RiskClassification system (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification). |
| 2 | LastUpdate | TIMESTAMP | YES | Timestamp of the most recent score calculation. Set to CURRENT_TIMESTAMP on both INSERT and UPDATE by the Upsert procedure. Actively updated - recent records from today (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification). |
| 3 | Data | STRING | YES | Complete JSON scoring breakdown. Contains a "Contributions" object with nested objects per parameter (CountryOfResidenceRank, PlaceOfBirthRank, CountryOfCitizenshipRank, etc.), each with Answer (input value), Score (parameter score), Weight (decimal weight), and WeightedScore (Score * Weight). Added via ALTER TABLE after initial table creation - a later enhancement to provide full scoring transparency (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification). |
| 4 | ReasonID | INT | YES | Source: RiskClassification.RiskClassification.CustomerOnboardingRiskClassification.ReasonID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RiskClassification.RiskClassification.CustomerOnboardingRiskClassification` | Primary | `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` |

### 4.2 Pipeline ASCII Diagram

```
RiskClassification.RiskClassification.CustomerOnboardingRiskClassification
        │
        ▼
main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification   ←── this object
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
| GCID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification) |
| Score | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification) |
| LastUpdate | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification) |
| Data | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CustomerOnboardingRiskClassification) |
| ReasonID | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CustomerOnboardingRiskClassification.md` but column `ReasonID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 1 TN, 0 U | Elements: 5/5 | Source: bronze_tier1_inheritance*
