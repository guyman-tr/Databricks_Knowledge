# BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_German_Crypto_Transition_To_Tangany`

## Source Tables
| Source Table | Schema | Join/Usage |
|---|---|---|
| DWH_dbo.Dim_Customer | DWH_dbo | Population base — German users with TanganyID NOT NULL |
| BI_DB_dbo.External_UserApiDB_Dictionary_TanganyStatus | BI_DB_dbo (External) | TanganyStatus name lookup from UserApiDB |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions | BI_DB_dbo (External) | Interaction completion status for T&C (45), Selfie (46), Confirmation (47) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| TanganyID | DWH_dbo.Dim_Customer | TanganyID | Passthrough (WHERE TanganyID IS NOT NULL) |
| TanganyStatusID | DWH_dbo.Dim_Customer | TanganyStatusID | Passthrough |
| TanganyStatus | External_UserApiDB_Dictionary_TanganyStatus | Name | Passthrough via JOIN on TanganyStatusID |
| Is_TC | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId | ETL-computed: MAX(CASE WHEN UserInteractionId=45 THEN 1 ELSE 0) — Terms & Conditions interaction exists |
| Is_Active_TC | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=45 AND IsActive=1 THEN 1 ELSE 0) |
| Is_Completed_TC | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsCompleted, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=45 AND IsCompleted=1 AND IsActive=0 THEN 1 ELSE 0) |
| TC_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | ETL-computed: MAX(CASE WHEN UserInteractionId=45 THEN ISNULL(CompletedDate, '1900-01-01')) — sentinel 1900-01-01 = not completed |
| Is_Selfie_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId | ETL-computed: MAX(CASE WHEN UserInteractionId=46 THEN 1 ELSE 0) |
| Is_Active_Selfie_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=46 AND IsActive=1 THEN 1 ELSE 0) |
| Is_Completed_Selfie_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsCompleted, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=46 AND IsCompleted=1 AND IsActive=0 THEN 1 ELSE 0) |
| Selfie_Popup_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | ETL-computed: MAX(CASE WHEN UserInteractionId=46 THEN ISNULL(CompletedDate, '1900-01-01')) |
| Is_Confirmation_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId | ETL-computed: MAX(CASE WHEN UserInteractionId=47 THEN 1 ELSE 0) |
| Is_Active_Confirmation_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=47 AND IsActive=1 THEN 1 ELSE 0) |
| Is_Completed_Confirmation_Popup | External_ComplianceStateDB_Compliance_CustomerInteractions | UserInteractionId, IsCompleted, IsActive | ETL-computed: MAX(CASE WHEN UserInteractionId=47 AND IsCompleted=1 AND IsActive=0 THEN 1 ELSE 0) |
| Confirmation_Popup_LastCompletionDate | External_ComplianceStateDB_Compliance_CustomerInteractions | CompletedDate | ETL-computed: MAX(CASE WHEN UserInteractionId=47 THEN ISNULL(CompletedDate, '1900-01-01')) |
| UpdateDate | — | — | ETL metadata: GETDATE() |
