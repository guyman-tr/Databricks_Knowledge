# Review Needed: BI_DB_dbo.BI_DB_HourlyReport_Withdraws

## Tier 4 Items (Best Available Knowledge)

None — all columns traced to source code or upstream wiki.

## Questions for Reviewer

1. **Companion table pair**: This table (FundingTypeID != 27) + BI_DB_HourlyReport_Redeems (FundingTypeID = 27) cover all active withdrawals. Is this split intentional for Tableau dashboard performance, or could they be unified?
2. **WithdrawID is int here vs bigint in Redeems**: Is there a truncation risk as WithdrawID grows beyond int max (2.1B)? Current max is ~19M so not imminent, but the inconsistency is notable.
3. **15-day window vs 30-day for Redeems**: Why the different window sizes? Was the 15-day window a deliberate reduction (SP comment says it was 6 months, then 2 weeks)?
4. **PK NOT ENFORCED**: Synapse doesn't enforce PKs — this is just for optimizer hints. Is the PK useful for Tableau or downstream tools?
5. **Column count discrepancy**: DDL has 26 columns but the batch assignment listed 27. DDL used as ground truth.
6. **CashoutReasonID 15=Affiliate Payment treated as Foreclosed**: Same question as Redeems — is this intentional?

## Corrections Applied

None.

## Cross-Object Consistency Notes

- **Identical structure to BI_DB_HourlyReport_Redeems**: Same 26 columns in same order, same PIVOT logic, same flag computation. Key differences: FundingTypeID filter (NOT IN 27 vs IN 27), window (15d vs 30d), WithdrawID type (int vs bigint), FullyFunded type (int vs money), PK constraint (present vs absent), external table used (vWithdrawToFunding vs Billimg_vWithdrawToFunding_FUll for funding amount).
- **WithdrawID, CID, CashoutStatusID**: Same FK conventions across all billing tables.
- **Approved**: Int passthrough (same as Redeems, unlike Object 1 which converts to varchar YES/NO).
