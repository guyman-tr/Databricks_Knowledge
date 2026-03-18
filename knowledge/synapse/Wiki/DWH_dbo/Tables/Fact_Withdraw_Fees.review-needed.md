# DWH_dbo.Fact_Withdraw_Fees - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Reason Unverified |
|--------|------------------|
| PaymentOrderStatus | Distinct from WithdrawStatus; semantics inferred |
| ProcessorValueDate | Accounting value date inferred |
| PreparationType | BackOffice workflow type inferred from column name |
| ExecutionType | Execution classification inferred |
| Executedby | System vs staff executor inferred |
| CashoutType | Cashout classification inferred |
| BackOfficeWithdrawReason | BackOffice reason inferred; no live sample taken |
| VerificationCode | Processor verification code inferred |
| VendorCode | Vendor-specific code inferred |
| CustomerStatus | Account status inferred |
| CustomerLevel | Customer tier inferred |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| "Partialy Reversed" typo | Is "Partialy Reversed" (missing 'l') a data error in production or intentional? Is there also a properly spelled "Partially Reversed" status that may appear in newer data? |
| DepositID in withdrawals | When is DepositID populated vs NULL? Is it only for credit card returns (card-match compliance) or also for other funding methods? |
| BackOfficeWithdrawReason | What values appear in BackOfficeWithdrawReason? Is it used for compliance-initiated withdrawals? |
| PreparationType, ExecutionType, Executedby | What are the distinct values? Do they represent manual vs automated vs batch? |
| PaymentOrderStatus vs WithdrawStatus | What is the relationship? Can WithdrawStatus=Processed but PaymentOrderStatus!=Processed? |
| ProcessorValueDate | Is this the bank value date for wire transfers? When is it different from ProcessTime? |

## Structural Questions

| Question | Context |
|----------|---------|
| Pipeline status | Staging table DWH_staging.etoro_BackOffice_GetProcessedWithdrawPCIVersion is gone. Is this permanently discontinued or being migrated? |
| No AccountManager column | Fact_Deposit_Fees has AccountManager but Fact_Withdraw_Fees does not. Was this intentional? |
| ProcessTime starts 2021-12 | Deposit data starts 2020-03 but withdrawal data starts 2021-12. Is this by design (pipeline started later) or are earlier withdrawals in a different table? |
| eToroCryptoWallet withdrawals | 532,899 crypto wallet withdrawals (8%). Is there separate crypto-specific data or documentation for this channel? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
