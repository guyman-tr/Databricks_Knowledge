# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

## Tier Coverage

- **Tier 1**: 0 columns — no upstream production wikis exist for the staging source tables (`External_Etoro_CEP_CompoundPropertyToRule`, `External_Etoro_History_CompoundPropertyToRule`). All columns are ETL-derived or passthrough from unresolved staging sources.
- **Tier 2**: 11 columns — all grounded in SP_CEPDailyAudit code.
- **Tier 3**: 0
- **Tier 4**: 0

## Items for Human Review

1. **UpdateDate (column 11)**: Assigned Tier 2 based on `GETDATE()` pattern visible in SP code. Sibling CEPDailyAudit tables mark this as Tier 4. The SP code clearly shows `GETDATE()` as the source, so Tier 2 is defensible, but flagging for consistency review across the family.

2. **LoginName trailing NULL bytes**: Live data sample shows `LoginName` values padded with `\u0000` characters (e.g., `charilaosch` followed by ~100 null bytes). This appears to be a source-system artifact from the CEP temporal tables. Consider whether downstream consumers need RTRIM/REPLACE handling.

3. **No production wiki coverage**: All 6 staging source tables are unresolved in the upstream bundle (no wikis exist). This means 0 Tier 1 columns — acceptable given that CEP is an internal eToro system with no documented production DB_Schema wikis. If CEP wikis are created in the future, this object should be regenerated to inherit Tier 1 descriptions.

4. **Fan-out row multiplication**: The LEFT JOIN to `#Dim_CPtoRule` can produce multiple rows per CP event. The wiki documents this behavior, but analysts unfamiliar with the pattern may interpret duplicates as data quality issues. Consider adding a note to the table's query advisory in any analyst-facing documentation.

## No Section 4 Elements Here

The Elements table is in the main wiki file (`Dealing_CEPDailyAudit_CPToRule.md`), not in this sidecar.
