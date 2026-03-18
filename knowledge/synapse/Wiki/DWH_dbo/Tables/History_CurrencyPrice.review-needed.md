# DWH_dbo.History_CurrencyPrice - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Reason Unverified |
|--------|------------------|
| LiquidityAccountID | Liquidity account routing semantics inferred from name |
| RateLastEx | "Last executed rate" interpretation inferred; relationship to Bid/Ask unclear |
| MarketReceivedTime | Distinct from ReceivedOnPriceServer; exact meaning inferred |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| RateLastEx | What does this represent? Is it the price of the last trade executed against this quote? How does it differ from Bid/Ask? |
| LiquidityAccountID | What are the valid values? Does this map to a lookup table? |
| MarketReceivedTime vs ReceivedOnPriceServer | What is the distinction? Is MarketReceivedTime from the exchange/ECN and ReceivedOnPriceServer from the eToro price aggregation layer? |
| ValidFrom/ValidTo | Are these always populated for every tick, or only for "snapshot" style records? What is the logic that sets ValidTo? |
| SkewValueBid/SkewValueAsk | When are these non-zero? Is skew only applied for specific instruments (e.g., crypto) or for all? |

## Structural Questions

| Question | Context |
|----------|---------|
| Row count estimate | Live data query times out - unable to confirm total row count. Estimate needed for infrastructure planning. Is this billions of rows? |
| Data retention | How far back does the Bronze archive go? Is there a retention policy that removes old partitions? |
| History_CurrencyPrice_20230622 | There is a dated variant (hardcoded to 2023-06-22). What is the purpose of this snapshot? Was it used for a specific migration/audit? |
| PriceLog_History_CurrencyPrice_Active staging tables | How are these materialized? ADF pipeline, stored procedure, or streaming? How frequently updated? |
| UC target | This Bronze data likely already exists in UC. What is the actual Unity Catalog table name? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
