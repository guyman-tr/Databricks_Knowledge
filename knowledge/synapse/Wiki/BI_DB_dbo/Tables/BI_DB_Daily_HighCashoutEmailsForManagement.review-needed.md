# BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement — Review Needed

## Tier 4 Items

None — all columns traced to SP logic or DWH dimensions.

## Questions for Reviewer

1. **RequestorComments column**: This column exists in the DDL but is NOT populated by the SP. Should it be removed from the DDL, or is it populated by another process?
2. **FundingTypeID_Withdraw<>27**: What is FundingTypeID 27? Why is it excluded? Confirm this is the correct exclusion.
3. **CashoutStatusID NOT IN (3,4)**: Confirms this table shows PENDING requests only (not approved=3 or cancelled=4). Is the intention to show only un-actioned requests for management review?
4. **NWA = BonusCredit**: The SP uses V_Liabilities.BonusCredit for NWA. Confirm this is the correct mapping — NWA typically means "Net Worth Adjustment."
5. **PII/sensitive data**: AMLComment and RiskComment columns contain detailed compliance investigation notes. These should NOT be exported to general-access UC tables.
6. **DDL has 27 columns but batch assignment said 25**: The DDL has 27 columns (FundingType and CashoutReason were added in 2022). The batch assignment column count was approximate.

## Cross-Object Consistency Notes

- **Age calculation**: Uses DATEDIFF(year, BirthDate, GETDATE()) which is approximate (doesn't account for day-of-year). Standard SQL Server year-difference.

## Validation

- Element count: 27 (DDL) = 27 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
