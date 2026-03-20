# DWH_dbo.Fact_RegulationTransfer — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code and V_Liabilities analysis (Tier 2).

## Columns Needing Clarification

1. **RegulationID values**: What are the specific RegulationIDs? (e.g., 1=CySEC, 2=FCA, 3=ASIC, 4=FinCEN?). Is Dim_Regulation documented?
2. **Equity snapshot timing**: Confirmed that V_Liabilities is read for DateID = day BEFORE transfer. Is this because the transfer happens at market open and the previous day's closing equity is the most accurate?
3. **InvestedReal* computation**: `InvestedRealStocks = PositionPnLStocksReal + TotalRealStocks`. Is "Invested" really the sum of PnL + position value? Or is it just the position value (TotalRealStocks)?
4. **CID nullable**: CID is marked as NULL in DDL but is the distribution key. Can CID actually be NULL in practice?

## Structural Questions

1. **No primary key**: Should there be a PK on (CID, DateID)?
2. **money vs decimal**: The table mixes `money` and `decimal(16,2)` types for financial columns. The newer columns (futures, margin) use `decimal`. Should the older `money` columns be migrated to `decimal` for consistency?
3. **V_Liabilities dependency**: V_Liabilities is a view — if it changes schema, the INSERT will break. Is there monitoring for this?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
