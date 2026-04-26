# BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **DepositFundingType "Error"**: The SP has a CASE for FundingTypeID=0 → "Error". Are there any deposits with FundingTypeID=0 in practice? The live data shows only Automatic and Manual.
2. **eMoneyEligible criteria**: The commented-out line `AND CAST(fbd.PaymentDate AS DATE)>=mdcr.RolloutDate` was removed from the main WHERE but kept in the LEFT JOIN condition. Is the eligibility criteria still correct?
3. **HEAP distribution**: No clustered index on this 6.23M-row table. Would a CLUSTERED INDEX on DepositDate improve dashboard query performance?
4. **Companion table**: BI_DB_Money_Out_New_Management_Dashboard uses the same dashboard. Are they always queried together, or independently?

## Cross-Object Consistency Notes

- CID matches DWH_dbo.Dim_Customer.RealCID usage.
- DepositID matches Fact_BillingDeposit.DepositID.
- PaymentStatusID values align with Dim_PaymentStatus.
- Regulation values align with Dim_Regulation.Name.
