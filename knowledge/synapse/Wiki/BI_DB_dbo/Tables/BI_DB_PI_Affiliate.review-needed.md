# BI_DB_dbo.BI_DB_PI_Affiliate — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **PII matching risk**: PI-to-affiliate matching uses FirstName + LastName + BirthDate. Could this produce false positives for common names?
2. **CID 11101455 exclusion**: Hard-coded exclusion in the SP — what is the business reason?
3. **Column count**: Batch assignment said 44, DDL has 43. Verified by counting DDL columns.
4. **Amount negation**: All MIMO amounts use `-Amount`. Is this the standard Fact_CustomerAction convention for copy actions?
5. **LastMonth = 30 days**: The SP uses `DATEADD(DAY,-30,@yesterday)`, not calendar month. Is this intentional or should it align with calendar months?

## Tier Summary

- **Tier 1 (5 columns)**: UserName, GuruStatusID, PITier, PI_RealCID (4 dim-lookup passthroughs + 1 computed dim-lookup)
- **Tier 2 (38 columns)**: All FTD, MIMO, AUM, Date, Manager, Affiliate, and UpdateDate columns
