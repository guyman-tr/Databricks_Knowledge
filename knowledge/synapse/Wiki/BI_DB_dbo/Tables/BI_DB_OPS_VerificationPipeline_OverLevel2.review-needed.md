# BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2 — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **Column count mismatch**: Batch assignment said 15 columns but DDL has 18. The DDL is authoritative.
2. **NULL Category rows**: ~3.8K rows have NULL Category — these fall through all CASE branches. Are these edge cases that need a new category?
3. **RiskAlerts as varchar**: The column is varchar(max) but stores '0' or '1'. Is this intentional or should it be int?
4. **5-month window**: The SP computes `@FiveMonthsAgo = DATEADD(MONTH, -5, FirstDayOfMonth)`. Is this window sufficient for compliance reporting?
5. **NOLOCK usage**: SP uses WITH(NOLOCK) on Dim_Customer which is unnecessary on Synapse (snapshot isolation). Cosmetic issue only.

## Corrections Applied

- Column count corrected from 15 (batch assignment) to 18 (actual DDL)

## Tier Summary

- **Tier 1 (7 columns)**: RealCID, VerificationLevelID, Country, PhoneVerifiedName, IsEmailVerified, RegisteredReal, Regulation
- **Tier 2 (11 columns)**: EvMatchStatusName, Uploaded 2 Docs, Uploaded POI only, Uploaded POA only, TotalHits, IsManual, DDCategoryVL2toVL3, ScreeningStatus, Category, RiskAlerts, UpdateDate
