# Review Needed: BI_DB_dbo.BI_CLData_AllTimeData_Optimove

**Generated**: 2026-04-23
**Quality Score**: 6.5/10
**Status**: NEEDS REVIEW — empty table, 1 Tier 4 column, no writer SP

---

## Tier 4 Items (Require Verification)

| Column | Question | Priority |
|--------|----------|----------|
| Rounds | What does "Rounds" represent? It's typed as `date` — is this an Optimove campaign round end date, a billing round date, or something else entirely? | HIGH |

## Open Questions

1. **What populated this table?** No writer SP found in SSDT BI_DB_dbo. Was this fed by:
   - A scheduled Optimove export process running outside Synapse?
   - A Python/SSIS job calling an Optimove API?
   - A now-deleted SP?
   - The Marketing/CRM team directly?

2. **Why is the table empty?** Was the feeding process:
   - Discontinued when the Optimove CL program ended?
   - Migrated to a different Optimove integration approach?
   - Replaced by a Fivetran or similar connector?

3. **`Rounds` column**: The date-typed `Rounds` column has no clear meaning from column name analysis or context. What Optimove concept does "Rounds" represent?

4. **`PostiveTotalCLAmount` typo**: Column name `PostiveTotalCLAmount` is missing the second 'i' (should be "Positive"). Is this an intentional legacy name preserved from the upstream system, or a bug in the original DDL?

5. **Relationship to BI_DB_CreditLineData_Optimove**: Both tables are empty. Is `BI_CLData_AllTimeData_Optimove` an aggregated version of `BI_DB_CreditLineData_Optimove`, or do they come from different source processes?

6. **Was BI_DB_Daily_CreditLine the upstream source?** `SP_Daily_CreditLine` processes `Fact_CustomerAction WHERE ActionTypeID=9 AND BonusTypeID=71` → `BI_DB_Daily_CreditLine`. Did an SP then aggregate `BI_DB_Daily_CreditLine` into `BI_CLData_AllTimeData_Optimove`?

## Corrections

- If reviewer identifies the writer SP or source system, upgrade Tier 3 columns to Tier 2 and Tier 4 `Rounds` to the appropriate tier
- Quality score should be revised upward once source is confirmed and `Rounds` semantics are understood

## Reviewer Instructions

1. Check with the Marketing/CRM team or Optimove integration owners for the feeding process
2. Check if a deleted or archived SP existed (git history, old Synapse SP backup)
3. Confirm whether `Rounds` is an Optimove campaign concept or a eToro internal billing concept
4. Check git history for any SP that previously wrote to this table
