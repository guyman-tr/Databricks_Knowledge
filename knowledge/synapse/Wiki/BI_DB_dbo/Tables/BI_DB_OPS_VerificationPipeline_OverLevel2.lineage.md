# BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2 — Column Lineage

## Writer SP
`BI_DB_dbo.SP_OPS_VerificationPipeline_Level2` — daily TRUNCATE+INSERT

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary — customer demographics, VL, compliance |
| general.etoro_History_BackOfficeCustomer | general | VL change history for DDCategoryVL2toVL3 |
| DWH_dbo.Dim_Country | DWH_dbo | Country name |
| DWH_dbo.Dim_EvMatchStatus | DWH_dbo | EvMatchStatusName |
| DWH_dbo.Dim_PhoneVerified | DWH_dbo | PhoneVerifiedName |
| DWH_dbo.Dim_ScreeningStatus | DWH_dbo | ScreeningStatus |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name |
| External_ScreeningService_Screening_UserScreening | BI_DB_dbo | Screening data + TotalHits |
| External_ScreeningService_Screening_ProviderScreening | BI_DB_dbo | TotalHits, IsMainProvider |
| External_ScreeningService_Screening_ManagerResolvedCasesAudit | BI_DB_dbo | IsManual resolution |
| External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | Document uploads (POI/POA/SSN/Selfie) |
| External_etoro_BackOffice_CustomerDocumentToDocumentType | BI_DB_dbo | Document type classification |
| External_ComplianceStateDB_Compliance_KycFlow | BI_DB_dbo | KYC flow (unused in final output) |
| External_UserApiDB_Ev_CustomerResult | BI_DB_dbo | EV provider transactions |
| BI_DB_dbo.BI_DB_RiskAlertManagementTool | BI_DB_dbo | Risk alerts (Relations, HighRiskLogin) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | dim-lookup via EvMatchStatus |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough (2 or 3) |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup via CountryID |
| Uploaded 2 Docs | (computed) | — | 1 if both POI and POA docs uploaded in window |
| Uploaded POI only | (computed) | — | 1 if only POI uploaded |
| Uploaded POA only | (computed) | — | 1 if only POA uploaded |
| TotalHits | External_ScreeningService_Screening_ProviderScreening | TotalHits | from main provider screening |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | dim-lookup via PhoneVerifiedID |
| IsEmailVerified | DWH_dbo.Dim_Customer | IsEmailVerified | passthrough |
| IsManual | (computed) | — | MAX(CASE WHEN ProviderUsername <> 'devteam-compliance-ops@etoro.com' THEN 1 ELSE 0) |
| DDCategoryVL2toVL3 | (computed) | — | Time bucket for VL2→VL3 transition (from History_BackOfficeCustomer) |
| ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | dim-lookup via ScreeningStatusID |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough |
| Category | (computed) | — | Complex CASE classification based on EV status, VL, docs, hits, phone, email, alerts |
| Regulation | DWH_dbo.Dim_Regulation | Name | dim-lookup via RegulationID |
| RiskAlerts | (computed) | — | 1 if customer has Relations or HighRiskLogin alerts |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
