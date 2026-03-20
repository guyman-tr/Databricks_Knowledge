# DWH_dbo.Fact_Position_Futures_Snapshot — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns.

## Columns Needing Clarification

1. **PnL formula for open positions**: `LotCount × Multiplier × (SettlementPrice - InitForexRate)` — is this correct for both buy and sell positions? Should sell be negated?
2. **14-day settlement price lookback**: If no settlement price exists within 14 days, what happens to the position in risk reports? NULL PnL?
3. **ProviderMargin/eToroMargin typed as int**: These are computed as `LotCount × MarginPerLot` but stored as `int`. Is precision loss acceptable here?
4. **CloseOccurred = '1900-01-01'**: Why use a sentinel date instead of NULL for open positions?

## Structural Questions

1. **No primary key**: Should there be a PK on (DateID, PositionID)?
2. **OriginalPositionID**: For partial close children, how reliable is this linkage? Does it handle multi-level partial closes (partial close of a partial close)?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
