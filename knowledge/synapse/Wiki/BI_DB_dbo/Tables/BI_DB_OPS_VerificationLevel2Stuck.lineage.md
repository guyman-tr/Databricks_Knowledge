# BI_DB_dbo.BI_DB_OPS_VerificationLevel2Stuck — Column Lineage

## Writer SP
`BI_DB_dbo.SP_OPS_VerificationLevel2Stuck` — daily TRUNCATE+INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary — customer demographics, verification, compliance |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | VerificationLevel2Date |
| DWH_dbo.Dim_Country | DWH_dbo | Country name |
| DWH_dbo.Dim_PhoneVerified | DWH_dbo | PhoneVerifiedName |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | PlayerStatus name |
| DWH_dbo.Dim_EvMatchStatus | DWH_dbo | EvMatchStatusName |
| DWH_dbo.Dim_DocumentStatus | DWH_dbo | DocumentStatusName |
| DWH_dbo.Dim_Regulation | DWH_dbo | DesignatedRegulation and Regulation (two joins) |
| External_ScreeningService_Screening_UserScreening | BI_DB_dbo | Screening status source |
| External_ScreeningService_Dictionary_ScreeningStatus | BI_DB_dbo | ScreeningStatus name |
| External_ComplianceStateDB_Compliance_KycFlow | BI_DB_dbo | KYCFlowTypeID |
| External_ComplianceStateDB_Dictionary_KYCFlowType | BI_DB_dbo | KYCFlow ShortName |
| External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | POA/POI/SSN/Selfie documents |
| External_etoro_BackOffice_CustomerDocumentToDocumentType | BI_DB_dbo | Document type classification |
| BI_DB_dbo.BI_DB_RiskAlertManagementTool | BI_DB_dbo | Active risk alerts |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | rename |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough |
| RegistrationDate | DWH_dbo.Dim_Customer | RegisteredReal | CAST to date |
| VerificationLevel2Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | passthrough |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | dim-lookup via DesignatedRegulationID |
| KYCFLow | External_ComplianceStateDB_Dictionary_KYCFlowType | ShortName | dim-lookup via GCID → KycFlow → KYCFlowTypeID |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup via CountryID |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough (always 2) |
| Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | dim-lookup via EvMatchStatus |
| ScreeningStatus | External_ScreeningService_Dictionary_ScreeningStatus | Name | lookup via UserScreening.ScreeningStatusID |
| ScreeningStatusCheck | (computed) | — | CASE WHEN ScreeningStatus = 'NoMatch' THEN 1 ELSE 0 |
| EmailVerifiedCheck | DWH_dbo.Dim_Customer | IsEmailVerified | CASE WHEN IsEmailVerified=1 THEN 1 ELSE 0 |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | dim-lookup via PhoneVerifiedID |
| IsEmailVerified | DWH_dbo.Dim_Customer | IsEmailVerified | passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | dim-lookup via PlayerStatusID |
| DocumentStatusName | DWH_dbo.Dim_DocumentStatus | DocumentStatusName | dim-lookup via DocumentStatusID |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup via RegulationID (different from DesignatedRegulation) |
| EVorDocsVerified | (computed) | — | 1 if EV=Verified OR (valid non-expired POI AND valid non-expired POA) |
| NoActiveAlertsCheck | (computed) | — | 1 if no active HighRisk/KYC/CreditCard/Funding alerts; 0 if active alerts exist |
| SelfieCheck | (computed) | — | 1 if customer has DocumentTypeID IN (18=SelfieLiveliness, 23=SelfieMotion); 0 otherwise |
| ElderlyCheck | (computed) | — | 1 if (US AND Age>=60) OR (non-US AND Age>=70); 0 otherwise |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
