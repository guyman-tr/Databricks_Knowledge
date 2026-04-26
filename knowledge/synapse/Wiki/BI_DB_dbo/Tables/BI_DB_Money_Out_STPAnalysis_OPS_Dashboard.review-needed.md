# BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard — Review Needed

## Tier 4 Items

None — all columns have Tier 1 or Tier 2 sources.

## Questions for Reviewer

1. **#FINAL dead code**: The SP creates a `#FINAL` temp table with PlayerLevel and Regulation enrichment (via Dim_Customer, Dim_PlayerLevel, Dim_Regulation), but the actual INSERT reads from `#billing`. Was the intent to include these columns? Should they be added to the target table?
2. **UserGroupID=2 for OPS**: The upstream BackOffice.WithdrawApproval wiki documents UserGroupID values 1=Admin, 3=Risk, 4=Marketing, 6=Trading. The SP uses UserGroupID=2 for OPS — this value is not in the wiki's known list. Verify this mapping is correct.
3. **UserGroupID=36 for AML**: Similarly, UserGroupID=36 is not documented in the upstream wiki. Verify this is the correct AML group identifier.
4. **Column name typo**: `AmdinistratorsApproved` — "Adm**in**istrators" is misspelled as "Amd**in**istrators". Baked into DDL; renaming would require ALTER TABLE + downstream coordination.
5. **Amount$Withdraw**: Dollar sign in column name requires bracket quoting in all queries. Consider whether this naming convention causes downstream issues.

## Corrections Applied

- Column count is 16 (not 15 as stated in batch assignment).

## Cross-Object Consistency

- WithdrawID, CID, RequestDate descriptions aligned with Billing.Withdraw upstream wiki.
- Amount$Withdraw, ModificationDate, WithdrawPaymentID descriptions aligned with Billing.WithdrawToFunding upstream wiki.
