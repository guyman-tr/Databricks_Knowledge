# BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation — Column Lineage

## Writer SP
`BI_DB_dbo.SP_US_Customer_Acount_Reconcilation` — daily DELETE @Date + INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| External_USABroker_Apex_ApexData | External | Apex account identifiers |
| External_USABroker_Apex_UserData | External | Apex CID + approval date |
| External_USABroker_Dictionary_ApexStatus | External | Apex status name lookup |
| DWH_dbo.Dim_Customer | DWH_dbo | eToro customer data (RealCID, VerificationLevelID) |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup |
| DWH_dbo.Dim_AccountStatus | DWH_dbo | Account status name lookup |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | (parameter) | @Date | passthrough |
| ApexID | External_USABroker_Apex_ApexData | ApexID | passthrough |
| ApexCID | External_USABroker_Apex_UserData | CID | passthrough |
| ApexApprovedDate | External_USABroker_Apex_UserData | ApprovedByDate | rename |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | dim-lookup via StatusID |
| ReconStatus | (computed) | — | CASE: 'Missing In Apex Side' / 'Missing In eToro Side' / 'Check' |
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough (NULL for Apex-only records) |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough via COALESCE(RealCID, ApexCID) join |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup via RegulationID |
| EtoroAcountStatus | DWH_dbo.Dim_AccountStatus | AccountStatusName | dim-lookup via AccountStatusID |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
