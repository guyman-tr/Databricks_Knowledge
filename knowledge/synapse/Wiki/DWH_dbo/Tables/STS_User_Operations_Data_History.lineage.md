# Column Lineage — DWH_dbo.STS_User_Operations_Data_History

## Production Source

| Property | Value |
|----------|-------|
| **Source Database** | STS_Audit |
| **Source Schema** | StsAudit |
| **Source Table** | UserOperations |
| **Staging Table** | DWH_staging.STS_Audit_UserOperationsData |
| **Writer SP** | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse |
| **Load Pattern** | Daily Append via Partition SWITCH |
| **Generic Pipeline** | ID 459 → `dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history` |

## Column Mapping

| # | DWH Column | Source Expression | Transform |
|---|-----------|-------------------|-----------|
| 1 | Gcid | STS_Audit_UserOperationsData.Gcid | Pass-through |
| 2 | RealCid | STS_Audit_UserOperationsData.RealCid | Pass-through |
| 3 | DemoCid | STS_Audit_UserOperationsData.DemoCid | Pass-through |
| 4 | ApplicationIdentifier | STS_Audit_UserOperationsData.ApplicationIdentifier | Pass-through |
| 5 | ApplicationVersion | STS_Audit_UserOperationsData.ApplicationVersion | Pass-through |
| 6 | ClientIp | STS_Audit_UserOperationsData.ClientIp | Pass-through |
| 7 | ClientName | STS_Audit_UserOperationsData.ClientName | Pass-through |
| 8 | CreatedAt | STS_Audit_UserOperationsData.CreatedAt | Pass-through |
| 9 | UserAgent | STS_Audit_UserOperationsData.UserAgent | Pass-through |
| 10 | AccessTokenHashed | STS_Audit_UserOperationsData.AccessTokenHashed | Pass-through |
| 11 | ClientDeviceId | STS_Audit_UserOperationsData.ClientDeviceId | Pass-through |
| 12 | ParentSessionId | STS_Audit_UserOperationsData.ParentSessionId | Pass-through |
| 13 | AccountTypeName | STS_Audit_UserOperationsData.AccountTypeName | Pass-through |
| 14 | LoginTypeName | STS_Audit_UserOperationsData.LoginTypeName | Pass-through |
| 15 | SessionId | STS_Audit_UserOperationsData.SessionId | Pass-through |
| 16 | GatewayAppId | STS_Audit_UserOperationsData.GatewayAppId | Pass-through |
| 17 | ProxyType | STS_Audit_UserOperationsData.ProxyType | Pass-through |
| 18 | CountryISOCode | STS_Audit_UserOperationsData.CountryISOCode | Pass-through |
| 19 | AdditionalData | STS_Audit_UserOperationsData.AdditionalData | Pass-through |
| 20 | DateID | `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))` | Computed from SP parameter |
| 21 | UpdateDate | `GETDATE()` | ETL load timestamp |

## Upstream Wiki

No upstream wiki available. Source table `STS_Audit.StsAudit.UserOperations` is not documented in DB_Schema.

## ETL Support Objects

| Object | Role |
|--------|------|
| DWH_dbo.STS_User_Operations_Data_History_SWITCH_SINGLE | Daily staging table (created/dropped each run) |
| DWH_dbo.STS_User_Operations_Data_History_SWITCH | Shadow table for partition swap (truncated each run) |
| DWH_dbo.SP_STS_User_Operations_Data_History_CREATE_SWITCH_SINGLE | Creates both SWITCH tables with matching schema |
| DWH_dbo.SP_STS_User_Operations_Data_History_SWITCH | Executes the 3-step partition swap |
