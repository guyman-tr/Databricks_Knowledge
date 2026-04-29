# BI_DB_dbo.BI_DB_VAT_Transactions — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Questions for Reviewer

1. **ActionTypeID=39**: What does this action type represent? The SP filters to ActionTypeID IN (1,2,3,39) but 39 is not documented in Dim_ActionType context.
2. **IsSettled=-1**: 1% of rows have IsSettled=-1. What does this mean? Is it a sentinel, error, or a valid business state?
3. **IsCreditReportValidCB**: This filter on Fact_SnapshotCustomer determines which customers are included in VAT reporting. What is the business definition of "credit report valid"?

## Corrections Log

- DDL shows 6 columns (batch assignment estimated 7). Documented 6.

## Cross-Object Consistency

- **Regulation** description inherited verbatim from Dim_Regulation.Name wiki (Tier 1 — Dictionary.Regulation)
- **Country** description inherited verbatim from Dim_Country.Name wiki (Tier 1 — Dictionary.Country)
