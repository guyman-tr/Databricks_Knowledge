---
object_fqn: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:13:01Z'
upstreams:
- RiskClassification.RiskClassification.CySecRiskClassificationParameter
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md
  source_database: RiskClassification
  source_schema: RiskClassification
  source_table: CySecRiskClassificationParameter
  source_repo: ComplianceDBs
  datalake_path: Bronze/RiskClassification/RiskClassification/CySecRiskClassificationParameter
  copy_strategy: Override
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

# bronze_riskclassification_riskclassification_cysecriskclassificationparameter

> Bronze ingest in `main.bi_db` (1:1 passthrough of `RiskClassification.RiskClassification.CySecRiskClassificationParameter`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Mar 01 11:39:49 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `RiskClassification.RiskClassification.CySecRiskClassificationParameter` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md`.

- Lake path: `Bronze/RiskClassification/RiskClassification/CySecRiskClassificationParameter`
- Copy strategy: `Override`
- Source database: `RiskClassification` (`ComplianceDBs`)
- Source schema/table: `RiskClassification.CySecRiskClassificationParameter`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegulationID | INT | YES | Regulation this rule applies to. Part of composite PK. Currently CySEC-focused. See [Regulation](../_glossary.md#regulation) (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 1 | ParameterID | INT | YES | Risk parameter being configured. Part of composite PK. FK to Dictionary.CySecRiskClassificationParameter. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter) (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 2 | ID | INT | YES | Option/row ID within the parameter+regulation combination. Part of composite PK. 0 = default/fallback rule, 1+ = specific matching rules (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 3 | Value | STRING | YES | Input value matching criteria. NULL for default rules. Contains country tier codes ("0","1","2,3"), screening status codes, or other matching patterns. Comma-separated values match any of the listed values (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 4 | RiskClassificationID | INT | YES | Resulting risk score when this rule matches. 0=Low, 50=Medium, 100=High. Looked up in Dictionary.RiskClassificationRegulation for named level (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 5 | ValidationText | STRING | YES | Human-readable description of the rule. "Default" for fallback rules, NULL for specific matching rules. May also contain descriptions like "Sanction Match\Risk Match" (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 6 | BeginTime | TIMESTAMP | YES | Temporal row start. GENERATED ALWAYS AS ROW START (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |
| 7 | EndTime | TIMESTAMP | YES | Temporal row end. GENERATED ALWAYS AS ROW END (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RiskClassification.RiskClassification.CySecRiskClassificationParameter` | Primary | `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` |

### 4.2 Pipeline ASCII Diagram

```
RiskClassification.RiskClassification.CySecRiskClassificationParameter
        │
        ▼
main.bi_db.bronze_riskclassification_riskclassification_cysecriskclassificationparameter   ←── this object
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
| RegulationID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| ParameterID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| ID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| Value | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| RiskClassificationID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| ValidationText | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| BeginTime | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |
| EndTime | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/RiskClassification/Wiki/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RiskClassification.RiskClassification.CySecRiskClassificationParameter) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
