# Column Lineage: BI_DB_dbo.BI_DB_CIDFirstDates

> Production-to-DWH column mapping from SP_CIDFirstDates (1,467 lines). Alias-level source attribution applied per Phase 9 Step 2b.

## Lineage Chain

```
DWH_dbo.Dim_Customer (primary) ──┐
DWH_dbo.Fact_CustomerAction     ─┤
DWH_dbo.Fact_BillingDeposit     ─┤  SP_CIDFirstDates
DWH_dbo.Fact_FirstCustomerAction─┤  (Priority 90, SB_Daily)
DWH_dbo.Fact_SnapshotCustomer   ─┤       │
DWH_dbo.V_Liabilities           ─┤       ▼
DWH_dbo.Dim_Mirror              ─┤  BI_DB_CIDFirstDates
BI_DB_dbo.BI_DB_UsageTracking_SF─┤
External_etoro_History_Credit    ─┤
External ComplianceStateDB       ─┤
BI_DB_dbo.BI_DB_AppFlyer_Reports─┤
Function_Population_Funded()     ─┤
Function_Population_First_Time_Funded()─┘
```

## Column Lineage

### A. Identity & Demographics (7 columns — Dim_Customer passthrough)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| CID | Dim_Customer (dc) | RealCID | passthrough (PK) |
| GCID | Dim_Customer (dc) | GCID | passthrough |
| OriginalCID | Dim_Customer (dc) | OriginalCID | passthrough |
| UserName | Dim_Customer (dc) | UserName | passthrough |
| Gender | Dim_Customer (dc) | Gender | passthrough |
| BirthDate | Dim_Customer (dc) | BirthDate | passthrough |
| CountryID | Dim_Customer (dc) | CountryID | passthrough |

### B. Dimension Lookups (16 columns — join-enriched from Dim_Customer FK columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Club | Dim_PlayerLevel (pl) | Name | JOIN via PlayerLevelID |
| Channel | Dim_Channel (chan) | Channel | JOIN via Dim_Affiliate.SubChannelID; ISNULL(,'Direct') |
| SubChannel | Dim_Channel (chan) | SubChannel | JOIN via Dim_Affiliate.SubChannelID; ISNULL(,'Direct') |
| LabelName | Dim_Label (ln) | Name | JOIN via LabelID |
| Country | Dim_Country (country) | Name | JOIN via CountryID |
| Language | Dim_Language (language) | Name | JOIN via LanguageID |
| Region | Dim_Country (country) | Region | JOIN via CountryID |
| NewMarketingRegion | Dim_Country (country) | MarketingRegionManualName | JOIN via CountryID |
| PotentialDesk | Dim_Country (country) | Desk | JOIN via CountryID |
| FunnelName | Dim_Funnel (fun) | Name | JOIN via FunnelID |
| FunnelFromName | Dim_Funnel (funF) | Name | JOIN via FunnelFromID |
| CommunicationLanguage | Dim_Language (comlang) | Name | JOIN via CommunicationLanguageID |
| Verified | Dim_VerificationLevel (ver) | ID | JOIN via VerificationLevelID |
| Manager | Dim_Manager (man) | FirstName+' '+LastName | JOIN via AccountManagerID |
| State | Dim_State_and_Province (ds) | Name | JOIN via RegionID=RegionByIP_ID |
| SerialID | Dim_Customer (cc) | AffiliateID | rename |

### C. Dim_Customer Direct Reads (8 columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Email | Dim_Customer (cc) | Email | passthrough (PII) |
| ReferralID | Dim_Customer (cc) | ReferralID | passthrough |
| DownloadID | Dim_Customer (cc) | DownloadID | passthrough |
| RegulationID | Dim_Customer (cc) | RegulationID | passthrough |
| BannerID | Dim_Customer (cc) | BannerID | passthrough |
| SubAffiliateID | Dim_Customer (cc) | SubSerialID | rename |
| PrivacyPolicyID | Dim_Customer (cc) | PrivacyPolicyID | passthrough |
| IP | Dim_Customer (dc) | IP | passthrough (PII) |

### D. ETL-Computed from Dim_Customer (4 columns)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| registered | Dim_Customer (cc) | RegisteredDemo, RegisteredReal | CASE WHEN RegisteredDemo < RegisteredReal THEN RegisteredDemo ELSE RegisteredReal |
| Blocked | Dim_Customer (cc) | PlayerStatusID | CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0 |
| EvMatchStatus | Dim_Customer (b) | EvMatchStatus | Direct read with change detection |
| DesignatedRegulationID | Dim_Customer (b) | DesignatedRegulationID | Direct read with change detection |

### E. Deposit Attempt Data (4 columns — Fact_FirstCustomerAction)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| FirstDepositAttempt | Fact_FirstCustomerAction (ffa) | FirstOccurred | WHERE ActionTypeID=27, first by date |
| FirstDepositAttemptAmount | Fact_FirstCustomerAction (ffa) | Amount*ExchangeRate | WHERE ActionTypeID=27 |
| FirstDepositAttemptProcessor | (hardcoded) | N/A | Always 'NA' — not resolved |
| FirstDepositAttemptFundingType | (hardcoded) | N/A | Always 'NA' — not resolved |

### F. First Deposit Data (4 columns — ALIAS-LEVEL ATTRIBUTION)

**⛔ Alias-level source attribution applied**: In the `#funding` temp table (SP lines 597-613), `dc.FirstDepositDate` and `dc.FirstDepositAmount` use alias `dc` which resolves to `Dim_Customer`. The `LEFT JOIN Fact_BillingDeposit D ON dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000))` serves only columns with alias `D`, `F`, and `dbd` — NOT `dc.*`.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| FirstDepositDate | **Dim_Customer (dc)** | FirstDepositDate | **Direct read**. Dim_Customer sources from CustomerFinanceDB.Customer.FirstTimeDeposits with FTDRecoveryDate override logic. 1900-01-01 = sentinel (no deposit). |
| FirstDepositAmount | **Dim_Customer (dc)** | FirstDepositAmount | **Direct read**. Dim_Customer sources from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. |
| FirstDepositProcessor | Dim_BillingDepot (dbd) | Name | **Join-enriched** via Fact_BillingDeposit: dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000)), then D.DepotID → dbd.DepotID |
| FirstDepositFundingType | Dim_FundingType (F) | Name | **Join-enriched** via Fact_BillingDeposit: same FTDTransactionID join, then D.FundingTypeID → F.FundingTypeID |

### G. Last Deposit Data (3 columns — Fact_BillingDeposit via #fundingLast)

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| LastDepositDate | Fact_BillingDeposit (fbd) | ModificationDate | WHERE rn_desc=1 (latest by Occurred) |
| LastDepositAmount | Fact_BillingDeposit (fbd) | Amount*ExchangeRate | Latest deposit |
| LastDepositFundingType | Dim_FundingType (F) | Name | JOIN via Fact_BillingDeposit.FundingTypeID |

### H. Action Events (16 columns — Fact_CustomerAction via #fca)

| BI_DB Column | Source | ActionTypeID | Logic |
|-------------|--------|-------------|-------|
| FirstLoggedIn | Fact_CustomerAction | 14 | MIN(Occurred) WHERE rn=1 |
| LastLoggedIn | Fact_CustomerAction | 14 | MAX(Occurred) |
| FirstCashierLogin | Fact_CustomerAction | 29 | MIN(Occurred) WHERE rn=1 |
| LastCashierLogin | Fact_CustomerAction | 29 | MAX(Occurred) |
| FirstPosOpenDate | Fact_CustomerAction | 1,2 | MIN(Occurred) WHERE rn=1 |
| LastPosOpenDate | Fact_CustomerAction | 1,2 | MAX(Occurred) |
| FirstMenualPosOpenDate | Fact_CustomerAction | 1 | MIN(Occurred) WHERE rn=1 |
| LastMenualPosOpenDate | Fact_CustomerAction | 1 | MAX(Occurred) |
| FirstMirrorPosOpenDate | Fact_CustomerAction | 2 | MIN(Occurred) WHERE rn=1 |
| LastMirrorPosOpenDate | Fact_CustomerAction | 2 | MAX(Occurred) |
| FirstMirrorRegistrationDate | Fact_CustomerAction | 17 | MIN(Occurred) WHERE rn=1 |
| LastMirrorRegistrationDate | Fact_CustomerAction | 17 | MAX(Occurred) |
| FirstStocksOpenDate | Fact_CustomerAction | 34 | MIN(Occurred) WHERE rn=1 |
| FirstCashoutDate | Fact_CustomerAction | 8 | MIN(Occurred) WHERE rn=1 |
| LastCashoutDate | Fact_CustomerAction | 8 | MAX(Occurred) WHERE rn_desc=1 |
| FirstDepositAmountExtended | (not populated) | — | Not set by SP |

### I. Copy Trading (2 columns — Dim_Mirror)

| BI_DB Column | Source Table | Source Column | Transform |
|-------------|-------------|---------------|-----------|
| FirstTimeBeingCopied | Dim_Mirror | MIN(OpenOccurred) | GROUP BY ParentCID |
| LastTimeBeingCopied | Dim_Mirror | MAX(OpenOccurred) | GROUP BY ParentCID |

### J. Financial Snapshot (2 columns — V_Liabilities, daily only)

| BI_DB Column | Source Table | Source Column | Transform |
|-------------|-------------|---------------|-----------|
| Credit | V_Liabilities | Credit | ISNULL(Credit,0), only when @date=@yesterday |
| RealizedEquity | V_Liabilities | RealizedEquity | ISNULL(RealizedEquity,0), only when @date=@yesterday |

### K. Contact Tracking (8 columns — BI_DB_UsageTracking_SF)

| BI_DB Column | Source Table | Logic |
|-------------|-------------|-------|
| LastContactDate | BI_DB_UsageTracking_SF | MAX(CreatedDate_SF) WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c') |
| FirstContactDate | BI_DB_UsageTracking_SF | MIN(CreatedDate_SF) WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c') |
| LastContactDate_ByPhone | BI_DB_UsageTracking_SF | MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c' |
| LastContactAttemptDate_ByPhone | (not populated by SP) | Legacy column |
| LastContactAttemptDate | (not populated by SP) | Legacy column |
| FirstContactAttemptDate | (not populated by SP) | Legacy column |
| FirstContactAttemptDate_ByPhone | (not populated by SP) | Legacy column |
| FirstContactDate_ByPhone | (not populated by SP) | Legacy column |

### L. Campaign Data (3 columns — External_etoro_History_Credit)

| BI_DB Column | Source Table | Logic |
|-------------|-------------|-------|
| FirstCampaignID | External_etoro_History_Credit | CampaignID, ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Occurred)=1 |
| FirstCampaignDate | External_etoro_History_Credit | Occurred (first campaign) |
| FirstCampaignAmount | External_etoro_History_Credit | Payment (first campaign) |

### M. Verification & Compliance (9 columns)

| BI_DB Column | Source Table | Logic |
|-------------|-------------|-------|
| VerificationLevel1Date | Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) WHERE VerificationLevelID=1 |
| VerificationLevel2Date | Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) WHERE VerificationLevelID=2 |
| VerificationLevel3Date | Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) WHERE VerificationLevelID=3 |
| EmailVerifiedDate | Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) WHERE IsEmailVerified=1 |
| EvMatchStatusDate | Fact_SnapshotCustomer + Dim_Range | MIN(FromDateID) WHERE EvMatchStatus=2 |
| PhoneVerifiedDate | External History.BackOfficeCustomer | MIN(ValidFrom) WHERE PhoneVerifiedID IN (1,2) |
| KycModeID | External ComplianceStateDB | CustomerKycMode.KycModeID via GCID |
| ProfessionalApplicationDate | External ComplianceStateDB | CustomerProfessionalQuestionnaireResult.ApplicationDate via GCID |
| FirstInstallDate | BI_DB_AppFlyer_Reports + External_MarketPerformance_Tracking_Customer | MIN(EventTime) WHERE EventName='install', linked via AppsFlyerID |

### N. Funded Status (3 columns — Functions)

| BI_DB Column | Source | Logic |
|-------------|--------|-------|
| IsFundedNew | Function_Population_Funded(@dateINT) | 1 if RealCID returned by function (depositor + verified + traded + equity > 0), else 0 |
| FirstNewFundedDate | Function_Population_First_Time_Funded() | GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)) |
| LastNewFundedDate | BI_DB_DDR_Customer_Daily_Status + Function_Population_Funded | COALESCE(yesterday funded, MAX(Date) WHERE IsFunded=1 from DDR) |

### O. ETL-Computed Flags (3 columns)

| BI_DB Column | Logic |
|-------------|-------|
| FTDIsLessThanAWeek | CASE WHEN DATEDIFF(DAY,registered,FirstDepositDate) < 8 AND FirstDepositAmount > 0 THEN 1 ELSE 0 |
| IsAirDropBefore | 1 if CID exists in Fact_CustomerAction WHERE IsAirDrop=1 AND ActionTypeID=1 AND InstrumentTypeID=5 AND FirstDepositDate IS NOT NULL |
| UpdateDate | GETDATE() — ETL metadata |

### P. Social/Legacy Events (2 columns — Fact_CustomerAction #fca)

| BI_DB Column | Source | Logic |
|-------------|--------|-------|
| LastPublishedPostDate | Fact_CustomerAction | MAX(Occurred) WHERE ActionTypeID=21 |
| LastActionDateForLifeStage | Fact_CustomerAction | MAX(Occurred) WHERE ActionTypeID IN (1,15,17) |

### Q. Not Populated / Disabled / Nullified Columns (29 columns)

| BI_DB Column | Status | Notes |
|-------------|--------|-------|
| SocialConnect | Disabled | Social connect section commented out (linked server removed) |
| KYC | Nullified | Nullified 2022-02-22 by Guy Manova |
| DocsOK | Not populated | Legacy column, not set by SP |
| IsSales | Not populated | Legacy column |
| HasPic | Not populated | Legacy column |
| Bankruptcy | Nullified | Nullified 2022-02-22 |
| FirstTimeUser | Not populated | Legacy column |
| FirstDemoLoggedIn | Disabled | Demo step disabled 2017-01-26 |
| FirstDemoPosOpenDate | Disabled | Demo step disabled |
| FirstDemoMirrorRegistrationDate | Disabled | Demo step disabled |
| LastDemoMirrorRegistrationDate | Disabled | Demo step disabled |
| FirstDemoMirrorPosOpenDate | Disabled | Demo step disabled |
| FirstEngagementDate | Disabled | Engagement section commented out |
| FirstLeadDate | Nullified | Nullified 2022-02-22 |
| LastDemoLoggedIn | Disabled | Demo step disabled |
| LastDemoMirrorPosOpenDate | Disabled | Demo step disabled |
| LastDemoPosOpenDate | Disabled | Demo step disabled |
| LastEngagementDate | Disabled | Engagement section commented out |
| CertifiedGuru | Not populated | Legacy column |
| FirstTimeSocialConnect | Disabled | Social connect section disabled |
| PremiumAccount | Not populated | Legacy column |
| Evangelist | Not populated | Legacy column |
| FirstToThirtyDayRetained | Not populated | Legacy column |
| FirstWallEngagement | Not populated | Legacy column |
| FeedUnBlocked | Not populated | Legacy column |
| FeedUnlocked | Not populated | Legacy column |
| Follow5UsersDate | Not populated | Legacy column |
| NumberOfUsersFollowed | Not populated | Legacy column |
| PopularInvestor | Not populated | Legacy column |
| SuitabilityTestCompletedAt | Nullified | Nullified 2022-02-22 |
| PassedSuitabilityTest | Nullified | Nullified 2022-02-22 |
| Model_FTDsOTDs | Not populated | ML model score — legacy |
| Model_Leads | Not populated | ML model score — legacy |
| Model_ReDepositor | Not populated | ML model score — legacy |
| RiskGroup | Disabled | Disabled 2023-05-09 |
| DepositGroup | Disabled | Disabled 2023-05-09 |
| PEPCreatedTime | Nullified | Nullified 2022-02-22 |
| PEPStatusUpdatedDate | Nullified | Nullified 2022-02-22 |
| isPassedPEP | Nullified | Nullified 2022-02-22 |
| PEPStatusID | Nullified | Nullified 2022-02-22 |
| SevenDayRetained | Not populated | Legacy retention metric |
| FirstToSevenDayRetained | Not populated | Legacy retention metric |
| FirstDateRetained | Not populated | Legacy retention metric |
| SignedW8Date | Disabled | Disabled 2022-02-29 |
| LastCampaignSentDate | Not populated | Legacy column |

---
*Generated: 2026-03-20 | Phases: P9 + P13*
