# Lineage: BI_DB_dbo.BI_DB_AMLPeriodicReview_PostReview

**Writer SP**: SP_BI_DB_AMLPeriodicReview_PostReview  
**Load Pattern**: UPSERT — DELETE WHERE RealCID IN (#finalreportwithdelta) + INSERT  
**Frequency**: Daily  
**Parameter**: `@Date DATE`

---

## Source Tables

| Source | Role | Columns Used |
|--------|------|--------------|
| `BI_DB_dbo.BI_DB_AMLPeriodicReview` | Primary input — latest review snapshot per RealCID (ROW_NUMBER DESC on Review_Due_DateID) | All columns; delta comparison at review time |
| `DWH_dbo.Dim_Customer` | Customer master | RealCID, FirstDepositDate, CountryID, POBCountryID, CitizenshipCountryID, ScreeningStatusID, PhoneVerifiedID, EvMatchStatus, RiskClassificationID, PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID, PlayerLevelID, RegulationID, VerificationLevelID, IsIDProofExpiryDate, GCID |
| `DWH_dbo.Dim_Country` (×3) | Country decode | Name, RiskGroupID — joined for KYC, POB, and Citizenship country IDs |
| `DWH_dbo.Dim_ScreeningStatus` | Screening label | Name |
| `DWH_dbo.Dim_PhoneVerified` | Phone label | PhoneVerifiedName |
| `DWH_dbo.Dim_EvMatchStatus` | EV status label | EvMatchStatusName |
| `DWH_dbo.Dim_RiskClassification` | Risk label | RiskClassificationName |
| `DWH_dbo.Dim_PlayerStatus` | Account status label | Name |
| `DWH_dbo.Dim_PlayerStatusReasons` | Status reason label | Name |
| `DWH_dbo.Dim_PlayerStatusSubReasons` | Status sub-reason label | PlayerStatusSubReasonName |
| `DWH_dbo.Dim_PlayerLevel` | Club/loyalty tier label | Name |
| `DWH_dbo.Dim_Regulation` | Regulation label | Name |
| `DWH_dbo.Fact_BillingDeposit` | Deposit aggregations | AmountUSD, ModificationDateID, PaymentStatusID=2 (approved only) |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | EV date | EvMatchStatusDate |
| `BI_DB_dbo.BI_DB_KYC_Panel` | Economic profile answers | KYC_LastUpdateDate, Q10/Q11/Q14/Q15/Q18 answer texts |
| `BI_DB_dbo.BI_DB_RiskAlertManagementTool` | Post-review risk alerts | AlertType, StatusReason, AlertStatusReason, StatusType, ModificationDate (filtered: > Review_Due_Date) |
| `BI_DB_dbo.BI_DB_AML_BI_Alerts_New` | Post-review BI AML alerts | AlertType, AlertDate (filtered: > Review_Due_Date) |
| `BI_DB_dbo.External_etoro_BackOffice_CustomerDocument` | Document records | CID, DocumentID, IssueDate |
| `BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType` | Document-type join | DocumentID, DocumentTypeID, DocumentClassificationID |
| `BI_DB_dbo.External_etoro_Dictionary_DocumentType` | Document type dict | DocumentTypeID |
| `BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField` | TIN/tax country | GCID, FieldId=6, CountryId, LastModified |
| `BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType` | TIN type label | ValueTypeID, Name |
| `BI_DB_dbo.External_ScreeningService_Screening_UserScreening` | Screening date | CID, LastUpdateDate |
| `BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions` | APU gap interactions | GCID, DisplayName, CompletedDate, LastEvaluationData (filtered: > Review_Due_Date) |

---

## Column-Level Lineage

| Column | Source | Derivation |
|--------|--------|------------|
| RealCID | Dim_Customer | Passthrough |
| FirstDepositDate | Dim_Customer | Passthrough |
| KYC_Country_ID | Dim_Customer.CountryID | Alias |
| POBCountryID | Dim_Customer.POBCountryID | Passthrough |
| CitizenshipCountryID | Dim_Customer.CitizenshipCountryID | Passthrough |
| KYC_Country | Dim_Country.Name | JOIN on CountryID |
| POBCountry | Dim_Country.Name | JOIN on POBCountryID |
| CitizenshipCountry | Dim_Country.Name | JOIN on CitizenshipCountryID |
| KYC_Country_Rank | Dim_Country.RiskGroupID | JOIN on CountryID |
| POBCountry_Rank | Dim_Country.RiskGroupID | JOIN on POBCountryID |
| CitizenshipCountry_Rank | Dim_Country.RiskGroupID | JOIN on CitizenshipCountryID |
| ScreeningStatus | Dim_ScreeningStatus.Name | JOIN on ScreeningStatusID |
| PhoneVerified | Dim_PhoneVerified.PhoneVerifiedName | JOIN on PhoneVerifiedID |
| EvMatchStatusName | Dim_EvMatchStatus.EvMatchStatusName | JOIN on EvMatchStatus |
| RiskClassificationName | Dim_RiskClassification.RiskClassificationName | JOIN on RiskClassificationID |
| VerificationLevelID | Dim_Customer.VerificationLevelID | Passthrough |
| PlayerStatus | Dim_PlayerStatus.Name | JOIN on PlayerStatusID |
| PlayerStatusReason | Dim_PlayerStatusReasons.Name | JOIN on PlayerStatusReasonID |
| PlayerStatusSubReason | Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName | JOIN on PlayerStatusSubReasonID |
| Club | Dim_PlayerLevel.Name | JOIN on PlayerLevelID |
| Regulation | Dim_Regulation.Name | JOIN on RegulationID |
| POI_ExpiryDate | Dim_Customer.IsIDProofExpiryDate | Alias |
| POA_ExpiryDate | External_CustomerDocument.IssueDate | MAX(IssueDate) WHERE DocumentTypeID=1 — stores IssueDate despite name |
| Is_POI_Expired | Computed | 1 if POI_ExpiryDate < GETDATE() |
| Is_POA_Expired | Computed | 1 if docs.IssueDate < DATEADD(YEAR,-1,GETDATE()) |
| POI_IsMissing | Computed | 1 if POI_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL |
| POA_IsMissing | Computed | 1 if POA_ExpiryDate IS NULL AND EvMatchStatusDate IS NULL |
| TaxCountry | External_ExtendedUserField (FieldId=6) | Up to 3 TIN country names, comma-separated |
| TaxCountryDiscrepancy | Computed | 1 if any TIN country ≠ KYC_Country |
| EVStatus | Dim_EvMatchStatus.EvMatchStatusName | Duplicate of EvMatchStatusName |
| SOFProvided | External_CustomerDocument | 1 if DocumentTypeID IN (7,8) with qualifying classification; else 0 |
| LastEVDate | BI_DB_CIDFirstDates.EvMatchStatusDate | Passthrough |
| EVReviewPending | Computed | CASE on EvMatchStatusDate age vs RiskClassificationName |
| KYC_LastUpdateDate | BI_DB_KYC_Panel.KYC_LastUpdateDate | MAX |
| EconomicProfileReviewPending | Computed | CASE on KYC_LastUpdateDate age vs RiskClassificationName |
| TotalDepositsLifetime | Fact_BillingDeposit.AmountUSD | SUM where ModificationDateID <= @DateID |
| TotalDepositsCurrentYear | Fact_BillingDeposit.AmountUSD | SUM where ModificationDateID >= @StartDateCurrYear |
| TotalDeposits12Months | Fact_BillingDeposit.AmountUSD | SUM where ModificationDateID >= @Date12MID |
| TotalDeposits6Months | Fact_BillingDeposit.AmountUSD | SUM where ModificationDateID >= @Date6MID |
| LastEPUpdateDate | BI_DB_KYC_Panel.KYC_LastUpdateDate | Duplicate of KYC_LastUpdateDate |
| CheckAlertSummary | BI_DB_AMLPeriodicReview | Passthrough from review-time snapshot |
| TotalCheckAlerts | BI_DB_AMLPeriodicReview | Passthrough from review-time snapshot |
| CheckAlertSummaryPostReview | Computed | 8-item checklist built from current-state fields |
| TotalCheckAlertsPostReview | Computed | SUM of 8 binary check flags |
| RiskAlertSummary | BI_DB_RiskAlertManagementTool | STRING_AGG of alerts after Review_Due_Date |
| LatestRiskAlertDateReview | BI_DB_RiskAlertManagementTool | MAX(ModificationDate) after Review_Due_Date |
| BIAMLAlerts | BI_DB_AML_BI_Alerts_New | STRING_AGG of alerts after Review_Due_Date |
| LatestBIAlertDate | BI_DB_AML_BI_Alerts_New | MAX(AlertDate) all-time |
| APU_Gaps_Summary | External_ComplianceStateDB_CustomerInteractions | STRING_AGG of interactions after Review_Due_Date |
| Review_Due_Date | BI_DB_AMLPeriodicReview | MAX(Review_Due_DateID) converted to date |
| Review_Due_DateID | BI_DB_AMLPeriodicReview | MAX per RealCID |
| POI_Expired_StatusChange | Computed (delta) | CASE: review.Is_POI_Expired vs post.Is_POI_Expired |
| POA_Expired_StatusChange | Computed (delta) | CASE: review.Is_POA_Expired vs post.Is_POA_Expired |
| POA_Updated_StatusChange | Computed (delta) | 'POA was not updated' if POA unchanged + CheckAlertSummary has POA item |
| POI_Missing_StatusChange | Computed (delta) | CASE: review.POI_IsMissing vs post.POI_IsMissing |
| POA_Missing_StatusChange | Computed (delta) | CASE: review.POA_IsMissing vs post.POA_IsMissing |
| EV_StatusChange | Computed (delta) | CASE: review.EVReviewPending vs post.EVReviewPending |
| EP_Review_StatusChange | Computed (delta) | CASE: review.EconomicProfileReviewPending vs post.EconomicProfileReviewPending |
| Screening_StatusChange | Computed (delta) | CASE: review.ScreeningStatus vs post.ScreeningStatus |
| SOF_Status | Computed (delta) | CASE on CheckAlertSummary LIKE '%request SOF%' and SOFProvided |
| NeedsFollowup | Computed | 1 if TotalCheckAlertsPostReview > 0 |
| ReviewOutcomeChange | Computed | 'Worsened'/'Improved'/'No Change'/'Unknown' vs TotalCheckAlerts at review time |
| HasSOFDocument | Computed | 1 if SOF document in External_CustomerDocument |
| HasSelfieDocument | Computed | 1 if selfie document (DocumentTypeID 15/18/23) in External_CustomerDocument |
| UpdateDate | GETDATE() | ETL timestamp |
