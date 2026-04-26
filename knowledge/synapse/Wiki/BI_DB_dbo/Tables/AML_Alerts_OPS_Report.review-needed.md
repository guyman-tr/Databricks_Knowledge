# Review Needed: BI_DB_dbo.AML_Alerts_OPS_Report

**Generated**: 2026-04-23
**Quality Score**: 7.0/10
**Status**: NEEDS REVIEW — unknown source, empty table

---

## Tier 4 Items (Require Verification)

All 11 data columns are Tier 4 (unknown source). The entire table needs source identification.

| Column | Question | Priority |
|--------|----------|----------|
| AlertIdentifier | What system generates this identifier? UUID format? Case management system ID? | HIGH |
| AlertType | What is the full enum of alert types? Same as BI_DB_AML_BI_Alerts_New.AlertType? | HIGH |
| AssignedNotHandled / AssignedAndHandled / NotAssigned | Are these mutually exclusive? Do they sum to total alerts? | MEDIUM |
| Assigned | Is this a user name, email, team name, or system ID? | MEDIUM |

## Open Questions

1. **What populated this table?** No writer SP found in SSDT BI_DB_dbo. Was this fed by:
   - An external AML case management tool (e.g., STS Compliance, Oracle)?
   - A manual SQL process from a BI analyst?
   - A now-deleted SP?
   - The AML OPS team directly?

2. **Why is the table empty?** Was the feeding process:
   - Migrated to another system?
   - Discontinued after the 2024-12-01 backup?
   - Temporarily suspended?

3. **Relationship to BI_DB_AML_BI_Alerts_New**: Is this a summarized/aggregated view of alerts from `BI_DB_AML_BI_Alerts_New`? The alert types look similar in naming convention.

4. **CID bigint → int change**: The backup had CID as bigint, the live table has int. Was this intentional? Does it risk overflow for large CID values?

5. **Schema prefix**: This table does NOT have the `BI_DB_` prefix unlike most BI_DB_dbo tables. Was it migrated from a different schema?

## Corrections

- If reviewer knows the source system, please update all Tier 4 descriptions to the appropriate tier
- Quality score should be revised upward once source is confirmed

## Reviewer Instructions

1. Check with the AML team (Pavlina Masoura or equivalent) for ownership of this table
2. Check if a feeding application or SP existed in a non-SSDT pipeline (e.g., old on-prem SQL Server)
3. Confirm if table is permanently decommissioned or expected to be re-populated
