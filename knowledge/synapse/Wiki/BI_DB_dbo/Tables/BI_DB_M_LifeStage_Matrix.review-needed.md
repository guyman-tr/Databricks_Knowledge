# Review Needed: BI_DB_dbo.BI_DB_M_LifeStage_Matrix

## Tier 4 Items (Needs Verification)

- None. All columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Column count discrepancy**: The batch assignment says 11 columns, but the DDL has 10 columns. Confirmed 10 from the SSDT repo DDL. The orchestrator may have counted incorrectly.
2. **Hardcoded fake reg exclusion**: The March 2024 Direct SubChannel filter is hardcoded. If similar fake registration events occur in the future, the SP would need manual update. Is there a more general detection mechanism planned?
3. **Delete scope**: The SP deletes WHERE ToMonthFull >= @ToMonth. This means re-running for a past month will also delete all subsequent months. Is this the intended behavior for backfill scenarios?
4. **Year from FromMonth**: The Year column uses the FromMonth's CalendarYear. For Dec→Jan transitions, Year=previous year. Is this the intended convention for the business users consuming this data?

## Cross-Object Consistency

- OpsDB dependencies: BI_DB_CID_LifeStageDefinition (Priority 0) and BI_DB_CIDFirstDates (Priority 90). This table depends on both being up-to-date.
- Life stage status values are consistent with BI_DB_CID_LifeStageDefinition domain.

## Corrections Applied

- Corrected column count from 11 (batch assignment) to 10 (actual DDL).
