# Review Needed: BI_DB_dbo.BI_DB_Daily_Open_Closed_Position

## Tier 4 Items

None — all columns traced to DWH_dbo dimension/fact wikis or SP code.

## Questions for Reviewer

1. **Residual 'Stocks' InstrumentType**: 86 rows in 2026 have InstrumentType='Stocks' instead of 'US Stocks' or 'Non-US Stocks'. This may be edge cases where InstrumentTypeID is not 5 but InstrumentType text is 'Stocks', or instruments without ISINCode. Confirm if this is expected behavior.

2. **Date range start**: Data starts Jan 2023, but the SP has no explicit start date filter. Was the table truncated or recreated around that time? The SP comment says logic changed 2024-05-30.

3. **Buy/Sell amount basis**: Buy Amount uses InitialAmountCents/100 while Sell Amount uses Amount+NetProfit. Confirm this is intentional for the business use case (initial investment vs realized value at close).

4. **No CID grain**: This aggregate table cannot be drilled to customer level. Is there a complementary CID-level table for position open/close analysis?

## Corrections Applied

- DDL column count is 14 (orchestrator stated 11 — corrected).

## Cross-Object Consistency

- Regulation values match DWH_dbo.Dim_Regulation wiki.
- PlayerStatus values match DWH_dbo.Dim_PlayerStatus wiki (trailing spaces noted).
- Club values match DWH_dbo.Dim_PlayerLevel wiki.
- Country values match DWH_dbo.Dim_Country wiki.
- IsSettled description matches DWH_dbo.Dim_Position wiki.
