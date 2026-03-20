# DWH_dbo.Dim_Position_Account_Statement_AmountInUnitsDecimal - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns - all columns typed from DDL (Tier 2) and confirmed by live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| AmountInUnitsDecimal_history | What is the "history" source? Is this from a specific history table (e.g., PositionHistory), a reporting snapshot, or a different ETL path? Knowing the source would clarify why there are systematic differences. |
| diff direction | Is diff always computed as _dwh - _history? Or could some rows be _history - _dwh? The positive/negative range (-374 to +23,332) suggests _dwh is generally higher. |

## Structural Questions

| Question | Context |
|----------|------------|
| Who populated this table? | No writer SP exists in the SSDT repo. Was this populated by a DBA script, a Python notebook, or an ADF pipeline outside of SSDT? Knowing the creator would clarify when it was last refreshed. |
| Is this table still relevant? | The 99.5% mismatch rate suggests the underlying issue may or may not have been resolved. Was this investigation concluded? Is the table still actively used? |
| Relationship to AmountInUnitsDecimal in Fact_Positions | The compared metric "AmountInUnitsDecimal" - which exact column in which fact table does this correspond to? Is it `Fact_Positions.AmountInUnitsDecimal` vs `Fact_PositionHistory.AmountInUnitsDecimal`? |
| Only 34,258 positions covered | The DWH has many more positions than 34K. Was this table scoped to a specific date range, product, or investigation batch? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|-----------------------------|--------------|----------------|
