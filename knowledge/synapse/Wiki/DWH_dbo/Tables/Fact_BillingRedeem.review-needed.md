# DWH_dbo.Fact_BillingRedeem -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All 12 columns have Tier 2 (SP code) descriptions.

## Columns Needing Clarification

1. **No upstream wiki**: `Billing.Redeem` production table is not yet documented in DB_Schema wiki. All column descriptions are based on SP code analysis and naming conventions. Domain expert validation recommended.
2. **AmountOnRequest vs AmountOnClose semantics**: Confirm the business rule for when these two amounts differ (market movement? fee deduction? manual adjustment?).
3. **FundingID null rate**: What percentage of redeems have NULL FundingID? Are there redeems that don't require a payment instrument (internal transfers)?

## Structural Questions

1. **PositionID as bigint**: Most position IDs in DWH are INT. The bigint suggests this may reference a different position namespace (copy positions vs. regular positions). Confirm the join target for PositionID.
2. **Relationship to Billing.Cashout**: Is `Billing.Redeem` distinct from `Billing.Cashout`? They appear to be different withdrawal mechanisms (Redeem=copy position cashout; Cashout=general withdrawal). Confirm the distinction.
3. **1.4M row count**: Relatively small for an hourly-refreshed billing table. Confirm whether historical redeems are retained or if there's a retention cutoff beyond the 7-day refresh window.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
