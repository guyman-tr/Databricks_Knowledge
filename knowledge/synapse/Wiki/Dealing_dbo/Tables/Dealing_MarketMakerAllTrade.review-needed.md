# Dealing_dbo.Dealing_MarketMakerAllTrade — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| ApiPrice | Should this column be renamed to ExecutedPrice or PriceDiff? | Name is misleading — it stores the executed price when different from API, not the API price itself. |
| DIFF | What does 'DB' stand for? | Assumed "Dealer Board" or "Dealer Book" — triggered when Price=-1 (dealer override). |
| OrderStatus filtering | What are OrderStatus 2 and 4? | SP filters `OrderStatus NOT IN (2, 4)`. Likely 2=Cancelled, 4=Rejected. |

## Structural Questions

| Question | Context |
|----------|---------|
| What happened to eToroX trades? | SR-239249 removed the eToroX section. Is eToroX exchange data now tracked elsewhere? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
