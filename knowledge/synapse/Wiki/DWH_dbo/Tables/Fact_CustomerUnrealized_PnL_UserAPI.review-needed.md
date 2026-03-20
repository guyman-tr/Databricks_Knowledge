# DWH_dbo.Fact_CustomerUnrealized_PnL_UserAPI — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

1. **TransURPnL** (Tier 4): Assumed to be "Translated Unrealized PnL" — PnL converted to a common reporting currency. Confirm exact meaning and which currency it translates to.

## Columns Needing Clarification

1. **Who consumes this table?**: Which API or external system reads from this table? Is it the eToro public API, an internal microservice, or a partner data feed?
2. **NOP vs Notional**: NOP = Net Open Position (long - short). Notional = gross position value. Confirm this understanding.
3. **CommissionOnOpen vs FullCommissionOnOpen**: What's the difference? Is "Full" including partial-close portions?
4. **CopyFundPnL**: Is "Fund" = Smart Portfolio? Or is it a different product?

## Structural Questions

1. **Data redundancy**: This is a full copy of 34 columns from the parent table. Why not use a view?
2. **MenualPositionPnL**: Known typo. Any plans to fix it with a column rename?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
