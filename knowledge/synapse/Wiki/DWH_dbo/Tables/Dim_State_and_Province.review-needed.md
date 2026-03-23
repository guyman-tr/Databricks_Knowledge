# DWH_dbo.Dim_State_and_Province -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 5 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

1. **ShortName vs Name distinction**: ShortName contains the geolocation provider's code (e.g., "CA", "64") while Name contains the full label (e.g., "California"). Confirm which column should be used in customer-facing reports.

## Structural Questions

1. **181 rows vs 4,206 source rows**: The INNER JOIN filters ~98% of RegionByIP entries. Confirm whether this is intentional (only named regions are useful in DWH) or if regions without RegionName entries should also be present.
2. **Upstream wiki gap**: Dictionary.RegionName has an upstream wiki (read during Phase 10A) but ShortName/Name column descriptions are Tier 2 only (derived from SP code). Consider upgrading to Tier 1 by reading the RegionName wiki details.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
