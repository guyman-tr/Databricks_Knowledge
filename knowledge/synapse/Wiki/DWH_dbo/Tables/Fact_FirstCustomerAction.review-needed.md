# DWH_dbo.Fact_FirstCustomerAction — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

1. **UpdateDateID** (Tier 4): Assumed to be the date portion of UpdateDate in YYYYMMDD format. Not populated in the SP — is it set elsewhere?

## Columns Needing Clarification

1. **FirstEver semantics**: The second MERGE captures events by HistoryID with FirstEver=0. What is the business use case for these non-"first-ever" events? Are they used in any reports?
2. **ActionTypeID values**: Which ActionTypeIDs are most commonly queried for funnel analysis? (e.g., which ID = first deposit, first trade, first withdrawal?)
3. **DELETE re-processing**: `DELETE WHERE FirstOccurred >= @Yesterday` — this means if a customer's first action was yesterday and we re-run, it gets deleted and re-merged. Does this handle late-arriving data correctly?

## Structural Questions

1. **RealCID distribution**: The table is HASH(RealCID) but many queries will filter by GCID. Should there be an NCI on GCID?
2. **No primary key**: This table has no PK constraint. The logical key is (GCID, ActionTypeID) for FirstEver=1 rows, but FirstEver=0 rows can have duplicate (GCID, ActionTypeID). Is this intentional?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
