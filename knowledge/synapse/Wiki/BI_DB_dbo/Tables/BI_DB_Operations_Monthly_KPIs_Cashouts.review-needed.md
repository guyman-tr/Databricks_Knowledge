# Review Needed: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts

## Tier 3 / Low Confidence Items

The following 10 columns are Tier 3 (inferred from column name/DDL only -- no upstream wiki or SP code confirmation):

- **IPAddress** (bigint): Mapped as customer IP but Fact_BillingWithdraw wiki does not expose this column directly. May come from a different source path in the SP.
- **Remark** (nvarchar max): Free-text remark field. Not documented in Fact_BillingWithdraw wiki. Likely from Billing.Withdraw directly.
- **RequestorComments** (nvarchar max): Not documented in Fact_BillingWithdraw wiki. Likely from Billing.Withdraw.
- **SuggestedBonusDeductionAmount** (money): From Billing.Withdraw but not surfaced in Fact_BillingWithdraw wiki. Need SP code review.
- **ActualBonusDeductionAmount** (money): Same as above.
- **ClientWithdrawReasonComment** (nvarchar max): From Billing.Withdraw but not in Fact_BillingWithdraw wiki.
- **UserFeedbackIssue** (int): Origin unclear. Could be from a feedback system not documented in DWH wikis.
- **ProcessMonth/ProcessYear/ProcessDay**: Mapped as DATEPART from ProcessorValueDate but could be from ModificationDate instead. SP code review needed.

## Open Questions

- The SP contains both pre- and post-2019-12-22 SLA CASE blocks. Are both branches still active, or is the pre-2019 block inert given the Nov 2021 data start?
- The FundingTypeID resolution CASE (prefer Funding over Withdraw) -- is there documentation on when these diverge and why?
- ModificationDateID is NULL in all 13.4M rows despite being in the clustered index. Is this intentional or a bug in the INSERT statement? Should the CI be rebuilt without it?
- Columns Remark, RequestorComments, SuggestedBonusDeductionAmount, ActualBonusDeductionAmount, ClientWithdrawReasonComment: these appear to come from Billing.Withdraw columns that are not surfaced through Fact_BillingWithdraw. Does the SP query Billing.Withdraw directly (bypassing Fact_BillingWithdraw)?
