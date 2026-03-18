# DWH_dbo.Fact_Reverse_Deposits - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Reason Unverified |
|--------|------------------|
| OldPaymentID | Legacy identifier; semantics inferred from name |
| RollbackCanceled | Whether non-NULL vs specific values indicate cancellation unclear |
| ReferenceNumber | External chargeback reference inferred from name |
| ConversionFee | Currency conversion fee inferred from context |
| ThreedsParameters | 3DS payload content inferred |
| CustomerStatus | Account status interpretation inferred |
| RiskStatus | Risk status interpretation inferred; distinct from RiskStatus in Fact_Deposit_Fees? |
| VerificationLevel | KYC level interpretation inferred |
| CustomerLevel | Tier level inferred |
| CountryByRegIP | IP-based country inferred |
| AccountManager | AM name inferred |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| RollbackCanceled | What values appear in this column? Is it NULL (not cancelled) vs a reason string, or a Y/N flag? |
| PreviousDepositStatus | What status transitions are most common? Can a deposit go from Refund to Approved (ChargebackReversal scenario)? |
| Customer financial columns | Are Balance/TotalDeposits/etc. calculated at the moment of rollback (real-time from BackOffice report), or are they stale cached values? |
| ConversionFee | When is a conversion fee applied to a rollback? Is this always zero for USD deposits? |
| VerificationLevel | What are the possible values? Is this KYC level 1/2/3 or a text label? |

## Structural Questions

| Question | Context |
|----------|---------|
| Pipeline status | Staging table DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion is gone. Is this pipeline permanently discontinued or migrated elsewhere? |
| Relationship to Fact_Deposit_Fees | Both tables have DepositID and overlapping columns. Can they always be joined on DepositID? A deposit in Fact_Reverse_Deposits should have a matching row in Fact_Deposit_Fees with DepositStatus=Refund/Chargeback - is this always true? |
| Why only 9,904 rows? | Fact_Deposit_Fees has 16,658 rows with non-Approved status (Refund+Chargeback+etc.). Why does Fact_Reverse_Deposits have only 9,904? Date range difference (Fact_Reverse_Deposits starts 2021 for rollbacks vs 2020 for deposits)? |
| No AffiliateID | Fact_Deposit_Fees has AffiliateID but Fact_Reverse_Deposits does not. Was this intentional? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
