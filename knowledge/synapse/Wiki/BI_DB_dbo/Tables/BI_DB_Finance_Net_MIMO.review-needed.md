# Review Needed: BI_DB_dbo.BI_DB_Finance_Net_MIMO

Generated: 2026-04-22 | Batch 25 #4

## Tier 4 Items (Needs SME Verification)

None — all column descriptions are Tier 1 or Tier 2.

## Questions for Business SME

1. **FundingType asymmetry — withdrawals use processor side**: The SP uses `FundingTypeID_Funding` (processor payment method) for withdrawals, not `FundingTypeID_Withdraw` (customer's withdrawal request method). This means a customer who originally deposited via CreditCard but has a wire transfer withdrawal will appear under WireTransfer in the MIMO table. Is this the intended design (tracking actual money movement channel), or should withdrawal FundingType reflect the customer-requested method?

2. **Total_Transaction_Count is additive (deposits + withdrawals)**: The column sums inflow and outflow unique transaction counts, which means it cannot be used to count unique customers or unique payment events per direction. Is there a separate table that provides deposit-only and withdrawal-only transaction counts by dimension?

3. **BVI net negative ($-204M over 5 years)**: BVI-regulated customers consistently show more withdrawals than deposits in MIMO. Is this expected (BVI customers are historically net withdrawers), or does it indicate a data quality issue with how BVI regulation is assigned?

4. **IsValidCustomer filter — demo accounts excluded**: The SP filters `IsValidCustomer = 1`, so demo account deposits/withdrawals are completely excluded. Confirm that finance reporting requirements are for real-money accounts only, and that no separate MIMO report exists for demo accounts.

5. **No IsCreditReportValidCB=0 rows for some dates**: In some day/dimension combinations, only IsCreditReportValidCB=1 rows exist. Is it expected that some dimension combinations have no IsCreditReportValidCB=0 customers making deposits/withdrawals?

## Data Quality Observations

- **Currency = 'USD' with Net Amount in USD**: For USD deposits, AmountUSD = Amount in processing currency. For multi-currency deposits, the conversion to USD is done in the source (Fact_BillingDeposit.AmountUSD is already in USD). Consumers should not divide by exchange rates — the column is already USD.
- **Total_Transaction_Count sums both directions**: Cannot be used to count inbound or outbound separately without going back to source tables.
- **Non-trading day gaps**: Dates with no approved deposits or withdrawals have no rows — the table is sparse for low-activity days/segments. Consumers should use LEFT JOIN or fill with zeros for trend analysis.

## Reviewer Sign-Off

- [ ] FundingType processor-side design confirmed (intentional or needs change)
- [ ] Additive Transaction_Count design confirmed
- [ ] BVI net-negative MIMO confirmed as expected
- [ ] IsValidCustomer=1 filter scope confirmed
- [ ] Downstream consumers confirmed
