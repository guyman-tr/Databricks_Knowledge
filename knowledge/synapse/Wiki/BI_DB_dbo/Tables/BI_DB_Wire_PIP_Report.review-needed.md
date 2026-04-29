# BI_DB_dbo.BI_DB_Wire_PIP_Report — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **EUR/GBP only filter**: Is this intentional that USD wire transfers are excluded, or should this report eventually cover all currencies?
2. **Discount% values**: The older discount logic (commented out in SP) used Club-based rates (Silver/Gold=0.25, Platinum=0.5, Diamond=1.0). The current logic uses Fivetran Google Sheets config which has much larger percentages (20%, 40%, 80%, 100%). Are both value ranges expected or is the config miscategorized?
3. **ExchangeFee always 150**: In the sample, ExchangeFee is always 150.00000000. Is this a fixed fee for all wire transfers, or does it vary by regulation?
4. **Eligible_for_discount columns**: These appear empty in sample data. Are they populated for newer dates or specific configurations?

## Corrections Applied

- DDL shows 20 columns (batch assignment said 16 — confirmed 20 from SSDT DDL, likely the table was expanded with Club, ExchangeFee, Regulation, Eligible_for_discount_private, Eligible_for_discount_corporate after the original 15-column design).
