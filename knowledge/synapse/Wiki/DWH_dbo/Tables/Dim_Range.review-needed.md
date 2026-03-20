# DWH_dbo.Dim_Range - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 2 or Tier 3b.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DateRangeID (cross-year ranges) | The encoding formula constrains ToDate year = FromDate year. Are there any cross-year ranges (e.g., FromDate in Dec, ToDate in following Jan)? If so, how are they encoded? |
| ToDateID (non-year-end values) | 6,770 distinct ToDateIDs suggest many non-Dec-31 to-dates. What business use cases generate non-year-end ToDate values in the Snapshot SPs? |

## Structural Questions

- **Three NCIs on a REPLICATE table**: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, IX_Dim_Range_FromDateID_ToDateID. What query pattern requires these? Synapse NCIs have overhead - are these actively used by the Snapshot views?
- **Primary Key NOT ENFORCED**: If both SPs insert independently (SnapshotEquity + SnapshotCustomer), is there a race condition risk where both try to insert the same DateRangeID simultaneously on the same day?
- **1.3M rows and growing**: At ~365 new rows per day minimum, this table will grow substantially. Is there a cleanup or archival plan?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
