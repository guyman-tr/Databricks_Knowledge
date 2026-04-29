# BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report — Review Needed

## Tier 4 Items (needs human verification)

- None — all columns resolved to Tier 1, Tier 2, Tier 3, or Tier 5.

## Questions for Reviewer

1. **"CDIM" acronym**: Assumed Consumer Duty Information Model — please confirm if this is the correct FCA regulatory framework name.
2. **Desk from Dim_Country vs CIDFirstDates**: The SP reads Desk from Dim_Country (dc1.Desk), and CIDFirstDates also has a Desk column. The wiki inherits from Dim_Country. Confirm this is correct.
3. **Appropriateness blank values**: 356 rows have empty string (not NULL) for Appropriateness_Status — are these customers who never took the test?
4. **Rollover fee adjustment**: Only CFD PnL columns subtract rollover fees (ActionTypeID=35). Stocks and Crypto PnL do not include this adjustment — is this intentional?
5. **Knowledge_Assessment_Score sentinel**: -100 means version not taken — should this be filtered or flagged in dashboards?

## Reviewer Corrections

(none yet)

---

*Generated: 2026-04-27 | Object: BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report*
