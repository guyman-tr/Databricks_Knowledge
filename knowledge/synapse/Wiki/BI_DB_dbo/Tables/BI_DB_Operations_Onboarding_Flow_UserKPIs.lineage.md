# Column Lineage: BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs` |
| **UC Target** | _Not_Migrated |
| **Primary Source** | `DWH_dbo.Dim_Customer` (customer base pool, 24-month registration window) |
| **ETL SP** | `SP_Operations_Onboarding_Flow_UserKPIs` |
| **Secondary Sources** | `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_EvMatchStatus`, `DWH_dbo.Dim_PhoneVerified`, `DWH_dbo.Fact_BillingDeposit`, `[general].[etoro_History_BackOfficeCustomer]`, `BI_DB_dbo.External_ComplianceStateDB_*` (3 tables), `BI_DB_dbo.External_ScreeningService_*` (7 tables), `BI_DB_dbo.External_etoro_BackOffice_CustomerDocument*` (5 tables), `BI_DB_dbo.BI_DB_First5Actions`, `BI_DB_dbo.BI_DB_LTV_BI_Actual` |
| **Generated** | 2026-04-26 |

## Lineage Chain

```
DWH_dbo.Dim_Customer (base: RegisteredReal >= DATEADD(MONTH, -24, GETDATE()))
    |
    +-- JOIN DWH_dbo.Dim_Country dc ON CountryID
    +-- JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID (DesignatedRegulation)
    +-- LEFT JOIN DWH_dbo.Dim_Regulation dr2 ON RegulationID (CurrentRegulation)
    +-- LEFT JOIN DWH_dbo.Dim_PhoneVerified dpv ON PhoneVerifiedID
    +-- LEFT JOIN [general].[etoro_History_BackOfficeCustomer] hbo (VL transitions: VL1/VL2/VL3 timestamps)
    +-- LEFT JOIN DWH_dbo.Dim_EvMatchStatus evms ON EvMatchStatusID
    +-- LEFT JOIN BI_DB_dbo.External_ComplianceStateDB_Compliance_KycFlow (current KYC flow)
    +-- LEFT JOIN BI_DB_dbo.External_ComplianceStateDB_History_KycFlow (historical KYC flow fallback)
    +-- LEFT JOIN BI_DB_dbo.External_ComplianceStateDB_Dictionary_KYCFlowType (KYC flow name)
    +-- LEFT JOIN BI_DB_dbo.External_ScreeningService_* (7 tables: user screening data)
    +-- LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocument + related (POI/POA documents)
    +-- LEFT JOIN BI_DB_dbo.BI_DB_First5Actions (FirstAction, FirstActionDate)
    +-- LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual (Revenue8Y_LTV_New -> LTV)
    +-- LEFT JOIN DWH_dbo.Fact_BillingDeposit (FirstDepositAttemptDate)
    |
    └-- SP_Operations_Onboarding_Flow_UserKPIs
        ├-- TRUNCATE TABLE target
        └-- INSERT -> BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |
| **rename** | Same value, different column name in target. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| # | Target Column | Source Table | Source Column | Transform | Notes |
|---|--------------|-------------|---------------|-----------|-------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | rename | Customer ID, hash distribution key |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | passthrough | Group Customer ID |
| 3 | KYCFlowID | External_ComplianceStateDB_Dictionary_KYCFlowType | KYCFlowTypeID | join-enriched | KYC flow type ID, resolved via Compliance_KycFlow or History_KycFlow |
| 4 | KYCFlow | External_ComplianceStateDB_Dictionary_KYCFlowType | Name | join-enriched | KYC flow name (e.g., Normal, Verify Before Deposit) |
| 5 | CountryID | DWH_dbo.Dim_Country | CountryID | join-enriched | Via Dim_Customer.CountryID -> Dim_Country |
| 6 | CountryName | DWH_dbo.Dim_Country | Name | join-enriched | Country full name |
| 7 | RiskGroupID | DWH_dbo.Dim_Country | RiskGroupID | join-enriched | Country risk classification |
| 8 | Region | DWH_dbo.Dim_Country | Region | join-enriched | Marketing region label |
| 9 | MarketingRegion | DWH_dbo.Dim_Country | MarketingRegionManualName | join-enriched | Manual marketing region override name |
| 10 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | join-enriched | Via Dim_Country.RegulationID -> Dim_Regulation.Name |
| 11 | IsRegAndVL3SameDay | SP logic | — | ETL-computed | `CASE WHEN CAST(DateTime_VL0 AS DATE) = CAST(DateTime_VL3 AS DATE) THEN 1 ELSE 0 END` |
| 12 | IsVL3In24HRsFromReg | SP logic | — | ETL-computed | `CASE WHEN DATEDIFF(HOUR, DateTime_VL0, DateTime_VL3) <= 24 THEN 1 ELSE 0 END` |
| 13 | CountVLChangesCount | [general].[etoro_History_BackOfficeCustomer] | VerificationLevelID | ETL-computed | Count of VL changes from history table |
| 14 | IsVLChangesCountOkay | SP logic | — | ETL-computed | Flag indicating VL change count is within acceptable range |
| 15 | DDCategoryVL0toVL3 | SP logic | — | ETL-computed | CASE on DDMinutes_VL0toVL3: <=60->'<=1Hour', <=1440->'1Hour-24Hours', etc. |
| 16 | IsVL0 | DWH_dbo.Dim_Customer | VerificationLevelID | ETL-computed | `CASE WHEN VerificationLevelID >= 0 THEN 1 ELSE 0 END` (always 1) |
| 17 | IsVL1 | [general].[etoro_History_BackOfficeCustomer] | VerificationLevelID | ETL-computed | 1 if customer reached VL1+ |
| 18 | IsVL2 | [general].[etoro_History_BackOfficeCustomer] | VerificationLevelID | ETL-computed | 1 if customer reached VL2+ |
| 19 | IsVL3 | [general].[etoro_History_BackOfficeCustomer] | VerificationLevelID | ETL-computed | 1 if customer reached VL3 |
| 20 | IsFTD | DWH_dbo.Dim_Customer | IsDepositor | rename | First-time deposit flag |
| 21 | DateTime_VL0 | DWH_dbo.Dim_Customer | RegisteredReal | rename | Registration timestamp = VL0 datetime |
| 22 | DateTime_VL1 | [general].[etoro_History_BackOfficeCustomer] | UpdateDate | ETL-computed | First timestamp where VerificationLevelID >= 1 |
| 23 | DateTime_VL2 | [general].[etoro_History_BackOfficeCustomer] | UpdateDate | ETL-computed | First timestamp where VerificationLevelID >= 2 |
| 24 | DateTime_VL3 | [general].[etoro_History_BackOfficeCustomer] | UpdateDate | ETL-computed | First timestamp where VerificationLevelID = 3 |
| 25 | DateTime_FTD | DWH_dbo.Dim_Customer | FirstDepositDate | rename | First deposit timestamp |
| 26 | DDMinutes_VL0toVL1 | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, DateTime_VL0, DateTime_VL1)` |
| 27 | DDMinutes_VL1toVL2 | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, DateTime_VL1, DateTime_VL2)` |
| 28 | DDMinutes_VL2toVL3 | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, DateTime_VL2, DateTime_VL3)` |
| 29 | DDMinutes_VL0toVL3 | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, DateTime_VL0, DateTime_VL3)` |
| 30 | US_TotalHits | External_ScreeningService_* | — | join-enriched | Total screening hits from ScreeningService provider |
| 31 | US_UnresolvedHits | External_ScreeningService_* | — | join-enriched | Unresolved screening hits count |
| 32 | US_ProviderName | External_ScreeningService_* | ProviderName | join-enriched | Screening provider name (e.g., WorldCheck) |
| 33 | US_ProviderStatus | External_ScreeningService_* | ProviderStatus | join-enriched | Provider-level screening status |
| 34 | US_ScreeningStatus | External_ScreeningService_* | ScreeningStatus | join-enriched | User-level screening status (NoMatch/UnderInvestigation/Match) |
| 35 | US_ScreeningProcess | External_ScreeningService_* | ScreeningProcess | join-enriched | Screening process type |
| 36 | US_ScreeningPriority | External_ScreeningService_* | ScreeningPriority | join-enriched | Screening priority level |
| 37 | US_UpdatedBy | External_ScreeningService_* | UpdatedBy | join-enriched | Who last updated the screening record |
| 38 | US_IsCaseResolved | External_ScreeningService_* | — | join-enriched | Whether screening case is resolved (1/0) |
| 39 | US_StartTime | External_ScreeningService_* | StartTime | join-enriched | Screening case start datetime |
| 40 | US_EndTime | External_ScreeningService_* | EndTime | join-enriched | Screening case end datetime |
| 41 | US_SLAMinutes | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, US_StartTime, US_EndTime)` |
| 42 | US_IsAutomatic | External_ScreeningService_* | — | ETL-computed | 1 if screening resolved automatically (no manual intervention) |
| 43 | EV_IsCountryEligible | SP logic | CountryID | ETL-computed | 1 if CountryID in hardcoded list of 25 EV-eligible countries |
| 44 | EV_MatchStatusDateTime | [general].[etoro_History_BackOfficeCustomer] | UpdateDate | ETL-computed | Timestamp when EV match status was set |
| 45 | EV_MatchStatusID | [general].[etoro_History_BackOfficeCustomer] | EvMatchStatus | ETL-computed | EV match status ID from history |
| 46 | EV_MatchStatus | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | join-enriched | EV match status label (Verified/PartiallyVerified/etc.) |
| 47 | EV_DDMinutes_VL2toEVMatch | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, DateTime_VL2, EV_MatchStatusDateTime)` |
| 48 | VD_HasDocuments | External_etoro_BackOffice_CustomerDocument | — | ETL-computed | 1 if customer has any uploaded documents |
| 49 | POI_IsApproved | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if proof of identity document approved |
| 50 | POI_UploadDateTime | External_etoro_BackOffice_CustomerDocument | DateAdded | join-enriched | POI document upload timestamp |
| 51 | POI_ResponseDateTime | External_etoro_BackOffice_CustomerDocument | ResponseDate | join-enriched | POI review response timestamp |
| 52 | POI_SLAMinutes | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, POI_UploadDateTime, POI_ResponseDateTime)` |
| 53 | POI_IsResponseAutomatic | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if POI reviewed by automated vendor (Onfido/Au10tix/Sumsub) |
| 54 | POI_HasOnlyDeclines | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if all POI submissions were declined |
| 55 | POI_CountDeclines | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | Count of declined POI submissions |
| 56 | POA_IsApproved | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if proof of address document approved |
| 57 | POA_UploadDateTime | External_etoro_BackOffice_CustomerDocument | DateAdded | join-enriched | POA document upload timestamp |
| 58 | POA_ResponseDateTime | External_etoro_BackOffice_CustomerDocument | ResponseDate | join-enriched | POA review response timestamp |
| 59 | POA_SLAMinutes | SP logic | — | ETL-computed | `DATEDIFF(MINUTE, POA_UploadDateTime, POA_ResponseDateTime)` |
| 60 | POA_IsResponseAutomatic | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if POA reviewed by automated vendor |
| 61 | POA_HasOnlyDeclines | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | 1 if all POA submissions were declined |
| 62 | POA_CountDeclines | External_etoro_BackOffice_CustomerDocument* | — | ETL-computed | Count of declined POA submissions |
| 63 | EmailVerification | DWH_dbo.Dim_Customer | IsEmailVerified | rename | Email verification flag |
| 64 | PhoneVerification | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | join-enriched | Phone verification status label |
| 65 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough | Current KYC verification level |
| 66 | IsSTP_eToro | SP logic | — | ETL-computed | Compound: IsVL3 + US_IsAutomatic + EV matched + POI_IsResponseAutomatic + POA_IsResponseAutomatic |
| 67 | IsSTP_User | SP logic | — | ETL-computed | Compound: IsVL3 + no docs uploaded + no declines |
| 68 | UpdateDate | — | — | ETL-computed | `GETDATE()` ETL timestamp |
| 69 | FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstAction | join-enriched | Customer's first platform action type |
| 70 | FirstDepositAmount | DWH_dbo.Dim_Customer | FirstDepositAmount | passthrough | First deposit amount in USD |
| 71 | NonVerificationReason | SP logic | — | ETL-computed | CASE logic for VL2 customers not reaching VL3 |
| 72 | VendorPOA | External_etoro_BackOffice_DocumentVendors | VendorName | join-enriched | Vendor who processed POA document |
| 73 | RejectionReasonPOA | External_etoro_BackOffice_DocumentRejectReason | RejectReasonName | join-enriched | POA rejection reason text |
| 74 | VendorPOI | External_etoro_BackOffice_DocumentVendors | VendorName | join-enriched | Vendor who processed POI document |
| 75 | RejectionReasonPOI | External_etoro_BackOffice_DocumentRejectReason | RejectReasonName | join-enriched | POI rejection reason text |
| 76 | CurrentRegulation | DWH_dbo.Dim_Regulation | Name | join-enriched | Current regulation name via Dim_Customer.RegulationID |
| 77 | PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | passthrough | Compliance and trading account status |
| 78 | PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | passthrough | Reason code for PlayerStatus |
| 79 | POA_Manager | External_etoro_BackOffice_CustomerDocumentToDocumentType | ManagerID | join-enriched | Manager who reviewed POA document |
| 80 | POI_Manager | External_etoro_BackOffice_CustomerDocumentToDocumentType | ManagerID | join-enriched | Manager who reviewed POI document |
| 81 | LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | rename | Customer lifetime value |
| 82 | DepositAttempt | DWH_dbo.Fact_BillingDeposit | — | ETL-computed | 1 if customer attempted a deposit (any status) |
| 83 | FirstDepositAttemptDate | DWH_dbo.Fact_BillingDeposit | PaymentDate | ETL-computed | MIN(PaymentDate) from Fact_BillingDeposit for this CID |
| 84 | PlayerStatusSubReasonID | DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | passthrough | Sub-reason code for PlayerStatus |
| 85 | FirstActionDate | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | join-enriched | Timestamp of customer's first platform action |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 6 |
| **Rename** | 7 |
| **Join-enriched** | 33 |
| **ETL-computed** | 39 |
