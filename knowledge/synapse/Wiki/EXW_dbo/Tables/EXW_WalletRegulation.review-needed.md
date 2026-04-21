# EXW_WalletRegulation — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 2 Items (Derived — May Need Verification)

| # | Column | Description | Verification Needed |
|---|--------|-------------|---------------------|
| 1 | TypeID | Values 1–5 hardcoded in SP WHERE clause | Confirm if new regulatory entities (TypeID > 5) have been added to WalletDB since SP was written (2024-12-15); SP comment acknowledges "might be more types in the future" |
| 2 | FromDate | Defaults to '1900-01-01' via ISNULL | Confirm whether '1900-01-01' is treated as a sentinel for "unknown date" by downstream consumers, or if those rows should be filtered out |
| 3 | Occurred | MAX(Occurred) per GCID + TypeId + WalletRegulation group | Confirm this is the correct field to represent "when the regulation started" — distinct from MAX(DateOccurred) used for FromDate |

## Open Questions

- **Full DELETE with no rollback protection**: The SP deletes the entire table before inserting. If the SP fails mid-run, the table is empty. Is there a compensating control (e.g., an operational alert for zero-row state, or a staging swap pattern) in the orchestration layer?
- **No downstream SP consumers**: No SPs or views reference EXW_WalletRegulation in the SSDT repo. Is this table consumed via ad-hoc queries from BI tools (Power BI, Databricks)? If so, there may be hidden dependencies not captured here.
- **Only previous regulation kept (Rn=2)**: Users who have accepted 3+ regulations lose all intermediate history. Is this intentional? If full T&C history is needed for compliance audits, analysts must query WalletDB directly.
- **eToro DA and eToro SEY have very few rows**: TypeID=4 (eToro DA) has 870 rows and TypeID=5 (eToro SEY) has 60,581. Are these regulation types still active, or are they winding down?
- **GCID NOT NULL constraint**: This is the only EXW table with a DDL-level NOT NULL on GCID. Confirm whether this ever causes insertion failures for edge-case GCIDs (e.g., test users or migrated accounts).
- **UC Target**: Listed as `_Not_Migrated` — confirm whether regulatory tracking data should be in Unity Catalog for compliance self-service analytics.

## No Reviewer Corrections at Time of Generation
