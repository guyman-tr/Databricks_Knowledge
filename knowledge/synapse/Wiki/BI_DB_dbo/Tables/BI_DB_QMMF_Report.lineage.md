# Column Lineage: BI_DB_dbo.BI_DB_QMMF_Report

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts | BI_DB_dbo | Primary — interaction counts | cia.CustomerInteractionId = ci.CustomerInteractionId |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions | BI_DB_dbo | Customer interaction state | ci.UserInteractionId = ui.UserInteractionId |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_UserInteractionDetails | BI_DB_dbo | Interaction type filter | UserInteractionId=39, UserInteractionActionId IN (1,14,15) |
| DWH_dbo.Dim_Customer | DWH_dbo | GCID→RealCID mapping | q.GCID = dc1.GCID |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Customer snapshot at interaction date | dc1.RealCID = fsc.RealCID |
| DWH_dbo.Dim_Range | DWH_dbo | Date-range match | fsc.DateRangeID = dr.DateRangeID |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Club tier name | fsc.PlayerLevelID = dpl.PlayerLevelID |
| DWH_dbo.Dim_Country | DWH_dbo | Country name (used in enrichment) | fsc.CountryID = dc.CountryID |
| BI_DB_dbo.External_Interest_Trade_InterestConsent | BI_DB_dbo | Interest opt-in consent | GCID match, latest ValidFrom, ConsentStatusID=1 |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| GCID | External_ComplianceStateDB...CustomerInteractions | GCID | passthrough |
| Count_Clicks | External_ComplianceStateDB...CustomerInteractionActionCounts | Count | rename (Count → Count_Clicks) |
| FirstInteractionDate | External_ComplianceStateDB...CustomerInteractionActionCounts | FirstInteractionDate | passthrough |
| LastInteractionDate | External_ComplianceStateDB...CustomerInteractionActionCounts | LastInteractionDate | passthrough |
| UserInteractionActionId | External_ComplianceStateDB...CustomerInteractionActionCounts | UserInteractionActionId | passthrough (filtered: 1, 14, 15) |
| UserInteractionTypeId | External_ComplianceStateDB...UserInteractionDetails | UserInteractionTypeId | passthrough |
| UserInteractionId | External_ComplianceStateDB...UserInteractionDetails | UserInteractionId | passthrough (always 39) |
| CustomerInteractionId | External_ComplianceStateDB...CustomerInteractionActionCounts | CustomerInteractionId | passthrough |
| StateAdditionalData | External_ComplianceStateDB...CustomerInteractions | StateAdditionalData | passthrough |
| UpdateDate | (computed) | — | @Date parameter |
| Club | DWH_dbo.Dim_PlayerLevel | Name | dim-lookup via Fact_SnapshotCustomer at LastInteractionDate |
| InterestOnBalance_Opt_In | External_Interest_Trade_InterestConsent | ConsentStatusID | CASE: latest ConsentStatusID=1 → 1, else 0 |

## Writer SP

- **SP**: `BI_DB_dbo.SP_QMMF_Report`
- **Pattern**: DELETE + INSERT by LastInteractionDate = @Date
- **Shared with**: BI_DB_QMMF_Report_Finance
