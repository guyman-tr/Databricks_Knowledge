# DWH_dbo.V_Fact_SnapshotCustomer_FromDateID_Masked — Review Needed

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

All `[UNVERIFIED]` items are lifted unchanged from `Fact_SnapshotCustomer.md` for legacy placeholders.

## Columns Needing Clarification

Masking deltas between Synapse DDL `MASKED WITH` clauses vs Databricks column masking — confirm parity for analysts.

## Structural Questions

Databricks SQL samples may require dialect tweaks (`CAST(... AS DATE)` vs `STRING` literals) depending on warehouse settings.
