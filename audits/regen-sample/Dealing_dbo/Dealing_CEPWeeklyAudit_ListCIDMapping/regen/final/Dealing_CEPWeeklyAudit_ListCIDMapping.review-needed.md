# Review Needed: Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

## Tier 2 Items (SP-derived, no upstream wiki for staging externals)

All 8 non-metadata columns are Tier 2. The upstream sources (`Dealing_staging.External_Etoro_CEP_ListCIDMappings`, `External_Etoro_History_ListCIDMappings`) are external/staging tables with no wiki documentation available. Column descriptions are grounded entirely in `SP_W_CEPWeeklyAudit` code analysis.

## Items for Human Review

1. **LoginName population (~92% NULL)**: Confirm whether `AppLoginName` is expected to be largely unpopulated for CID membership changes in the source system, or whether this indicates a data quality issue. The sibling `Dealing_CEPWeeklyAudit_NameLists` wiki notes a similar pattern.

2. **ListName reflects latest version**: The SP joins to `#NameLists_Log WHERE RN_desc = 1` for list name resolution. If a Named List was renamed, all historical CID mapping rows will show the **current** name, not the name at the time of the CID change. Confirm whether this is acceptable for audit reporting or whether historical name preservation is needed.

3. **No daily counterpart identified**: Unlike most CEP weekly audit tables (Rules, CP, Conditions, ConditionToCP, CPToRule, NameLists), there is no corresponding `Dealing_CEPDailyAudit_ListCIDMapping` table in the bundle. Confirm whether CID-level mapping changes are tracked at daily granularity elsewhere, or whether this weekly table is the only audit trail for CID membership.

4. **Relationship to NameLists JOIN defect**: The `Dealing_CEPWeeklyAudit_NameLists` wiki documents a suspected JOIN bug at SP line ~878 (`fdtd.ToDate = fdtd.ToDate` self-join). The ListCIDMapping INSERT (later in the SP) uses the correct join pattern (`fdtd.FromDate = #ListCIDMapping_ChangesFinal.FromDate AND fdtd.ToDate = #ListCIDMapping_ChangesFinal.ToDate`). This table does NOT share the suspected defect.

## Data Quality Observations

- 113/1,057 rows (~11%) are no-change placeholders (NULL TypeOfChange) — structural, not a quality issue
- 32 distinct NameListID values observed; list names suggest a mix of abuser lists, client segment lists, and product-specific lists
- CID is `bigint` type, consistent with customer ID conventions across the platform
