# Column Lineage: BI_DB_dbo.BI_DB_QMMF_Report_Finance

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractionActionCounts | BI_DB_dbo | QMMF interaction base | UserInteractionActionId=14 only |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions | BI_DB_dbo | GCID source | CustomerInteractionId join |
| DWH_dbo.Dim_Customer | DWH_dbo | GCID→RealCID mapping | q.GCID = dc.GCID |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | CFD unrealized equity | bdppl.CID = dc.RealCID, IsSettled=0 |
| DWH_dbo.V_Liabilities | DWH_dbo | Credit balance | vl.CID = dc.RealCID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| GCID | External_ComplianceStateDB...CustomerInteractions | GCID | passthrough (UserInteractionActionId=14 filter) |
| DateID | (computed) | — | @DateID = YYYYMMDD integer from @Date |
| Date | (computed) | — | @Date SP parameter |
| UnrealizedEquity CFD | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) WHERE IsSettled=0. ISNULL → 0. |
| Credit | DWH_dbo.V_Liabilities | Credit | SUM(Credit). ISNULL → 0. |
| UpdateDate | (computed) | — | @Date parameter |

## Writer SP

- **SP**: `BI_DB_dbo.SP_QMMF_Report`
- **Pattern**: DELETE + INSERT by DateID = @DateID
- **Shared with**: BI_DB_QMMF_Report
