# DWH_dbo.Fact_History_Cost — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

1. **PartitionCol** (Tier 4): Purpose unknown — appears to be an application-level partition column from the source system. What does it represent?

## Columns Needing Clarification

1. **CostType vs CostSubType mapping**: What are the specific values? (e.g., CostTypeID 1=Spread, 2=Overnight, 3=Commission?)
2. **No date filter on staging**: The SP imports ALL rows from `DWH_staging.HistoryCosts_History_Costs` (the WHERE clause is commented out). Does this mean every run re-imports the full history?
3. **MirrorID**: Confirmed this links to copy trading? Or does it have another meaning in the cost context?
4. **CostCurrencyID vs BalanceCurrencyID vs AssetCurrencyID**: When do these three differ? Example scenario?

## Structural Questions

1. **HASH(CostID) distribution**: CostID is unique per row — this creates perfectly even distribution but prevents co-located JOINs on CID. Is the analytical workload primarily scan-heavy (favoring CCI) or JOIN-heavy (favoring HASH(CID))?
2. **PK NOT ENFORCED**: The composite PK (DateID, CostID, CID) is not enforced. Is there dedup logic elsewhere?
3. **decimal(38,18) precision**: Is this level of precision needed? 38,18 can hold very small values but limits the integer part to 20 digits.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
