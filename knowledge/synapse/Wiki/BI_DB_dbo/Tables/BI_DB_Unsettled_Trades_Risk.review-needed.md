# BI_DB_dbo.BI_DB_Unsettled_Trades_Risk — Review Needed

## Tier 4 Items (Unverified)

- None — all columns traced to SP code and Dealing_staging source.

## Questions for Reviewer

1. **Fail Reason Codes**: The 30 BNY Mellon fail reason codes (PRCY, CLAC, LACK, etc.) are industry-standard SWIFT codes. Confirm the descriptions are accurate for eToro's BNY Mellon account context.
2. **Amount_USD sentinel**: The SP uses `Local_Net_Amount * 1000000000` for unsupported currencies — is this intentional as a flag, or a bug? Currently CZK is in Dim_Instrument lookup but not in the live data (0 rows).
3. **Client_Reference format**: The numeric-plus-'C' suffix format (e.g., "177544108242C") — does the numeric part map to any eToro internal CID or account?
4. **Age_Days direction**: DATEDIFF(day, Report_Run_Date, Contractual_Settle_Date) gives negative values. Is this the intended convention, or should it be the inverse (positive = days overdue)?

## Cross-Object Consistency Notes

- No Tier 1 columns — source is BNY Mellon LP staging report with no upstream wiki.
- FX conversion uses Dim_Instrument + Fact_CurrencyPriceWithSplit (standard DWH pattern).

## Potential Data Quality Issues

- Amount_USD sentinel value (1B multiplier) for unsupported currencies may appear in aggregations
- 17 rows have empty string Fail_Reason_Code
