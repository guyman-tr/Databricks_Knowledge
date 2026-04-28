# Review Needed: DWH_dbo.Dim_ContactType

## Summary

Dim_ContactType is a **dormant dimension table** with 0 rows and no identifiable ETL process. All 6 columns are Tier 3 (DDL-grounded, no upstream wiki or SP code available). This table requires human review to determine whether it should be retained or deprecated.

## Open Questions

1. **Is this table still needed?** No stored procedure populates it, no downstream object reads from it, and it has 0 rows. Consider deprecation.
2. **What was the intended production source?** The naming pattern (`Dim_ContactType`) suggests a dictionary/lookup from a CRM or contact management system, but no mapping exists in the generic pipeline or SSDT SP code.
3. **Should ContactTypeID map to a production dictionary?** If a `Dictionary.ContactType` or similar exists in a production database, a writer SP and pipeline mapping should be created.
4. **InsertDate is nullable** — most DWH dimension tables enforce NOT NULL on InsertDate. Was this intentional?

## Tier 3 Columns Requiring Upstream Verification

| Column | Current Tier | Action Needed |
|--------|-------------|---------------|
| ContactTypeID | Tier 3 | Identify production source table and column |
| Name | Tier 3 | Identify production source table and column |
| DWHContactTypeID | Tier 3 | Confirm surrogate key assignment mechanism |
| UpdateDate | Tier 3 | Standard ETL audit — low priority |
| InsertDate | Tier 3 | Standard ETL audit — low priority |
| StatusID | Tier 3 | Standard soft-delete — low priority |

---

*Generated: 2026-04-27 | Object: DWH_dbo.Dim_ContactType | Status: Dormant — all columns Tier 3*
