# BI_DB_dbo.BI_DB_US_Apex_Rejected_Accounts — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| DWH_dbo.Dim_Customer | Table | Primary — customer identity, regulation, verification, IsDepositor |
| DWH_dbo.Dim_PlayerStatus | Table | Player status name |
| DWH_dbo.Dim_PendingClosureStatus | Table | Pending closure status name |
| DWH_dbo.V_Liabilities | View | Customer liabilities on @DateID |
| BI_DB_dbo.External_USABroker_Apex_ApexData | External Table | Apex account ID and status |
| BI_DB_dbo.External_USABroker_Dictionary_ApexStatus | External Table | Apex status name lookup |
| BI_DB_dbo.External_USABroker_Apex_UserValidationErrors | External Table | Validation error mapping |
| BI_DB_dbo.External_USABroker_Dictionary_ApexValidationError | External Table | Validation error name |
| BI_DB_dbo.External_USABroker_Apex_State | External Table | Error date (BeginTime) |
| BI_DB_dbo.BI_DB_SF_Cases_Panel | Table | Open support ticket indicator |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| GCID | Dim_Customer | GCID | Passthrough |
| RealCID | Dim_Customer | RealCID | Passthrough |
| RegulationID | Dim_Customer | RegulationID | Passthrough (note: filter on DesignatedRegulationID=8, not RegulationID) |
| ApexID | External_USABroker_Apex_ApexData | ApexID | CASE WHEN NULL THEN 'No ApexAccount' ELSE ApexID |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | JOIN on StatusID |
| ValidationError | External_USABroker_Dictionary_ApexValidationError | Name | JOIN via UserValidationErrors.ApexValidationErrorID |
| ErrortDate | External_USABroker_Apex_State | BeginTime | CAST(BeginTime AS DATE) |
| UpdateDate | ETL | GETDATE() | Insert timestamp |
| TicketInd | BI_DB_SF_Cases_Panel | CID_Last | CASE WHEN EXISTS open non-email ticket THEN 'Yes' ELSE 'No' |
| Liabilities | V_Liabilities | Liabilities | Passthrough for @DateID |
| IsDepositor | Dim_Customer | IsDepositor | CASE WHEN 1 THEN 'Yes' ELSE 'No' |
| PendingClosureStatusName | Dim_PendingClosureStatus | PendingClosureStatusName | JOIN on PendingClosureStatusID |
| PlayerStatus | Dim_PlayerStatus | Name | JOIN on PlayerStatusID |
