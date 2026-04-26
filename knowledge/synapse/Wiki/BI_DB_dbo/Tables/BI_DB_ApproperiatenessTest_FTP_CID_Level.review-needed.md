# Review Needed: BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level

**Generated**: 2026-04-23 | **Batch**: 56 | **Reviewer**: Pending

## Tier 4 Items (Low Confidence — Needs Confirmation)

None — all columns are Tier 2 with direct SP code evidence.

## Open Questions

1. **UserInteractionTypeId=4 / UserInteractionId=22 semantics**: The SP hardcodes these filter values for the "appropriateness popup" interaction type. Confirm with ComplianceStateDB owners that TypeId=4 = appropriateness popup and Id=22 is the current active interaction ID. These values may change if the popup is redesigned.

2. **UserInteractionActionId=2 meaning**: The WHERE filter `cia.UserInteractionActionId = 2` determines what "shown the popup" means. Confirm whether ActionId=2 = "popup displayed" or "popup acknowledged/dismissed".

3. **FTP vs AT relationship**: "First Time Pass" (FTP, via SettingsDB ResourceId=5907) vs "Appropriateness Test" (AT) — confirm if these are the same process or different phases. 74.9% have HasCompletedFTP=1 but only 35.5% have ApproprietnessScore_Status='Passed'. This suggests FTP completion ≠ passing the AT.

4. **GCID vs RealCID**: ComplianceStateDB uses GCID while DWH uses RealCID. The JOIN via BI_DB_Scored_Appropriateness_Negative_Market resolves this. Confirm the GCID→RealCID mapping is 1:1 or if edge cases exist (e.g., merged accounts).

5. **SettingsDB ResourceId=5907 stability**: This hardcoded resource ID is the FTP completion marker. Confirm it hasn't changed since the SP was created (2024-01-31).

## Known Issues / Notes

- Table name typo: "Approperiateness" — the word "Appropriateness" is misspelled in the DDL. Cannot be changed without breaking the ETL pipeline.
- INNER JOIN to BI_DB_Scored_Appropriateness_Negative_Market means customers not present in that table are excluded — even if they have ComplianceStateDB records. This may undercount the true at-risk population.
- AT_Date 3% NULLs (~31,542 rows) are inherited from BI_DB_Scored_Appropriateness_Negative_Market — not a data quality issue specific to this table.

## Cross-Object Consistency Checks

| Column | Canonical Source | Check Status |
|--------|-----------------|-------------|
| ApproprietnessScore_Status | BI_DB_Scored_Appropriateness_Negative_Market | ✓ Description copied verbatim from sibling wiki |
| AT_Date | BI_DB_Scored_Appropriateness_Negative_Market | ✓ Description copied verbatim from sibling wiki |
| RealCID | DWH_dbo.Dim_Customer | ✓ Standard FK — consistent with other tables |
