# Lineage: BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level

**Generated**: 2026-04-23
**Writer SP**: `SP_BI_DB_ApproperiatenessTest_FTP_CID_Level`
**Load Pattern**: TRUNCATE + INSERT (daily full refresh)
**UC Target**: `_Not_Migrated`

## ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerInteractionActionCounts (Bronze lake)
  └── External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts
        |
ComplianceStateDB.Compliance.CustomerInteractions (Bronze lake)
  └── External_ComplianceStateDB_Compliance_CustomerInteractions
        |
ComplianceStateDB.Compliance.UserInteractionDetails (Bronze lake, filtered: TypeId=4, Id=22)
  └── External_ComplianceStateDB_Compliance_UserInteractionDetails
        |
SettingsDB.Settings.CustomerData (Bronze lake, filtered: ResourceId=5907, SelectedValue='2')
  └── External_SettingsDB_Settings_CustomerData
        |
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (JOIN for AT_Date, ApproprietnessScore_Status)
        |
        v
SP_BI_DB_ApproperiatenessTest_FTP_CID_Level (TRUNCATE + INSERT)
        |
        v
BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level (1,052,545 rows)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | ComplianceStateDB.Compliance.CustomerInteractions | GCID | passthrough | Tier 2 |
| 2 | RealCID | BI_DB_Scored_Appropriateness_Negative_Market | RealCID | passthrough via JOIN on GCID | Tier 2 |
| 3 | PopUpsCount | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | Count | passthrough (aliased) | Tier 2 |
| 4 | FirstInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | FirstInteractionDate | passthrough | Tier 2 |
| 5 | LastInteractionDate | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | LastInteractionDate | passthrough | Tier 2 |
| 6 | HasCompletedFTP | SettingsDB.Settings.CustomerData | Gcid | computed: CASE WHEN cd.Gcid IS NULL THEN 0 ELSE 1 END | Tier 2 |
| 7 | CompletionFTPDate | SettingsDB.Settings.CustomerData | BeginDate | passthrough (aliased) | Tier 2 |
| 8 | DaysFromFirstToLast | ComplianceStateDB.Compliance.CustomerInteractionActionCounts | FirstInteractionDate, LastInteractionDate | computed: DATEDIFF(DAY, First, Last) | Tier 2 |
| 9 | ApproprietnessScore_Status | BI_DB_Scored_Appropriateness_Negative_Market | ApproprietnessScore_Status | passthrough via JOIN | Tier 2 |
| 10 | AT_Date | BI_DB_Scored_Appropriateness_Negative_Market | AT_Date | passthrough via JOIN | Tier 2 |
| 11 | UpdateDate | ETL pipeline | — | GETDATE() at INSERT time | Propagation |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| ComplianceStateDB.Compliance.CustomerInteractionActionCounts | External Table | Primary — interaction counts and dates |
| ComplianceStateDB.Compliance.CustomerInteractions | External Table | Join anchor — maps GCID |
| ComplianceStateDB.Compliance.UserInteractionDetails | External Table | Filter: TypeId=4 (appropriateness popup), Id=22 |
| SettingsDB.Settings.CustomerData | External Table | FTP completion gate (ResourceId=5907, SelectedValue='2') |
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Table | RealCID, AT_Date, ApproprietnessScore_Status |

## Notes

- `HasCompletedFTP` is derived: 1 if the customer's GCID appears in SettingsDB.Settings.CustomerData with ResourceId=5907 and SelectedValue='2' (FTP completion marker)
- `CompletionFTPDate` is NULL when HasCompletedFTP=0 (264,643 rows)
- `ApproprietnessScore_Status` and `AT_Date` relay from BI_DB_Scored_Appropriateness_Negative_Market; descriptions must match that wiki
- `UserInteractionActionId=2` filter in WHERE clause limits to specific action type
- No upstream wiki available for ComplianceStateDB or SettingsDB (both uncovered in routing)
