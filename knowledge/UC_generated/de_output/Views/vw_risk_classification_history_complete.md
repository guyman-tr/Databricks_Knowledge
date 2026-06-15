---
object_fqn: main.de_output.vw_risk_classification_history_complete
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.de_output.vw_risk_classification_history_complete
schema: de_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 96
row_count: null
generated_at: '2026-05-19T14:12:09Z'
upstreams:
- main.de_output.de_output_risk_classification_history
- main.de_output.de_output_risk_classification
writer:
  kind: view_definition
  path: knowledge/UC_generated/de_output/_discovery/source_code/vw_risk_classification_history_complete.sql
  source_code_snapshot: knowledge/UC_generated/de_output/_discovery/source_code/vw_risk_classification_history_complete.sql
concept_count: 0
formula_count: 96
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 96
  unverified_columns: 0
---

# vw_risk_classification_history_complete

> View in `main.de_output`. 0 business concept(s) in §2; 96 of 96 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.vw_risk_classification_history_complete` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | meravhu@etoro.com |
| **Row count** | n/a |
| **Column count** | 96 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Apr 23 11:50:16 UTC 2026 |

---

## 1. Business Meaning

`vw_risk_classification_history_complete` is a view in `main.de_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.de_output.de_output_risk_classification_history` → this object. Canonical upstream documentation: `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 96 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 0 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 96 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.de_output.de_output_risk_classification_history` (and 1 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | BeginTime | TIMESTAMP | YES | Source: `main.de_output.de_output_risk_classification_history.BeginTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 1 | EndTime | TIMESTAMP | YES | Source: `main.de_output.de_output_risk_classification_history.EndTime`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 2 | GCID | INT | YES | Source: `main.de_output.de_output_risk_classification_history.GCID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 3 | CID | INT | YES | Source: `main.de_output.de_output_risk_classification_history.CID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 4 | RegulationID | INT | YES | Source: `main.de_output.de_output_risk_classification_history.RegulationID`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 5 | Regulation | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.Regulation`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 6 | CountryofResidence_Onboarding_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.CountryofResidence_Onboarding_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 7 | CountryofResidence_Onboarding_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.CountryofResidence_Onboarding_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 8 | CountryofResidence_Existingclients_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.CountryofResidence_Existingclients_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 9 | CountryofResidence_Existingclients_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.CountryofResidence_Existingclients_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 10 | Ageofcustomer_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.Ageofcustomer_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 11 | Ageofcustomer_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.Ageofcustomer_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 12 | AgeAlert_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.AgeAlert_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 13 | AgeAlert_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.AgeAlert_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 14 | ScreeningStatus_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.ScreeningStatus_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 15 | ScreeningStatus_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.ScreeningStatus_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 16 | MainSourceofIncome_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.MainSourceofIncome_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 17 | MainSourceofIncome_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.MainSourceofIncome_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 18 | Occupation_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.Occupation_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 19 | Occupation_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.Occupation_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 20 | SpecialScore_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.SpecialScore_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 21 | SpecialScore_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SpecialScore_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 22 | AnnualIncome_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.AnnualIncome_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 23 | AnnualIncome_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.AnnualIncome_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 24 | TotalCashAndLiquidAssets_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.TotalCashAndLiquidAssets_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 25 | TotalCashAndLiquidAssets_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.TotalCashAndLiquidAssets_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 26 | MoneyplanToinvest_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.MoneyplanToinvest_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 27 | MoneyplanToinvest_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.MoneyplanToinvest_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 28 | HighRisk_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.HighRisk_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 29 | HighRisk_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.HighRisk_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 30 | SectorMLTF_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.SectorMLTF_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 31 | SectorMLTF_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SectorMLTF_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 32 | NetDeposit_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.NetDeposit_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 33 | NetDeposit_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.NetDeposit_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 34 | FTD_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.FTD_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 35 | FTD_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.FTD_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 36 | ScoreExpectedOriginFunds_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.ScoreExpectedOriginFunds_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 37 | ScoreExpectedOriginFunds_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.ScoreExpectedOriginFunds_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 38 | ScoreExpectedDestinationPayments_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.ScoreExpectedDestinationPayments_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 39 | ScoreExpectedDestinationPayments_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.ScoreExpectedDestinationPayments_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 40 | SectorHighRisk_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.SectorHighRisk_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 41 | SectorHighRisk_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SectorHighRisk_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 42 | Sector_ML_TF_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.Sector_ML_TF_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 43 | Sector_ML_TF_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.Sector_ML_TF_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 44 | SectorHighCash_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.SectorHighCash_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 45 | SectorHighCash_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SectorHighCash_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 46 | EstablishmentApproved_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.EstablishmentApproved_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 47 | EstablishmentApproved_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.EstablishmentApproved_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 48 | HighPublicProfile_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.HighPublicProfile_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 49 | HighPublicProfile_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.HighPublicProfile_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 50 | DisclosureSubjected_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.DisclosureSubjected_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 51 | DisclosureSubjected_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.DisclosureSubjected_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 52 | RegionSupervised_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.RegionSupervised_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 53 | RegionSupervised_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.RegionSupervised_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 54 | JurisdictionNonCorrupt_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.JurisdictionNonCorrupt_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 55 | JurisdictionNonCorrupt_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.JurisdictionNonCorrupt_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 56 | AML_CFT_Failure_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.AML_CFT_Failure_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 57 | AML_CFT_Failure_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.AML_CFT_Failure_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 58 | BackgroundConsistent_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.BackgroundConsistent_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 59 | BackgroundConsistent_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.BackgroundConsistent_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 60 | TransactionSuspicious_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionSuspicious_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 61 | TransactionSuspicious_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionSuspicious_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 62 | IdentityEvidence_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityEvidence_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 63 | IdentityEvidence_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityEvidence_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 64 | AvoidBusinessRelations_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.AvoidBusinessRelations_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 65 | AvoidBusinessRelations_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.AvoidBusinessRelations_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 66 | OwnershipTransparent_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.OwnershipTransparent_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 67 | OwnershipTransparent_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.OwnershipTransparent_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 68 | AssetHoldingVehicle_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.AssetHoldingVehicle_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 69 | AssetHoldingVehicle_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.AssetHoldingVehicle_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 70 | TransactionsUnusual_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionsUnusual_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 71 | TransactionsUnusual_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionsUnusual_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 72 | SecrecyUnreasonable_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.SecrecyUnreasonable_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 73 | SecrecyUnreasonable_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SecrecyUnreasonable_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 74 | NFTF_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.NFTF_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 75 | NFTF_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.NFTF_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 76 | IdentityDoubts_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityDoubts_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 77 | IdentityDoubts_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityDoubts_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 78 | ExpectedProductsUsed_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.ExpectedProductsUsed_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 79 | ExpectedProductsUsed_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.ExpectedProductsUsed_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 80 | NonProfitOrgAbused_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.NonProfitOrgAbused_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 81 | NonProfitOrgAbused_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.NonProfitOrgAbused_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 82 | CooperativeClient_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.CooperativeClient_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 83 | CooperativeClient_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.CooperativeClient_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 84 | IdentityAnonymous_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityAnonymous_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 85 | IdentityAnonymous_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.IdentityAnonymous_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 86 | TransactionComplexity_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionComplexity_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 87 | TransactionComplexity_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.TransactionComplexity_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 88 | PaymentsThirdParty_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.PaymentsThirdParty_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 89 | PaymentsThirdParty_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.PaymentsThirdParty_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 90 | Finalscore_RiskScore | INT | YES | Source: `main.de_output.de_output_risk_classification_history.Finalscore_RiskScore`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 91 | Finalscore_Value | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.Finalscore_Value`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 92 | RiskScore_Explanation | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.RiskScore_Explanation`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 93 | RiskScoreName | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.RiskScoreName`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 94 | SourceDate | STRING | YES | Source: `main.de_output.de_output_risk_classification_history.SourceDate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |
| 95 | IsLastUpdate | INT | YES | Source: `main.de_output.de_output_risk_classification_history.IsLastUpdate`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.de_output.de_output_risk_classification_history`). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.de_output.de_output_risk_classification_history` | Primary | `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md` |
| `main.de_output.de_output_risk_classification` | JOIN/UNION | `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification.md` |

### 5.2 Pipeline ASCII Diagram

```
main.de_output.de_output_risk_classification_history
main.de_output.de_output_risk_classification
        │
        ▼
main.de_output.vw_risk_classification_history_complete   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=96 runtime=96 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.de_output.de_output_risk_classification_history` (wiki: `knowledge/UC_generated/de_output/<Tables|Views>/de_output_risk_classification_history.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 96 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 96 TN, 0 U | Elements: 96/96 | Source: view_definition*
