# BI_DB_dbo.BI_DB_IndexDividends_Alert — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Alert consumption**: How is this alert table consumed? Is there a dashboard, email alert, or downstream process that reads it? The SSDT repo shows no consumers.

2. **BuyTax_Null_Ind always 1**: The SP filters to BuyTax_Null_Ind = 1 before inserting — the column is always 1 when rows exist. Is this by design, or should 0 values also be tracked?

## Reviewer Corrections

None yet.
