# Review Needed: BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation

## Tier 4 Items (Best Available Knowledge)

None — all columns traced to source code or upstream wiki.

## Questions for Reviewer

1. **Table currently empty (0 rows)**: Is this table still actively used? The SP runs hourly but if no OnlineBanking/UnionPay cashouts are pending, the table remains empty. Confirm this is expected operational behavior.
2. **"SEA" in table name**: The name suggests South-East Asia operations, but the SP has no geographic filter (no CountryID or RegulationID filter). Is "SEA" referring to the team name rather than a geographic scope? The table includes ALL regulations via Dim_Regulation.
3. **FundingTypeID 22 = UnionPay and 28 = OnlineBanking**: Confirm these are the correct mapping values. The SP comment says "OnlineBaking and UnionPay" (typo: OnlineBaking → OnlineBanking).
4. **Column count discrepancy**: DDL has 12 columns but the batch assignment listed 9 columns. The DDL includes SCREEN, Regulation, and UpdateDate which may have been missed in the column count.
5. **AMOPCurrency**: What does "AMOP" stand for? Likely "Alternative Method of Payment" — reviewer to confirm.

## Corrections Applied

None.

## Cross-Object Consistency Notes

- **CID**: Matches Dim_Customer.RealCID convention used across BI_DB_dbo tables.
- **FundingID**: Same meaning as Billing.Withdraw.FundingID — FK to Billing.Funding.
- **UpdateDate**: Standard ETL metadata column (GETDATE pattern).
