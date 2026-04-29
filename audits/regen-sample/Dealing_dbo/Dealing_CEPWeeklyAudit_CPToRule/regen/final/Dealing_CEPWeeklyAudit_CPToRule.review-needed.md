# Review Needed: Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule

## Tier 4 Items

| Column | Current Tier | Question |
|--------|-------------|----------|
| UpdateDate | Tier 4 | Standard `GETDATE()` ETL metadata pattern — consistent with all sibling weekly audit tables. No action needed unless SP is updated. |

## Data Quality Observations

1. **LoginName NULL rate (~54%)**: `AppLoginName` is NULL in roughly 31,383 of 58,192 event rows. This is significantly higher than some sibling tables. It may reflect that older temporal history rows in `External_Etoro_History_CompoundPropertyToRule` did not capture `AppLoginName`. Confirm whether this is expected or a data gap worth investigating.

2. **LoginName padding with null bytes**: Live sample shows `LoginName` values padded with null characters (e.g., `jasonha\0\0\0...`). This appears to be a `varchar(max)` storage artifact from the source system. Consumers should `RTRIM` or strip null characters when displaying.

3. **RuleName / HedgeServerID dimension join**: The INSERT uses `LEFT JOIN #Dim_CPtoRule ON rcf.CompoundPropertyID = dcr.CompoundPropertyID`, which resolves rule context by CP. If a CP is mapped to multiple rules, this join can produce **multiple resolved rule contexts**, but `RuleID` is explicitly taken from `rcf` (the change event). Verify that the `RuleID` from the event always matches the `RuleID` resolved through `#Dim_CPtoRule` — a mismatch would mean `RuleName` and `HedgeServerID` refer to a different rule than `RuleID`.

4. **Very few placeholder rows (56)**: Unlike sibling tables (`Dealing_CEPWeeklyAudit_Rules` has ~1,914 rows including many placeholders), this table has 58,248 rows with only 56 placeholders. The high event volume is expected given that CP-to-rule mappings are bulk-managed (many CPs per rule).

## No Upstream Production Wikis

The staging source tables (`External_Etoro_CEP_CompoundPropertyToRule`, `External_Etoro_History_CompoundPropertyToRule`) are unresolved external tables with no wiki documentation. All column descriptions are Tier 2 (from SP code analysis). This is expected for staging/external tables.
