# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_NameLists

## Tier 2 — All Columns SP-Derived

All 7 columns are Tier 2 (SP_CEPDailyAudit). No upstream wiki exists for the staging sources (`External_Etoro_CEP_NamedLists`, `External_Etoro_History_NamedLists`). The sibling CEPDailyAudit wikis in the bundle are co-written by the same SP but are not upstream sources for this table.

## Data Quality — LoginName Null-Byte Padding

Sampled `LoginName` values contain trailing `\0` (null-byte) characters, likely from fixed-width source fields. Example: `charilaosch` followed by ~117 null bytes. Consumers should apply `REPLACE(LoginName, CHAR(0), '')` or `RTRIM` when using this column for display or comparison.

## TypeOfChange Coverage

SP logic defines three possible values: `New Name List`, `Change In CIDs`, `Name List Deleted`. Current data (281 rows) shows only the first two. `Name List Deleted` has zero occurrences — either no lists have been deleted since Dec 2023, or the deletion path has a different behavior. No action needed but worth noting for completeness.

## Duplicate Rows

The sample shows what appear to be duplicate rows (same Date, NameListID, Name, TypeOfChange, LoginName, ChangeTime). This may be caused by the two UNION branches in `#NameLists_ChangesFinal` both producing rows when a list has temporal records on both `SysStartDate = @Date` and `SysEndDate = @Date`. Reviewer should verify whether this duplication is intentional or a minor SP logic issue.

## No Views

No views reference this table in the SSDT project. The sibling tables (Rules, CP, Conditions, CPToRule, ConditionToCP) have `V_*_Last180Days` views, but NameLists does not.
