# DWH_dbo.Dim_Campaign -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. Column descriptions are Tier 1 (from upstream BackOffice.Campaign wiki) for the intended design, Tier 2 for ETL-computed columns. However, all Tier 1 descriptions apply only to the intended design -- no actual campaign data exists in DWH.

## Columns Needing Clarification

| Column | Issue |
|--------|-------|
| ParticipatedUsers | Column has Dynamic Data Masking (default()) applied. What privilege level is required to see actual values? Are there any DWH users/roles configured with UNMASK permission? |
| Description | Same Dynamic Data Masking question as ParticipatedUsers. |

## Structural Questions

1. **Why was the INSERT commented out?** The data load for Dim_Campaign was disabled at an unknown point. Possible reasons: (a) PII concern about ParticipatedUsers or Description columns, (b) the campaign system was superseded by an external tool and the data became irrelevant, (c) data quality issue in staging. Should this be re-enabled or is the table safe to blacklist?
2. **Is this table safe to drop or blacklist?** The TRUNCATE + placeholder INSERT still runs daily, consuming SP execution time. If no fact tables JOIN to CampaignID from this dimension, it could be removed from the SP and blacklisted.
3. **BackOffice.Campaign frozen since 2017**: The production system has had no new campaigns since May 2017. Is campaign data still relevant for DWH analysis? Or has the entire campaign system been replaced?
4. **MASKED columns purpose**: Why apply Dynamic Data Masking to a table with no actual data? This suggests the masking was added in anticipation of loading the data, or added when the table still had data before a TRUNCATE cleared it.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
