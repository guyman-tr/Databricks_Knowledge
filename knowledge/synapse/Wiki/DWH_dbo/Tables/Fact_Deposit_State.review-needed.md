# DWH_dbo.Fact_Deposit_State - Review Needed

> Items flagged for offline domain expert review. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Current Description | Question |
|--------|--------------------|---------:|
| ExchangeFee | [UNVERIFIED] Exchange fee indicator. Values: 0, 52, 70, 101. May be basis points or a fee tier code. | Is ExchangeFee in basis points? Or an enumerated fee tier? What does 52 mean? |
| PIPsInUSD | [UNVERIFIED] Small decimal amount in USD (0.00-5.30). Possible: processing fee, platform incentive, or price improvement points. | What does PIPsInUSD represent in the Billing context? |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| PaymentStatusID=39 | What is PaymentStatusID=39? Dim_PaymentStatus shows 1-38 as of last doc. Is 39 a new status? |
| FromDate / EndDate | Are FromDate/EndDate always a 1-day window? Or can they span multiple days for certain transaction types? |
| FundingID | What table/object does FundingID point to? Is there a Dim_Funding or Fact_BillingWithdraw link? |
| CreditID | Is CreditID a surrogate key unique to Fact_Deposit_State, or does it reference a specific production table (e.g., Billing.Credit)? |

## Structural Questions

| Question |
|----------|
| Why does data only go back to 2023-01-01? Was a different table used for pre-2023 deposit state history? |
| Is Fact_Deposit_State exported to Databricks UC? It was not found in _generic_pipeline_mapping.json. |
| What is the relationship between Fact_Deposit_State and Fact_BillingDeposit? Do they overlap or serve different purposes? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
