# BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs

> 9.9M-row operational onboarding analytics table tracking every customer's KYC verification journey (VL0-VL3), AML screening, electronic verification, document processing (POI/POA), and straight-through processing outcomes over a 24-month rolling window. Produced daily by `SP_Operations_Onboarding_Flow_UserKPIs` via full TRUNCATE+INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.SP_Operations_Onboarding_Flow_UserKPIs |
| **Refresh** | Daily TRUNCATE+INSERT (full refresh, 24-month window) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CI(CID) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Operations_Onboarding_Flow_UserKPIs` is a wide denormalized analytics table (85 columns, ~9.94M rows) that measures the end-to-end onboarding efficiency for every customer registered in the last 24 months (April 2024 through April 2026). Each row represents one customer (keyed by CID) and captures the full KYC verification lifecycle: registration (VL0), identity verification progression through VL1/VL2/VL3, AML user screening, electronic verification (EV), document verification (Proof of Identity and Proof of Address), and straight-through processing (STP) outcomes.

The table is designed for Operations teams to monitor onboarding funnel performance, SLA compliance, and automation rates. Key metrics include time-to-verification (DDMinutes columns), screening SLA adherence (US_SLAMinutes), document processing SLA (POI_SLAMinutes, POA_SLAMinutes), and STP rates (IsSTP_eToro, IsSTP_User).

Distribution by regulation: CySEC (4.5M), FCA (2.2M), FSA Seychelles (1.8M), FinCEN+FINRA (722K), ASIC (403K), FSRA (292K), MAS (30K).

---

## 2. Business Logic

### 2.1 Verification Level Progression

**What**: Tracks each customer's journey from registration (VL0) through VL1, VL2, and VL3 (fully verified).

**Columns Involved**: `DateTime_VL0` through `DateTime_VL3`, `IsVL0`-`IsVL3`, `DDMinutes_VL0toVL1`/`VL1toVL2`/`VL2toVL3`/`VL0toVL3`, `IsRegAndVL3SameDay`, `IsVL3In24HRsFromReg`, `CountVLChangesCount`, `IsVLChangesCountOkay`, `DDCategoryVL0toVL3`

**Rules**:
- `DateTime_VL0` = Dim_Customer.RegisteredReal (registration timestamp)
- `DateTime_VL1/VL2/VL3` = first occurrence of that VL level in `[general].[etoro_History_BackOfficeCustomer]`
- `DDMinutes_*` = DATEDIFF(MINUTE, start_datetime, end_datetime) between consecutive VL milestones
- `DDCategoryVL0toVL3` buckets total VL0-to-VL3 time: `<=1Hour`, `1Hour-24Hours`, `1Day-7Days`, `7Days-14Days`, `14Days-30Days`, `>30Days`, `NotCompleted`
- `IsRegAndVL3SameDay` = 1 if VL0 and VL3 occurred on the same calendar day
- `IsVL3In24HRsFromReg` = 1 if VL3 was reached within 24 hours of registration
- `CountVLChangesCount` = total number of VL changes in history; `IsVLChangesCountOkay` = flag for acceptable change count

### 2.2 User Screening

**What**: AML/sanctions screening via ScreeningService integration (WorldCheck provider).

**Columns Involved**: `US_TotalHits`, `US_UnresolvedHits`, `US_ProviderName`, `US_ProviderStatus`, `US_ScreeningStatus`, `US_ScreeningProcess`, `US_ScreeningPriority`, `US_UpdatedBy`, `US_IsCaseResolved`, `US_StartTime`, `US_EndTime`, `US_SLAMinutes`, `US_IsAutomatic`

**Rules**:
- Data sourced from 7 External_ScreeningService_* tables (ProviderScreening, UserScreening, History_ProviderScreening, ManagerResolvedCasesAudit, plus 4 dictionary tables)
- `US_ScreeningStatus` values: NoMatch (clean), UnderInvestigation, Match (positive hit)
- `US_SLAMinutes` = DATEDIFF(MINUTE, US_StartTime, US_EndTime)
- `US_IsAutomatic` = 1 if case resolved without manual analyst intervention

### 2.3 Electronic Verification

**What**: Automated identity verification by country eligibility and match outcome.

**Columns Involved**: `EV_IsCountryEligible`, `EV_MatchStatusDateTime`, `EV_MatchStatusID`, `EV_MatchStatus`, `EV_DDMinutes_VL2toEVMatch`

**Rules**:
- `EV_IsCountryEligible` = 1 if customer's CountryID is in a hardcoded list of 25 EV-eligible countries
- `EV_MatchStatus` resolved from Dim_EvMatchStatus: None (0), PartiallyVerified (1), Verified (2), NotVerified (3)
- `EV_DDMinutes_VL2toEVMatch` = DATEDIFF(MINUTE, DateTime_VL2, EV_MatchStatusDateTime) -- time from VL2 to EV completion

### 2.4 Document Verification (POI/POA)

**What**: Proof of Identity and Proof of Address document processing metrics.

**Columns Involved**: `VD_HasDocuments`, `POI_IsApproved`, `POI_UploadDateTime`, `POI_ResponseDateTime`, `POI_SLAMinutes`, `POI_IsResponseAutomatic`, `POI_HasOnlyDeclines`, `POI_CountDeclines`, `POA_*` (mirror set), `VendorPOI`, `VendorPOA`, `RejectionReasonPOI`, `RejectionReasonPOA`, `POI_Manager`, `POA_Manager`

**Rules**:
- Sourced from External_etoro_BackOffice_CustomerDocument + CustomerDocumentToDocumentType + DocumentType + DocumentRejectReason + DocumentVendors
- `POI_SLAMinutes` / `POA_SLAMinutes` = DATEDIFF(MINUTE, Upload, Response)
- `POI_IsResponseAutomatic` / `POA_IsResponseAutomatic` = 1 if reviewed by automated vendor (Onfido, Au10tix, Sumsub)
- `POI_HasOnlyDeclines` / `POA_HasOnlyDeclines` = 1 if every submission for that doc type was declined
- `VendorPOI` / `VendorPOA` = name of the document processing vendor
- `POI_Manager` / `POA_Manager` = ManagerID of the BackOffice reviewer (0 or NULL if automated)

### 2.5 Straight-Through Processing

**What**: Measures fully automated onboarding without manual intervention.

**Columns Involved**: `IsSTP_eToro`, `IsSTP_User`

**Rules**:
- `IsSTP_eToro` = 1 when ALL of: IsVL3=1 AND US_IsAutomatic=1 AND EV matched AND POI_IsResponseAutomatic=1 AND POA_IsResponseAutomatic=1
- `IsSTP_User` = 1 when ALL of: IsVL3=1 AND no documents uploaded (VD_HasDocuments=0) AND no declines
- `IsSTP_eToro` measures platform automation; `IsSTP_User` measures frictionless user experience

### 2.6 NonVerificationReason Classification

**What**: Classifies why VL2 customers have not progressed to VL3.

**Columns Involved**: `NonVerificationReason`

**Rules** (CASE logic, evaluated in order):
1. Documents submitted but not approved -> `'Docs not Approved'`
2. Missing required documents -> `'Missing Docs'`
3. User screening issue blocking progression -> `'User Screening Issue'`
4. Phone not verified -> `'Phone Not Verified'`
5. None of the above -> `'Others'`
6. Customer already VL3 or not VL2 -> `'Not Relevant'`

### 2.7 KYC Flow Resolution

**What**: Determines which KYC flow governs the customer's onboarding process.

**Columns Involved**: `KYCFlowID`, `KYCFlow`

**Rules**:
- Primary: current KYC flow from External_ComplianceStateDB_Compliance_KycFlow
- Fallback: if current flow = 0 (unset), use historical flow from External_ComplianceStateDB_History_KycFlow
- Flow names resolved via External_ComplianceStateDB_Dictionary_KYCFlowType (e.g., Normal, Verify Before Deposit, Verify Before Trade)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED INDEX on CID. One row per customer. Optimal for CID-based point lookups and JOINs to Dim_Customer (also HASH on RealCID). At ~9.9M rows, full scans are moderately expensive -- filter by regulation, country, or date range when possible.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average time to VL3 by regulation | `WHERE IsVL3 = 1 GROUP BY DesignatedRegulation`, aggregate `DDMinutes_VL0toVL3` |
| STP rate by country | `AVG(CAST(IsSTP_eToro AS FLOAT)) GROUP BY CountryName` |
| Screening SLA compliance | `WHERE US_IsCaseResolved = 1`, analyze `US_SLAMinutes` distribution |
| Document processing bottlenecks | `WHERE POI_IsApproved = 0 AND IsVL2 = 1`, check `NonVerificationReason` |
| Onboarding funnel conversion | `SUM(IsVL1), SUM(IsVL2), SUM(IsVL3) GROUP BY DesignatedRegulation` |
| Daily onboarding cohort | `WHERE CAST(DateTime_VL0 AS DATE) = @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Additional country attributes (EU, IsHighRiskCountry) |
| DWH_dbo.Dim_Regulation | ON DesignatedRegulation = Name | Regulation metadata (ClusterRegulationID) |

### 3.4 Gotchas

- **24-month rolling window**: Older customers are dropped on each daily refresh. Do not rely on this table for historical trend analysis beyond the window.
- **TRUNCATE+INSERT daily**: No intra-day updates. Data reflects state as of the last ETL run.
- **EV_IsCountryEligible**: Based on a hardcoded list of 25 countries in the SP. If new countries become EV-eligible, the SP must be updated.
- **NULL DateTime_VL1/VL2/VL3**: NULL means the customer has not reached that VL level. DDMinutes columns will also be NULL.
- **NonVerificationReason**: Only meaningful for VL2 customers (IsVL2=1, IsVL3=0). For other customers, value is 'Not Relevant'.
- **US_* columns**: NULL if no screening record exists for the customer in ScreeningService.
- **PhoneVerification**: Contains the label text (e.g., "AutomaticallyVerified", "ManualyVerified" with production typo), not the numeric ID.
- **LTV**: From BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New -- may be NULL for customers without LTV model coverage.
- **DepositAttempt vs IsFTD**: DepositAttempt=1 means any deposit was attempted (any status); IsFTD=1 means customer is a depositor (approved deposit exists).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (verbatim) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 3 | Inferred from data | Medium |
| Tier 4 | Best guess / Confluence | Lower |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Distribution key and clustered index. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | KYCFlowID | int | YES | KYC flow type identifier from ComplianceStateDB. Resolved from current Compliance_KycFlow table, falling back to History_KycFlow if current = 0. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 4 | KYCFlow | varchar(50) | YES | KYC flow name (e.g., Normal, Verify Before Deposit, Verify Before Trade). Resolved from Dictionary_KYCFlowType via KYCFlowID. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 5 | CountryID | int | YES | Country of residence. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 6 | CountryName | varchar(50) | YES | Full country name in English. Unique per country. (Tier 1 — Dictionary.Country) |
| 7 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. (Tier 1 — Dictionary.Country) |
| 8 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region. 22 distinct values. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 9 | MarketingRegion | varchar(50) | YES | Manual override name for the marketing region. May differ from Region (e.g., Albania: Region=ROE, MarketingRegion=CEE). (Tier 3 — Ext_Dim_Country) |
| 10 | DesignatedRegulation | varchar(50) | YES | Regulatory entity name governing users from this country (via Dim_Country.RegulationID -> Dim_Regulation.Name). Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC, FSRA, MAS, etc. (Tier 1 — Dictionary.Regulation) |
| 11 | IsRegAndVL3SameDay | int | YES | 1 if customer registration (VL0) and VL3 completion occurred on the same calendar day. 0 otherwise. NULL if VL3 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 12 | IsVL3In24HRsFromReg | int | YES | 1 if customer reached VL3 within 24 hours of registration. 0 otherwise. NULL if VL3 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 13 | CountVLChangesCount | int | YES | Total count of verification level changes recorded in BackOffice customer history for this customer. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 14 | IsVLChangesCountOkay | int | YES | Flag indicating whether the count of VL changes is within the expected/acceptable range. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 15 | DDCategoryVL0toVL3 | varchar(50) | YES | Categorical bucket for total VL0-to-VL3 duration: '<=1Hour', '1Hour-24Hours', '1Day-7Days', '7Days-14Days', '14Days-30Days', '>30Days', 'NotCompleted'. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 16 | IsVL0 | int | YES | 1 if customer has reached VL0 (registered). Effectively always 1 since all rows are registered customers. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 17 | IsVL1 | int | YES | 1 if customer has reached verification level 1 or above. 0 if still at VL0. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 18 | IsVL2 | int | YES | 1 if customer has reached verification level 2 or above. 0 if below VL2. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 19 | IsVL3 | int | YES | 1 if customer has reached verification level 3 (fully verified). 0 otherwise. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 20 | IsFTD | int | YES | Whether the customer has ever deposited. Mapped from Dim_Customer.IsDepositor. 1=depositor, 0=non-depositor. (Tier 2 — SP_Dim_Customer) |
| 21 | DateTime_VL0 | datetime | YES | Registration timestamp (mapped from Dim_Customer.RegisteredReal). Represents the start of the onboarding journey. (Tier 1 — Customer.CustomerStatic) |
| 22 | DateTime_VL1 | datetime | YES | Timestamp when customer first reached verification level 1. Derived from the earliest History_BackOfficeCustomer record with VerificationLevelID >= 1. NULL if VL1 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 23 | DateTime_VL2 | datetime | YES | Timestamp when customer first reached verification level 2. Derived from History_BackOfficeCustomer. NULL if VL2 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 24 | DateTime_VL3 | datetime | YES | Timestamp when customer first reached verification level 3 (fully verified). Derived from History_BackOfficeCustomer. NULL if VL3 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 25 | DateTime_FTD | datetime | YES | Date of first deposit. Mapped from Dim_Customer.FirstDepositDate. DEFAULT='19000101' in Dim_Customer when no deposit exists. (Tier 2 — SP_Dim_Customer) |
| 26 | DDMinutes_VL0toVL1 | int | YES | Duration in minutes from registration (VL0) to reaching VL1. DATEDIFF(MINUTE, DateTime_VL0, DateTime_VL1). NULL if VL1 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 27 | DDMinutes_VL1toVL2 | int | YES | Duration in minutes from VL1 to VL2. DATEDIFF(MINUTE, DateTime_VL1, DateTime_VL2). NULL if VL2 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 28 | DDMinutes_VL2toVL3 | int | YES | Duration in minutes from VL2 to VL3. DATEDIFF(MINUTE, DateTime_VL2, DateTime_VL3). NULL if VL3 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 29 | DDMinutes_VL0toVL3 | int | YES | Duration in minutes from registration (VL0) to full verification (VL3). DATEDIFF(MINUTE, DateTime_VL0, DateTime_VL3). NULL if VL3 not reached. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 30 | US_TotalHits | int | YES | Total number of AML screening hits returned by the screening provider for this customer. NULL if no screening record exists. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 31 | US_UnresolvedHits | int | YES | Number of screening hits still unresolved (pending manual review). NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 32 | US_ProviderName | varchar(50) | YES | Name of the AML screening provider (e.g., WorldCheck). NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 33 | US_ProviderStatus | varchar(50) | YES | Provider-level screening status. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 34 | US_ScreeningStatus | varchar(50) | YES | User-level screening outcome: NoMatch (clean), UnderInvestigation, Match (positive hit). NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 35 | US_ScreeningProcess | varchar(50) | YES | Type of screening process applied. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 36 | US_ScreeningPriority | varchar(50) | YES | Priority level of the screening case. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 37 | US_UpdatedBy | varchar(50) | YES | Identifier of the person or system that last updated the screening record. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 38 | US_IsCaseResolved | int | YES | 1 if the screening case has been resolved (closed). 0 if still open. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 39 | US_StartTime | datetime | YES | Timestamp when the screening case was opened. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 40 | US_EndTime | datetime | YES | Timestamp when the screening case was closed/resolved. NULL if case still open or no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 41 | US_SLAMinutes | int | YES | SLA duration in minutes for screening case resolution. DATEDIFF(MINUTE, US_StartTime, US_EndTime). NULL if case not resolved or no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 42 | US_IsAutomatic | int | YES | 1 if the screening case was resolved automatically without manual analyst intervention. 0 if manually resolved. NULL if no screening record. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 43 | EV_IsCountryEligible | int | YES | 1 if the customer's country is in the hardcoded list of 25 countries eligible for electronic verification. 0 otherwise. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 44 | EV_MatchStatusDateTime | datetime | YES | Timestamp when the EV match status was recorded in BackOffice customer history. NULL if no EV process occurred. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 45 | EV_MatchStatusID | int | YES | EV match status code. 0=None, 1=PartiallyVerified, 2=Verified, 3=NotVerified. Derived from History_BackOfficeCustomer. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 46 | EV_MatchStatus | varchar(50) | YES | Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 47 | EV_DDMinutes_VL2toEVMatch | int | YES | Duration in minutes from VL2 to EV match completion. DATEDIFF(MINUTE, DateTime_VL2, EV_MatchStatusDateTime). NULL if VL2 not reached or no EV process. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 48 | VD_HasDocuments | int | YES | 1 if the customer has any uploaded verification documents (POI or POA). 0 if no documents on file. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 49 | POI_IsApproved | int | YES | 1 if a Proof of Identity document has been approved for this customer. 0 if no approved POI. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 50 | POI_UploadDateTime | datetime | YES | Timestamp when the POI document was uploaded by the customer. NULL if no POI document exists. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 51 | POI_ResponseDateTime | datetime | YES | Timestamp when the POI document review response was given (approved/rejected). NULL if not yet reviewed. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 52 | POI_SLAMinutes | int | YES | SLA duration in minutes for POI document review. DATEDIFF(MINUTE, POI_UploadDateTime, POI_ResponseDateTime). NULL if not yet reviewed. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 53 | POI_IsResponseAutomatic | int | YES | 1 if the POI document was reviewed by an automated vendor (Onfido, Au10tix, Sumsub). 0 if manually reviewed by a BackOffice agent. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 54 | POI_HasOnlyDeclines | int | YES | 1 if all POI document submissions for this customer have been declined. 0 if at least one was approved or is pending. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 55 | POI_CountDeclines | int | YES | Total number of declined POI document submissions for this customer. 0 if no declines. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 56 | POA_IsApproved | int | YES | 1 if a Proof of Address document has been approved for this customer. 0 if no approved POA. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 57 | POA_UploadDateTime | datetime | YES | Timestamp when the POA document was uploaded by the customer. NULL if no POA document exists. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 58 | POA_ResponseDateTime | datetime | YES | Timestamp when the POA document review response was given. NULL if not yet reviewed. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 59 | POA_SLAMinutes | int | YES | SLA duration in minutes for POA document review. DATEDIFF(MINUTE, POA_UploadDateTime, POA_ResponseDateTime). NULL if not yet reviewed. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 60 | POA_IsResponseAutomatic | int | YES | 1 if the POA document was reviewed by an automated vendor (Onfido, Au10tix, Sumsub). 0 if manually reviewed. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 61 | POA_HasOnlyDeclines | int | YES | 1 if all POA document submissions for this customer have been declined. 0 otherwise. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 62 | POA_CountDeclines | int | YES | Total number of declined POA document submissions for this customer. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 63 | EmailVerification | int | YES | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. Mapped from Dim_Customer.IsEmailVerified. (Tier 1 — Customer.CustomerStatic) |
| 64 | PhoneVerification | varchar(30) | YES | Phone verification status label: NotVerified, AutomaticallyVerified, ManualyVerified (production typo preserved), Initiated, Rejected, AbuseFlag. Resolved via Dim_PhoneVerified.PhoneVerifiedName. (Tier 1 — Dictionary.PhoneVerified) |
| 65 | VerificationLevelID | int | YES | KYC verification level. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | IsSTP_eToro | int | YES | Platform straight-through processing flag. 1 when ALL of: IsVL3=1, US_IsAutomatic=1, EV matched, POI_IsResponseAutomatic=1, POA_IsResponseAutomatic=1. Measures full automation of onboarding. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 67 | IsSTP_User | int | YES | User-experience straight-through processing flag. 1 when ALL of: IsVL3=1, no documents uploaded, no declines. Measures frictionless onboarding from the user perspective. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 68 | UpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() at SP run time. Not a business date. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 69 | FirstAction | int | YES | Customer's first platform action type code. Sourced from BI_DB_First5Actions. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 70 | FirstDepositAmount | money | YES | Amount of first deposit (in USD). Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 71 | NonVerificationReason | varchar(100) | YES | Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customers. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 72 | VendorPOA | varchar(100) | YES | Name of the vendor that processed the Proof of Address document (e.g., Onfido, Au10tix, Sumsub). NULL if no POA processing. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 73 | RejectionReasonPOA | varchar(100) | YES | Rejection reason text for the POA document. NULL if POA was approved or not submitted. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 74 | VendorPOI | varchar(100) | YES | Name of the vendor that processed the Proof of Identity document. NULL if no POI processing. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 75 | RejectionReasonPOI | varchar(100) | YES | Rejection reason text for the POI document. NULL if POI was approved or not submitted. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 76 | CurrentRegulation | varchar(100) | YES | Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration. (Tier 1 — Dictionary.Regulation) |
| 77 | PlayerStatusID | int | YES | Compliance and trading account status. 1=Normal (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 78 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 79 | POA_Manager | int | YES | ManagerID of the BackOffice agent who reviewed the POA document. 0 or NULL if automated. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 80 | POI_Manager | int | YES | ManagerID of the BackOffice agent who reviewed the POI document. 0 or NULL if automated. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 81 | LTV | money | YES | Customer lifetime value (Revenue8Y_LTV_New from BI_DB_LTV_BI_Actual). NULL if customer has no LTV model coverage. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 82 | DepositAttempt | int | YES | 1 if the customer has attempted at least one deposit (any payment status, including declined). 0 if no deposit attempted. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 83 | FirstDepositAttemptDate | datetime | YES | Timestamp of the customer's first deposit attempt (MIN PaymentDate from Fact_BillingDeposit, any status). NULL if no deposit attempted. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |
| 84 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (hierarchical). Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 85 | FirstActionDate | datetime | YES | Timestamp of the customer's first platform action. Sourced from BI_DB_First5Actions. (Tier 2 — SP_Operations_Onboarding_Flow_UserKPIs) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Type | Role |
|--------|------|------|
| DWH_dbo.Dim_Customer | Table | Primary customer base pool (24-month registration window). Provides CID, GCID, registration, deposit, verification, email, phone, player status columns. |
| DWH_dbo.Dim_Country | Table | Country attributes: CountryName, RiskGroupID, Region, MarketingRegion, RegulationID for DesignatedRegulation. |
| DWH_dbo.Dim_Regulation | Table | Regulation name resolution for both DesignatedRegulation and CurrentRegulation. |
| DWH_dbo.Dim_EvMatchStatus | Table | EV match status label lookup (4-row dictionary). |
| DWH_dbo.Dim_PhoneVerified | Table | Phone verification status label lookup (6-row dictionary). |
| [general].[etoro_History_BackOfficeCustomer] | External Table | VL transition timestamps (VL1/VL2/VL3) and EV match status history. |
| BI_DB_dbo.External_ComplianceStateDB_Dictionary_KYCFlowType | External Table | KYC flow type names. |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_KycFlow | External Table | Current KYC flow assignment. |
| BI_DB_dbo.External_ComplianceStateDB_History_KycFlow | External Table | Historical KYC flow (fallback when current = 0). |
| BI_DB_dbo.External_ScreeningService_* (7 tables) | External Tables | AML screening data: provider, user screening, history, manager audit, dictionary tables. |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | External Table | Document upload metadata. |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | External Table | Document-to-type classification events, manager info. |
| BI_DB_dbo.External_etoro_BackOffice_DocumentType | External Table | Document type dictionary. |
| BI_DB_dbo.External_etoro_BackOffice_DocumentRejectReason | External Table | Document rejection reason dictionary. |
| BI_DB_dbo.External_etoro_BackOffice_DocumentVendors | External Table | Document processing vendor names. |
| BI_DB_dbo.BI_DB_First5Actions | Table | First platform action type and date per customer. |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | Table | Customer LTV model output (Revenue8Y_LTV_New). |
| DWH_dbo.Fact_BillingDeposit | Table | First deposit attempt date and deposit attempt flag. |

### 5.2 ETL Pipeline

```
Dim_Customer (RegisteredReal >= -24 months)
  +-- JOIN Dim_Country, Dim_Regulation, Dim_PhoneVerified
  +-- LEFT JOIN History_BackOfficeCustomer (VL transitions, EV history)
  +-- LEFT JOIN ComplianceStateDB_* (KYC flow)
  +-- LEFT JOIN ScreeningService_* (US_* columns)
  +-- LEFT JOIN BackOffice_CustomerDocument_* (POI/POA columns)
  +-- LEFT JOIN BI_DB_First5Actions, BI_DB_LTV_BI_Actual, Fact_BillingDeposit
  |
  -> SP_Operations_Onboarding_Flow_UserKPIs
      -> TRUNCATE target
      -> INSERT INTO BI_DB_Operations_Onboarding_Flow_UserKPIs
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer master dimension |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country dimension |
| DesignatedRegulation | DWH_dbo.Dim_Regulation.Name | Designated regulation (via country) |
| CurrentRegulation | DWH_dbo.Dim_Regulation.Name | Customer's current regulation |
| VerificationLevelID | DWH_dbo.Dim_Customer.VerificationLevelID | Verification level |
| PlayerStatusID | DWH_dbo.Dim_Customer.PlayerStatusID | Player status |
| EV_MatchStatusID | DWH_dbo.Dim_EvMatchStatus.EvMatchStatusID | EV match status |

### 6.2 Referenced By

No known downstream consumers documented. This is an operational reporting endpoint table consumed by dashboards.

---

## 7. Sample Queries

### 7.1 Onboarding funnel by regulation
```sql
SELECT
    DesignatedRegulation,
    COUNT(*) AS TotalCustomers,
    SUM(IsVL1) AS ReachedVL1,
    SUM(IsVL2) AS ReachedVL2,
    SUM(IsVL3) AS ReachedVL3,
    SUM(IsFTD) AS Depositors,
    ROUND(100.0 * SUM(IsVL3) / NULLIF(COUNT(*), 0), 1) AS VL3_Pct
FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs]
GROUP BY DesignatedRegulation
ORDER BY TotalCustomers DESC;
```

### 7.2 Average time to VL3 by DDCategory
```sql
SELECT
    DDCategoryVL0toVL3,
    COUNT(*) AS Customers,
    AVG(DDMinutes_VL0toVL3) AS AvgMinutesToVL3
FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs]
WHERE IsVL3 = 1
GROUP BY DDCategoryVL0toVL3
ORDER BY AvgMinutesToVL3;
```

### 7.3 STP rates by regulation
```sql
SELECT
    DesignatedRegulation,
    COUNT(*) AS VL3Customers,
    SUM(IsSTP_eToro) AS STP_eToro,
    SUM(IsSTP_User) AS STP_User,
    ROUND(100.0 * SUM(IsSTP_eToro) / NULLIF(COUNT(*), 0), 1) AS STP_eToro_Pct
FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs]
WHERE IsVL3 = 1
GROUP BY DesignatedRegulation
ORDER BY VL3Customers DESC;
```

### 7.4 NonVerificationReason breakdown for VL2 customers
```sql
SELECT
    NonVerificationReason,
    DesignatedRegulation,
    COUNT(*) AS Customers
FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs]
WHERE IsVL2 = 1 AND IsVL3 = 0
GROUP BY NonVerificationReason, DesignatedRegulation
ORDER BY Customers DESC;
```

### 7.5 Document processing SLA by vendor
```sql
SELECT
    VendorPOI,
    COUNT(*) AS DocsProcessed,
    AVG(POI_SLAMinutes) AS AvgSLAMinutes,
    SUM(POI_IsResponseAutomatic) AS AutomaticCount
FROM [BI_DB_dbo].[BI_DB_Operations_Onboarding_Flow_UserKPIs]
WHERE POI_ResponseDateTime IS NOT NULL
GROUP BY VendorPOI
ORDER BY DocsProcessed DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 12 T1, 73 T2, 0 T3, 0 T4 | Elements: 85/85, all documented*
*Object: BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs | Type: Table | Production Source: BI_DB_dbo.SP_Operations_Onboarding_Flow_UserKPIs*
