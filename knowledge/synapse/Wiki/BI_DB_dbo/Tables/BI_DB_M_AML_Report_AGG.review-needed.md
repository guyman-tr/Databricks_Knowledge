# Review Needed — BI_DB_dbo.BI_DB_M_AML_Report_AGG

Generated: 2026-04-22 | Batch: 29

## Tier 4 / Unresolved Items

| Column | Issue | Action Needed |
|--------|-------|---------------|
| CID | Holds COUNT(CID) from #agg_table — customer count per group, not a customer ID. Column name is misleading. | Reviewer: confirm this column naming is intentional and downstream consumers are aware CID = count. |
| AML_Sub_Entity | Used as GROUP BY key (multi-value CSV string). "eToro_Gibraltar, eToro_Money_UK" and "eToro_Money_UK, eToro_Gibraltar" would be separate groups if string order varies. | Reviewer: confirm STRING_AGG in SP_AML_SubEntity_Categorization produces consistent ordering, so CSV strings always sort the same way. |

## Known Data Quality Issues

All data quality issues inherited from BI_DB_M_AML_Report apply:
1. **Is_Active 3/12-month discrepancy**: SP comment says 3 months; code uses 12 months.
2. **Wire Threshold $150K hardcoded**: Not configurable without SP change.
3. **RiskGroup = Country Risk**: Column name may suggest customer risk; it is country-level.
4. **Is_EEA_EU_Country Hardcoded**: 37-country list embedded in SP.
5. **AML_Sub_Entity Historical Drift**: Reflects current daily sub-entity, not historical EOM state.

## Open Questions

- Is there any downstream report that treats `CID` in M_AML_Report_AGG as a customer ID rather than a count? This would be a data quality bug.
- Is `AML_Sub_Entity` as a GROUP BY key the intended design for aggregation? Multi-value CSV strings as group keys make it difficult to aggregate at the sub-entity level without the LIKE pattern.

## Upstream Wiki Coverage

| Source | Wiki Exists? | Tier 1 Columns Inherited |
|--------|-------------|--------------------------|
| Dictionary.Country | Yes (via Dim_Country.md) | Country, RiskGroup |
| BackOffice.Customer | Yes (via Dim_Customer.md) | HasWallet, VerificationLevelID |
| BI_DB_M_AML_Report | Yes (Batch 29, this run) | All business logic and caveats |
