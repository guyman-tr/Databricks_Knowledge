# DWH_dbo.Fact_Deposit_Fees - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Reason Unverified |
|--------|------------------|
| OldPaymentID | Column name only; no SP logic found that explains its purpose |
| UserName | Presence confirmed from DDL; semantics inferred |
| DepositValueDate | Accounting value date interpretation is inferred |
| TransactionID_Internal | Purpose inferred from column name |
| ResponseCode | Acquirer response code interpretation inferred |
| TransactionResponse | Full description inferred |
| Threedsparameters | Content inferred as 3DS payload |
| DepositRiskStatus | Two risk columns exist (DepositRiskStatus vs Riskstatus) - distinction unclear |
| Riskstatus | Distinct from DepositRiskStatus; which is processor vs platform? |
| CountryByRegIP | IP-based country interpretation inferred |
| CustomerStatus | Customer account status interpretation inferred |
| CustomerLevel | Tier level interpretation inferred |
| AccountManager | Assigned AM name interpretation inferred |
| FTD | First Time Deposit - text vs bit type unclear |
| Funnel | Dictionary.Funnel reference inferred |
| DepositType | NULL for most rows; meaning unclear |
| CardCategory | Debit/Credit/Prepaid interpretation inferred |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DepositRiskStatus vs Riskstatus | Two risk columns exist. What is the distinction? Which is set by eToro risk system vs payment processor? |
| FTD | Is this "Yes"/"No" text, "1"/"0" string, or bit? What defines FTD - first deposit across all time, or first deposit in current regulatory entity? |
| Brand vs CardCategory | Brand="Visa", CardCategory=? Are these from Billing.Deposit or from the card BIN lookup? |
| OldPaymentID | What payment system does this reference? Is it still used? |
| DepositType | All NULL in sampled rows. When is this populated? |
| Funnel | Is this from Dictionary.Funnel or a different source? |

## Structural Questions

| Question | Context |
|----------|---------|
| Pipeline status confirmation | Staging table DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion no longer exists. Is the pipeline permanently discontinued, or planned for migration to a new pipeline? |
| Relationship to Fact_BillingDeposit | How does Fact_Deposit_Fees differ from Fact_BillingDeposit? Is one a superset of the other? Can they be joined on DepositID? |
| Duplicate rows | SP DELETE clause is commented out. Are there duplicate DepositID rows from multiple SP runs? Should SELECT DISTINCT be used in aggregations? |
| ModificationDateID filtering | The SP comment shows an example WHERE ModificationDateID = 20230721 - was the table designed for daily partitioned loads that were never implemented? |
| nvarchar(max) performance | Many columns are nvarchar(max) despite being short strings (DepositStatus, FundingMethod, etc.). Was this intentional for schema flexibility? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
