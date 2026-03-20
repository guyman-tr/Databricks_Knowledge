# DWH_dbo.Dim_ExecutionOperationType - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None. All columns resolved to Tier 2 (SP code).

## Columns Needing Clarification

- **Operation categorization**: The grouping of 25 operation types into 6 categories (Order Lifecycle, Position Event, Operational, Direct, Limit/Rate, Admin) is inferred from the names - no authoritative classification source found. Domain expert should confirm these groupings.
- **HistoryCosts context**: These operations are used in Fact_History_Cost (not yet documented). How exactly is OperationTypeId used there - is it the type of the traded position, or the type of cost event?
- **"InMirror" meaning**: Confirmed as copy-trade but verify if this encompasses both CopyTrade and Mirror products.

## Structural Questions

- **ROUND_ROBIN distribution anomaly**: With only 25 rows, REPLICATE would be significantly more efficient. Was ROUND_ROBIN intentional (e.g., to test something) or an oversight?
- **UpdateDate NOT NULL**: All other SP_Dictionaries-loaded tables have UpdateDate as nullable. Why is UpdateDate NOT NULL here? Is there special handling in the ETL?
- **OperationType nvarchar(max)**: All other dictionary name columns use varchar(N). Why nvarchar(max) for OperationType? Is there a Unicode requirement for HistoryCosts operation names?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
