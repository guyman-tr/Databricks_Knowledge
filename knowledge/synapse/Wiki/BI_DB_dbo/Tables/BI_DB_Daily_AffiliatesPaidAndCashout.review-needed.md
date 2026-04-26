# BI_DB_dbo.BI_DB_Daily_AffiliatesPaidAndCashout — Review Needed

## Tier 4 Items

None — all columns traced to SP logic or DWH dimension lookups.

## Questions for Reviewer

1. **PII exposure**: Contact, WebSiteURL, and Email columns contain real affiliate partner contact information. Should these be masked in downstream UC exports?
2. **CashoutStatusID=3 meaning**: The SP filters for CashoutStatusID_Funding=3 AND CashoutStatusID_Withdraw=3. Confirm this means "approved" status on both sides.
3. **Country source**: Country comes from MarketingMonthlyRawData.CountryID (the marketing cost record), NOT from Dim_Customer. This means it's the country associated with the affiliate cost, not the customer's country.

## Validation

- Element count: 14 (DDL) = 14 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
