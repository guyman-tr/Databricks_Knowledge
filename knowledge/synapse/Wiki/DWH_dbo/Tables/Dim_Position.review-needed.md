# DWH_dbo.Dim_Position -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

The following columns have Tier 4 (name-inferred) descriptions due to absence of upstream production wiki:

| Column | Tier 4 Description | Needs Clarification |
|--------|-------------------|---------------------|
| ProviderID | Liquidity provider or execution venue | Is this FK to a Dim_Provider? What are the values? |
| SpreadedPipBid / SpreadedPipAsk | Bid/ask in pips with spread | Is this in raw pip units? Currency? |
| LimitRate / StopRate | Take-profit and stop-loss rates | Confirmed correct? Do these update when customer changes SL/TP? |
| OrderType | Order type code | What are the valid codes? Market=1, Limit=2? |
| ExitOrderType | Exit order type code | Same codeset as OrderType? |
| OrderID / ExitOrderID | Order IDs | FK to which table? |
| PositionSegment | Internal segment | What are the valid values and their meanings? |
| IsOpenOpen | Opened at market open price | When is this set? Scheduled open orders? |
| RedeemStatus / RedeemID | Redemption state | What are valid RedeemStatus values? |
| IsSettledOnOpen | Settled at open | How does this differ from IsSettled? |
| IsComputeForHedge | Hedge accounting flag | What triggers this? |
| SettlementTypeID | Settlement mechanism | FK to which table? What are values? |
| Close_PriceType | Price type at close | Valid values? Bid=0, Ask=1, Mid=2? |
| StopRateOnOpen / LimitRateOnOpen | Immutable snapshot at open | Confirmed these do NOT change when SL/TP is updated (unlike StopRate/LimitRate)? |

## Columns Needing Clarification

- **CloseDateID=19000101 transient state**: Confirmed that this is only present during active ETL execution and should not appear in stable data? Or can it persist due to failed ETL runs?
- **Volume vs VolumeOnClose calculation**: The Volume calculation uses different formulas for open vs closed positions. For closed, VolumeOnClose uses `AmountInUnitsDecimal * EndForexRate * conversion`. For open, VolumeOnClose=0. Is this the intended behavior for P&L-weighted volume analysis?
- **PnLInDollars vs NetProfit**: When are these different? For closed positions, do they always match? For open positions, PnLInDollars is the daily unrealized P&L while NetProfit may hold a different value?
- **RegulationIDOnOpen JOIN logic**: The BackOfficeCustomer history JOIN uses `c.ValidFrom < @CurrentDate AND c.ValidTo >= @CurrentDate`. This gives the customer's regulation AS OF THE ETL RUN DATE, not necessarily the date they opened the position. Is this correct, or should it join to `c.ValidFrom <= OpenOccurred AND c.ValidTo > OpenOccurred`?
- **OpenPositionReasonID from OpenActionType**: Line 520 in SP has a typo: `OpenPositionReasonIDfOpenTotalFees`. Is this a copy-paste bug in the SP? Does it affect the loaded column name?
- **IsPartialCloseParent / IsPartialCloseChild**: When a position is partially closed, the parent row gets IsPartialCloseParent=1 and the new child gets IsPartialCloseChild=1. But how is the child row identified -- does it share OriginalPositionID with the parent? Or is it a new PositionID?
- **DDL partition column anomaly**: The PARTITION clause says `[DateID]` but there is no `DateID` column in the table -- the clustering is on `CloseDateID`. Is the partition actually functioning correctly? Which column is Synapse partitioning by?

## Structural Questions

- **NOT ENFORCED PK**: The PK (PositionID, CloseDateID) is NOT ENFORCED. Have duplicates ever occurred? Is there monitoring to detect them?
- **134 columns -- many from incremental additions**: 20+ columns were added between 2022-2025. Columns for positions opened before each addition date will be NULL. Is there any backfill of these NULL values for historical positions?
- **UpdateDate mixed timezone**: GETDATE() for new inserts vs GETUTCDATE() for updates -- is this intentional or a bug in the SP?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
