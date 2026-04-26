# BI_DB_dbo.BI_DB_EndOfDayReport_Redeems — Review Needed

## Tier 4 Items
None.

## Reviewer Questions

1. **TimeFrame threshold mismatch**: 'Over 30 days' label starts at 15 days (DATEADD(DAY,-15)). Should this be 30 days? Or should the label be 'Over 15 days'?

2. **Column name typo**: `NoOfRedees` is missing an 'm' — should be NoOfRedeems. DDL would need alteration.

3. **Column name with space**: `[Redeem Status Group]` has spaces — unusual for a column name. Consider renaming.

4. **No author documented**: SP has no author comment header.

5. **DDL says 6 columns but actual count is 7**: Batch assignment listed 6; DDL has 7 (includes RequestDate which Cashouts doesn't have).

## Data Quality Notes
- 111 rows total — small summary table
- Hourly refresh (SB_Hourly)
- Most rows are TransactionDone/Over 30 days (processed historical redeems)
