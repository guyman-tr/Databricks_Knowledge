# Review Needed: BI_DB_dbo.BI_DB_RiskClassification

## Summary

All 103 columns are Tier 3 (no upstream wiki, no Synapse writer SP code). This table has the highest review priority of any BI_DB object due to complete lack of documented upstream sources.

## 1. Dormant Table — Pipeline Status Verification Required

- **Issue**: All rows have `UpdateDate = 2024-06-02 01:39:57.930`. The Generic Pipeline is configured for weekly Override refresh from `RiskClassification.dbo.V_RiskClassificationDataLake`, but no new data has appeared since June 2024.
- **Action**: Verify with the BI_DB team whether this pipeline is still active or has been decommissioned. Check the Generic Pipeline logs for job ID 869.

## 2. No Writer SP — External Load Pattern

- **Issue**: No Synapse stored procedure writes to this table. Depth=0 in the dependency graph. The data is loaded directly from the production RiskClassification microservice database via Generic Pipeline.
- **Action**: This means column-level lineage cannot be verified via SP code. All column mappings are assumed passthrough based on naming alignment with the source view.

## 3. Duplicate Risk Factor Columns — Regulation-Specific Variants

- **Issue**: Several risk factors appear with two naming conventions:
  - `Sector ML TF` (spaces) vs `Sector_ML_TF` (underscores)
  - `Sector High Cash` (spaces) vs `SectorHighCash` (underscores)
  - `SectorHighRisk` (underscore, no space equivalent)
- **Action**: Confirm with the compliance/risk team whether these are regulation-specific variants (e.g., CySEC vs ASIC versions of the same factor) or legacy/deprecated duplicates.

## 4. Production Source Wiki Needed

- **Issue**: The `RiskClassification` database on `risk-fg-RiskClassification` has no wiki in any upstream repo. The `_no_upstream_found.txt` marker is present. Without this, all 103 columns remain Tier 3.
- **Action**: If a wiki or data dictionary exists for the RiskClassification microservice, adding it to the upstream wiki routing would elevate all columns to Tier 1.

## 5. Related Table — BI_DB_RiskClassification_Scores

- **Issue**: A companion table `BI_DB_dbo.BI_DB_RiskClassification_Scores` exists with a normalized structure (RiskClassificationParameterID, RiskClassificationParameter, Value). This appears to be a normalized version of the same data that this table stores in wide/pivoted format.
- **Action**: Document the relationship between these two tables and whether one is preferred over the other for downstream consumption.

## 6. Migration History

- **Issue**: Migration scripts found from September 2024 (`BI_DB_Migration.BI_DB_RiskClassification`). The migration table used underscored column names (e.g., `Country_of_Residence_Onboarding_RiskScore`) while the current table uses spaces and commas (e.g., `Country of Residence, Onboarding_RiskScore`). This suggests a schema redesign during migration.
- **Action**: No immediate action needed, but worth noting that column names changed during migration.

## 7. PII Sensitivity

- **Issue**: This table contains compliance-sensitive risk classification data that could be considered PII-adjacent (risk scores per customer, PEP screening results, occupation, income ranges, country of residence). While not directly PII, the combination of CID + risk factors could identify individuals.
- **Action**: Confirm appropriate access controls and PII tagging requirements for UC export.

---

*Generated: 2026-04-30 | Reviewer: Compliance/Risk team + BI_DB pipeline owner*
