---
object_fqn: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:13:02Z'
upstreams:
- USABroker.apex.SketchInvestigationDoNotAppealReason
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md
  source_database: USABroker
  source_schema: apex
  source_table: SketchInvestigationDoNotAppealReason
  source_repo: ComplianceDBs
  datalake_path: Bronze/USABroker/apex/SketchInvestigationDoNotAppealReason
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

# bronze_usabroker_apex_sketchinvestigationdonotappealreason

> Bronze ingest in `main.bi_db` (1:1 passthrough of `USABroker.apex.SketchInvestigationDoNotAppealReason`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 30 08:51:03 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `USABroker.apex.SketchInvestigationDoNotAppealReason` (`ComplianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md`.

- Lake path: `Bronze/USABroker/apex/SketchInvestigationDoNotAppealReason`
- Copy strategy: `Override`
- Source database: `USABroker` (`ComplianceDBs`)
- Source schema/table: `apex.SketchInvestigationDoNotAppealReason`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Auto-incrementing surrogate primary key. ~42K records to date (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 1 | GCID | INT | YES | Global Customer ID of the customer whose investigation produced this do-not-appeal reason (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 2 | ApexID | STRING | YES | The customer's Apex Clearing account ID. Stored here for direct reference without needing to JOIN to ApexData (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 3 | SketchID | STRING | YES | GUID of the Sketch investigation that produced this reason. Multiple reasons can share the same SketchID when the investigation returned multiple blockers (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 4 | ReasonTypeID | INT | YES | Category of the investigation reason. FK to Dictionary.SketchInvestigationReasonType: 0=None, 1=Indeterminate (inconclusive), 2=Reject (definitive failure). See [Sketch Investigation Reason Type](_glossary.md#sketch-investigation-reason-type). All observed data shows ReasonTypeID=2 (Reject). (Dictionary.SketchInvestigationReasonType) (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 5 | ReasonConstant | STRING | YES | Machine-readable constant identifying the specific reason. Maps to constants in the Sketch/Equifax API. Examples: SSN_FRAUD_VICTIM, DOB_NO_SSN_RELATION_FOUND, ADDRESS_NOT_VERIFIED, ADDRESS_NONRESIDENTIAL. Used for programmatic handling and matching against Apex.SketchInvestigationReason configuration (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 6 | SketchDataSource | STRING | YES | The data bureau that provided this verification result. Observed value: "Equifax". Identifies which third-party data source flagged the issue (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |
| 7 | ReasonDescription | STRING | YES | Human-readable description of the verification failure. Examples: "Applicant profile contains a fraud victim warning", "SSN could not be verified to the date of birth provided". NULL is allowed but typically populated from the Sketch API response (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `USABroker.apex.SketchInvestigationDoNotAppealReason` | Primary | `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` |

### 4.2 Pipeline ASCII Diagram

```
USABroker.apex.SketchInvestigationDoNotAppealReason
        │
        ▼
main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| GCID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| ApexID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| SketchID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| ReasonTypeID | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| ReasonConstant | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| SketchDataSource | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |
| ReasonDescription | upstream wiki `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.SketchInvestigationDoNotAppealReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from USABroker.apex.SketchInvestigationDoNotAppealReason) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
