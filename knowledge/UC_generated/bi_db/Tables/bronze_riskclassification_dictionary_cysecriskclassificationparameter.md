---
object_fqn: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T12:13:01Z'
upstreams:
- RiskClassification.Dictionary.CySecRiskClassificationParameter
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md
  source_database: RiskClassification
  source_schema: Dictionary
  source_table: CySecRiskClassificationParameter
  source_repo: ComplianceDBs
  datalake_path: Bronze/RiskClassification/Dictionary/CySecRiskClassificationParameter
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 2
  unverified_columns: 0
---

# bronze_riskclassification_dictionary_cysecriskclassificationparameter

> Bronze ingest in `main.bi_db` (1:1 passthrough of `RiskClassification.Dictionary.CySecRiskClassificationParameter`). 4 of 6 columns inherited from Tier 1 source wiki; 2 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 6 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 01 11:39:27 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `RiskClassification.Dictionary.CySecRiskClassificationParameter` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md`.

- Lake path: `Bronze/RiskClassification/Dictionary/CySecRiskClassificationParameter`
- Copy strategy: `Override`
- Source database: `RiskClassification` (`ComplianceDBs`)
- Source schema/table: `Dictionary.CySecRiskClassificationParameter`
- 4 of 6 columns inherited; 2 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ParameterID | INT | YES | Parameter identifier. PK. Same ID space as Dictionary.RiskClassificationParameter (2-21, 1001-1025, 9999). FK target for RiskClassification.CySecRiskClassificationParameter (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter). |
| 1 | Name | STRING | YES | Parameter name. Identical to Dictionary.RiskClassificationParameter.Name for the same ID (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter). |
| 2 | Description | STRING | YES | Parameter description. Same content as the main dictionary (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter). |
| 3 | Source | STRING | YES | External data source. Same as main dictionary (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter). |
| 4 | WeeklyWeightPercent | DECIMAL | YES | Source: RiskClassification.Dictionary.CySecRiskClassificationParameter.WeeklyWeightPercent. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | OnboardingWeightPercent | DECIMAL | YES | Source: RiskClassification.Dictionary.CySecRiskClassificationParameter.OnboardingWeightPercent. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RiskClassification.Dictionary.CySecRiskClassificationParameter` | Primary | `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` |

### 4.2 Pipeline ASCII Diagram

```
RiskClassification.Dictionary.CySecRiskClassificationParameter
        │
        ▼
main.bi_db.bronze_riskclassification_dictionary_cysecriskclassificationparameter   ←── this object
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
| ParameterID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter) |
| Name | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter) |
| Description | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter) |
| Source | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.Dictionary.CySecRiskClassificationParameter) |
| WeeklyWeightPercent | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` but column `WeeklyWeightPercent` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| OnboardingWeightPercent | would inherit from `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.md` but column `OnboardingWeightPercent` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 2 TN, 0 U | Elements: 6/6 | Source: bronze_tier1_inheritance*
