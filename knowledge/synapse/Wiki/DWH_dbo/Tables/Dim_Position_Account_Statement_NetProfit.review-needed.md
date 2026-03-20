# DWH_dbo.Dim_Position_Account_Statement_NetProfit - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns - all columns typed from DDL (Tier 2) and confirmed by live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| NetProfit_dwh (all zeros) | Was DWH NetProfit intentionally set to 0 for these positions, or was the calculation missing/broken at the time? If the DWH NetProfit has since been implemented, this table captures a historical gap. |
| NetProfit_history | What specific source is this? Is it from Fact_PositionHistory.NetProfit, a reporting system, or a different ETL path? |

## Structural Questions

| Question | Context |
|----------|------------|
| Who populated this table? | No writer SP exists in the SSDT repo. Was this a DBA investigation, a Python script, or a one-time ADF run? |
| Is the DWH NetProfit calculation now implemented? | Since all _dwh values are 0, this table documents a state where DWH lacked the metric. Has this been fixed since the table was populated? |
| Why 251K rows vs 34K for AmountInUnitsDecimal? | The sibling table has 34,258 rows while this has 251,813. Were these investigations run at different times, against different position populations, or with different scope criteria? |
| Relationship to production NetProfit | Which DWH object(s) now hold the authoritative NetProfit per position? Is this Fact_Positions.NetProfit? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|-----------------------------|--------------|----------------|
