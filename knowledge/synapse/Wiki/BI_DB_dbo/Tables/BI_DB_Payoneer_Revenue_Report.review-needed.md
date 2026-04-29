# BI_DB_dbo.BI_DB_Payoneer_Revenue_Report — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **Column count mismatch**: Batch assignment said 5 columns but DDL has 7 (EndofMonth, Country, Client Type, Clients Generated Revenue, Clients, Revenue, UpdateDate).
2. **Payoneer lifetime classification**: Is it intentional that the Payoneer flag is lifetime and not per-month? A customer who used Payoneer once in 2020 will be classified as Payoneer in every subsequent month.
3. **Clients Generated Revenue includes zero**: The CASE check is `Revenue >= 0`, which includes clients with exactly zero revenue. Should this be `> 0` instead?
4. **No author in SP header**: The SP has no author attribution in the comment block.

## Tier Summary

- **Tier 1 (1 column)**: Country
- **Tier 2 (6 columns)**: EndofMonth, Client Type, Clients Generated Revenue, Clients, Revenue, UpdateDate
