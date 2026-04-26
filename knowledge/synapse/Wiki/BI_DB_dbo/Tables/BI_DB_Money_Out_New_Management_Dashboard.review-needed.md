# BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Trailing SELECT**: The SP file ends with `SELECT * FROM BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard bdmonmd WHERE CAST(bdmonmd.UpdateDate AS DATE)='2023-08-24'` outside the BEGIN/END block. Is this a debug artifact or intentional?
2. **WithdrawID + FundingID uniqueness**: The DELETE+INSERT matches on WithdrawID+CID+FundingID. Are there cases where FundingID is NULL, which would prevent the DELETE from matching?
3. **Amount$Withdraw currency**: Is this amount in account currency (multi-currency) or always USD? The DDL type is money, and the SP uses ISNULL(Amount_WithdrawToFunding, Amount_Withdraw) — neither of which is explicitly AmountUSD.
4. **SLAHours calculation**: DATEDIFF(HOUR, RequestDate, ModificationDate) — for canceled/pending withdrawals, ModificationDate may be very close to RequestDate. Is SLAHours meaningful for non-Processed statuses?

## Cross-Object Consistency Notes

- CID matches DWH_dbo.Dim_Customer.RealCID usage across all BI_DB tables.
- Country, Region, Regulation logic matches the Money In companion table (same Dim_Country/Dim_Regulation joins via Fact_SnapshotCustomer).
- FundingType aligns with Dim_FundingType.Name used in Money In table's DepositMethod.
- Same 7-month rolling window cleanup as Money In table.
