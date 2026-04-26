# Review Needed: BI_DB_dbo.BI_DB_HourlyReport_Redeems

## Tier 4 Items (Best Available Knowledge)

None — all columns traced to source code or upstream wiki.

## Questions for Reviewer

1. **Table name "Redeems" vs FundingTypeID=27 (eToroCryptoWallet)**: The name suggests "redeems" but the SP filters to crypto wallet withdrawals only. Is "redeem" the internal term for crypto wallet withdrawal, or was this table repurposed from an earlier use?
2. **FullyFunded column is money type but stores 0/1**: Should this be int or bit? The CASE expression produces integer values but the DDL declares money.
3. **ReadyForPayment always 0**: The SUM(CASE...) aggregation within a GROUP BY that already has all non-aggregated columns may always yield 0 or 1. In current data, it's always 0. Is this column meaningful or a remnant?
4. **COStatus5-13 utility**: Status codes 5-13 are rare/specialized. Are any of COStatus5-13 ever populated for crypto wallet redeems?
5. **Typo in external table name**: `External_etoro_Billimg_vWithdrawToFunding_FUll` has "Billimg" (should be "Billing") and "FUll" (inconsistent case). This is a known DDL artifact.
6. **CashoutReasonID 15=Affiliate Payment treated as Foreclosed**: Is this correct? Affiliate payments seem distinct from account foreclosure.

## Corrections Applied

None.

## Cross-Object Consistency Notes

- **WithdrawID, CID**: Same FK conventions as across BI_DB_dbo billing tables.
- **CashoutStatusID/CashoutStatus**: Same lookup pattern as Object 1 (BI_DB_H_SEA_CashoutsEstimation).
- **Approved**: Note this is int (passthrough), unlike Object 1 where it's converted to 'YES'/'NO' varchar.
