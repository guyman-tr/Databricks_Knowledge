# Lineage: BI_DB_dbo.BI_DB_CIDFirstDates

## Source Objects

| Source Object | Schema | Role | Join Key |
|--------------|--------|------|----------|
| Dim_Customer | DWH_dbo | Core customer attributes (identity, demographics, registration, acquisition) | RealCID = CID |
| Dim_State_and_Province | DWH_dbo | State/province name from IP region | RegionID = RegionByIP_ID |
| Dim_Funnel | DWH_dbo | Funnel name lookup | FunnelID |
| Dim_Label | DWH_dbo | White-label brand name | LabelID |
| Dim_Country | DWH_dbo | Country name, region, desk, marketing region | CountryID |
| Dim_Language | DWH_dbo | Platform language name | LanguageID |
| Dim_Affiliate | DWH_dbo | Affiliate partner → SubChannelID | AffiliateID |
| Dim_Channel | DWH_dbo | Channel/SubChannel classification | SubChannelID |
| Dim_PlayerLevel | DWH_dbo | Club/tier name | PlayerLevelID |
| Dim_PlayerStatus | DWH_dbo | Account restriction state | PlayerStatusID |
| Dim_VerificationLevel | DWH_dbo | KYC verification level ID | VerificationLevelID = DWHVerificationLevelID |
| Dim_Manager | DWH_dbo | Account manager name (FirstName + LastName) | ManagerID = AccountManagerID |
| Fact_CustomerAction | DWH_dbo | First/last event dates (login, deposit, position, cashout, mirror, stocks, social) | RealCID = CID, ActionTypeID filter |
| Fact_FirstCustomerAction | DWH_dbo | First deposit attempt data | RealCID, ActionTypeID=27 |
| Fact_BillingDeposit | DWH_dbo | First/last deposit details (processor, funding type, amount) | CID, DepositID |
| Dim_FundingType | DWH_dbo | Payment method name for deposits | FundingTypeID |
| Dim_BillingDepot | DWH_dbo | Deposit processor name | DepotID |
| V_Liabilities | DWH_dbo | Credit and RealizedEquity snapshot | CID, DateID |
| Dim_Mirror | DWH_dbo | First/last time being copied | ParentCID |
| BI_DB_UsageTracking_SF | BI_DB_dbo | Contact dates from Salesforce CRM | CID |
| Fact_SnapshotCustomer | DWH_dbo | Verification level dates, email verified date, EvMatchStatus date | RealCID |
| Dim_Range | DWH_dbo | Date range decode for snapshot | DateRangeID |
| BI_DB_AppFlyer_Reports | BI_DB_dbo | First mobile install date | AppsFlyerID (via tracking customer mapping) |
| External_ComplianceStateDB_Compliance_CustomerKycMode | BI_DB_dbo | KYC mode ID | GCID |
| External_ComplianceStateDB_Compliance_CustomerProfessionalQuestionnaireResult | BI_DB_dbo | Professional application date | GCID |
| Function_Population_Funded | BI_DB_dbo | IsFundedNew flag | RealCID |
| Function_Population_First_Time_Funded | BI_DB_dbo | FirstNewFundedDate | RealCID |
| BI_DB_DDR_Customer_Daily_Status | BI_DB_dbo | LastNewFundedDate (max funded date) | RealCID |
| Dim_Instrument | DWH_dbo | InstrumentTypeID for airdrop detection | InstrumentID |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| CID | Dim_Customer | RealCID | Passthrough (rename) | T1 |
| GCID | Dim_Customer | GCID | Passthrough | T1 |
| OriginalCID | Dim_Customer | OriginalCID | Passthrough | T1 |
| UserName | Dim_Customer | UserName | Passthrough | T1 |
| Club | Dim_PlayerLevel | Name | Dim-lookup passthrough via Dim_Customer.PlayerLevelID | T1 |
| SerialID | Dim_Customer | AffiliateID | Passthrough (rename) | T1 |
| Channel | Dim_Channel | Channel | Dim-lookup passthrough via Dim_Affiliate.SubChannelID; ISNULL default 'Direct' | T1 |
| SubChannel | Dim_Channel | SubChannel | Dim-lookup passthrough via Dim_Affiliate.SubChannelID; ISNULL default 'Direct' | T1 |
| LabelName | Dim_Label | Name | Dim-lookup passthrough via Dim_Customer.LabelID | T1 |
| Country | Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID | T1 |
| Language | Dim_Language | Name | Dim-lookup passthrough via Dim_Customer.LanguageID | T1 |
| Region | Dim_Country | Region | Dim-lookup passthrough via Dim_Customer.CountryID | T2 |
| PotentialDesk | Dim_Country | Desk | Dim-lookup passthrough via Dim_Customer.CountryID | T1 |
| Email | Dim_Customer | Email | Passthrough | T1 |
| Credit | V_Liabilities | Credit | Daily snapshot value | T1 |
| RealizedEquity | V_Liabilities | RealizedEquity | Daily snapshot value | T1 |
| SocialConnect | — | — | Deprecated (not updated since Sep 2018) | T3 |
| Verified | Dim_VerificationLevel | ID | Dim-lookup passthrough via Dim_Customer.VerificationLevelID | T1 |
| KYC | — | — | Deprecated (nullified 2022-02-22) | T3 |
| DocsOK | — | — | Deprecated (nullified 2022-02-22) | T3 |
| Blocked | Dim_Customer | PlayerStatusID | ETL-computed: CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0 | T2 |
| IsSales | — | — | Deprecated | T3 |
| HasPic | — | — | Deprecated | T3 |
| Bankruptcy | — | — | Deprecated (nullified 2022-02-22) | T3 |
| FunnelName | Dim_Funnel | Name | Dim-lookup passthrough via Dim_Customer.FunnelID | T1 |
| DownloadID | Dim_Customer | DownloadID | Passthrough | T1 |
| registered | Dim_Customer | RegisteredDemo, RegisteredReal | ETL-computed: MIN(RegisteredDemo, RegisteredReal) | T2 |
| FirstTimeUser | — | — | Deprecated | T3 |
| FirstLoggedIn | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=14 | T2 |
| FirstDemoLoggedIn | — | — | Deprecated (demo disabled 2017-01-26) | T3 |
| FirstDemoPosOpenDate | — | — | Deprecated | T3 |
| FirstDemoMirrorRegistrationDate | — | — | Deprecated | T3 |
| LastDemoMirrorRegistrationDate | — | — | Deprecated | T3 |
| FirstDemoMirrorPosOpenDate | — | — | Deprecated | T3 |
| FirstCashierLogin | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=29 | T2 |
| FirstDepositAttempt | Fact_FirstCustomerAction | FirstOccurred | MIN(FirstOccurred) WHERE ActionTypeID=27 | T2 |
| FirstDepositAttemptAmount | Fact_FirstCustomerAction | Amount | Amount from first deposit attempt | T2 |
| FirstDepositAttemptProcessor | Fact_BillingDeposit → Dim_BillingDepot | Name | Depot name for first attempt deposit | T2 |
| FirstDepositAttemptFundingType | Fact_BillingDeposit → Dim_FundingType | Name | Funding type name for first attempt | T2 |
| FirstDepositDate | Dim_Customer | FirstDepositDate | Passthrough (via FTDTransactionID join to Fact_BillingDeposit) | T2 |
| FirstDepositProcessor | Fact_BillingDeposit → Dim_BillingDepot | Name | Depot name for FTD | T2 |
| FirstDepositFundingType | Fact_BillingDeposit → Dim_FundingType | Name | Funding type name for FTD | T2 |
| FirstDepositAmount | Dim_Customer | FirstDepositAmount | Passthrough | T2 |
| FirstEngagementDate | — | — | Deprecated (engagement section disabled) | T3 |
| FirstPosOpenDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID IN (1,2) | T2 |
| FirstMirrorRegistrationDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=17 | T2 |
| LastMirrorRegistrationDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=17 | T2 |
| FirstMirrorPosOpenDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=2 | T2 |
| FirstLeadDate | — | — | Deprecated (set to 1900-01-01 sentinel) | T3 |
| FirstDepositAmountExtended | — | — | Not populated by current SP | T3 |
| ReferralID | Dim_Customer | ReferralID | Passthrough | T1 |
| LastDemoLoggedIn | — | — | Deprecated | T3 |
| LastDemoMirrorPosOpenDate | — | — | Deprecated | T3 |
| LastDemoPosOpenDate | — | — | Deprecated | T3 |
| LastEngagementDate | — | — | Deprecated (engagement section disabled) | T3 |
| LastLoggedIn | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=14 | T2 |
| LastMirrorPosOpenDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=2 | T2 |
| LastPosOpenDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID IN (1,2) | T2 |
| CertifiedGuru | — | — | Deprecated | T3 |
| FirstTimeBeingCopied | Dim_Mirror | OpenOccurred | MIN(OpenOccurred) per ParentCID | T2 |
| LastTimeBeingCopied | Dim_Mirror | OpenOccurred | MAX(OpenOccurred) per ParentCID | T2 |
| Gender | Dim_Customer | Gender | Passthrough | T1 |
| CountryID | Dim_Customer | CountryID | Passthrough | T1 |
| FirstMenualPosOpenDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=1 | T2 |
| BirthDate | Dim_Customer | BirthDate | Passthrough | T1 |
| CommunicationLanguage | Dim_Language | Name | Dim-lookup via CommunicationLanguageID | T1 |
| LastMenualPosOpenDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=1 | T2 |
| FirstTimeSocialConnect | — | — | Deprecated | T3 |
| LastCashierLogin | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=29 | T2 |
| FirstCashoutDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=8 | T2 |
| FunnelFromName | Dim_Funnel | Name | Dim-lookup via FunnelFromID | T1 |
| BannerID | Dim_Customer | BannerID | Passthrough | T1 |
| SubAffiliateID | Dim_Customer | SubSerialID | Passthrough (rename) | T1 |
| FirstCampaignID | External History.Credit | CampaignID | First campaign by Occurred | T2 |
| FirstCampaignDate | External History.Credit | Occurred | First campaign date | T2 |
| FirstCampaignAmount | External History.Credit | Payment | First campaign payment amount | T2 |
| FirstStocksOpenDate | Fact_CustomerAction | Occurred | MIN(Occurred) WHERE ActionTypeID=34 | T2 |
| SevenDayRetained | — | — | Deprecated | T3 |
| FirstToSevenDayRetained | — | — | Deprecated | T3 |
| FirstDateRetained | — | — | Deprecated | T3 |
| LastContactAttemptDate_ByPhone | — | — | Not updated by current SP | T3 |
| LastContactDate | BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CreatedDate_SF) WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c') | T2 |
| LastContactAttemptDate | — | — | Not updated by current SP | T3 |
| LastContactDate_ByPhone | BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c' | T2 |
| FirstContactAttemptDate | — | — | Not updated by current SP | T3 |
| FirstContactAttemptDate_ByPhone | — | — | Not updated by current SP | T3 |
| FirstContactDate | BI_DB_UsageTracking_SF | CreatedDate_SF | MIN(CreatedDate_SF) WHERE ActionName IN successful contact | T2 |
| FirstContactDate_ByPhone | — | — | Not updated by current SP | T3 |
| PremiumAccount | — | — | Deprecated (nullified 2022-02-22) | T3 |
| Evangelist | — | — | Deprecated (nullified 2022-02-22) | T3 |
| FirstToThirtyDayRetained | — | — | Deprecated | T3 |
| FirstWallEngagement | — | — | Deprecated | T3 |
| FeedUnBlocked | — | — | Deprecated | T3 |
| PrivacyPolicyID | Dim_Customer | PrivacyPolicyID | Passthrough | T1 |
| IP | Dim_Customer | IP | Passthrough | T1 |
| FeedUnlocked | — | — | Deprecated | T3 |
| Follow5UsersDate | — | — | Deprecated | T3 |
| NumberOfUsersFollowed | — | — | Deprecated | T3 |
| PopularInvestor | — | — | Deprecated | T3 |
| Manager | Dim_Manager | FirstName + ' ' + LastName | Concatenation of manager names | T2 |
| SuitabilityTestCompletedAt | — | — | Deprecated (nullified 2022-02-22) | T3 |
| PassedSuitabilityTest | — | — | Deprecated (nullified 2022-02-22) | T3 |
| Model_FTDsOTDs | — | — | Deprecated | T3 |
| Model_Leads | — | — | Deprecated | T3 |
| LastDepositDate | Fact_BillingDeposit | ModificationDate | Last deposit modification date | T2 |
| LastDepositAmount | Fact_BillingDeposit | Amount * ExchangeRate | Last deposit amount in USD | T2 |
| LastDepositFundingType | Dim_FundingType | Name | Funding type of last deposit | T2 |
| Model_ReDepositor | — | — | Deprecated | T3 |
| RegulationID | Dim_Customer | RegulationID | Passthrough | T1 |
| RiskGroup | — | — | Deprecated (disabled 2023-05-09) | T3 |
| DepositGroup | — | — | Deprecated (disabled 2023-05-09) | T3 |
| UpdateDate | — | — | ETL-computed: GETDATE() | T2 |
| VerificationLevel1Date | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(FromDateID) WHERE VerificationLevelID=1 | T2 |
| VerificationLevel2Date | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(FromDateID) WHERE VerificationLevelID=2 | T2 |
| VerificationLevel3Date | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(FromDateID) WHERE VerificationLevelID=3 | T2 |
| EmailVerifiedDate | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(FromDateID) WHERE IsEmailVerified=1 | T2 |
| FirstInstallDate | BI_DB_AppFlyer_Reports | EventTime | MIN(EventTime) WHERE EventName='install' via AppsFlyerID mapping | T2 |
| EvMatchStatusDate | Fact_SnapshotCustomer + Dim_Range | FromDateID | MIN(FromDateID) WHERE EvMatchStatus=2 | T2 |
| State | Dim_State_and_Province | Name | Dim-lookup via Dim_Customer.RegionID = RegionByIP_ID | T2 |
| PhoneVerifiedDate | External BackOffice.Customer history | ValidFrom | MIN(ValidFrom) WHERE PhoneVerifiedID IN (1,2) | T2 |
| KycModeID | External ComplianceStateDB.CustomerKycMode | KycModeID | Passthrough via GCID | T2 |
| PEPCreatedTime | — | — | Deprecated (nullified 2022-02-22) | T3 |
| PEPStatusUpdatedDate | — | — | Deprecated (nullified 2022-02-22) | T3 |
| isPassedPEP | — | — | Deprecated (nullified 2022-02-22) | T3 |
| PEPStatusID | — | — | Deprecated (nullified 2022-02-22) | T3 |
| EvMatchStatus | Dim_Customer | EvMatchStatus | Passthrough | T1 |
| FTDIsLessThanAWeek | SP_CIDFirstDates | registered, FirstDepositDate, FirstDepositAmount | ETL-computed: CASE WHEN DATEDIFF(DAY,registered,FirstDepositDate)<8 AND FirstDepositAmount>0 THEN 1 ELSE 0 | T2 |
| DesignatedRegulationID | Dim_Customer | DesignatedRegulationID | Passthrough | T1 |
| ProfessionalApplicationDate | External ComplianceStateDB ProfessionalQuestionnaire | ApplicationDate | Passthrough | T2 |
| LastCampaignSentDate | — | — | Not actively updated by current SP in provided code | T3 |
| NewMarketingRegion | Dim_Country | MarketingRegionManualName | Dim-lookup passthrough | T1 |
| IsFundedNew | Function_Population_Funded | RealCID membership | ETL-computed: 1 if in Function_Population_Funded result set, else 0 | T1 |
| FirstNewFundedDate | Function_Population_First_Time_Funded | FirstFundedDate | Passthrough | T1 |
| LastNewFundedDate | BI_DB_DDR_Customer_Daily_Status + Function_Population_Funded | MAX(Date) WHERE IsFunded=1 | COALESCE of DDR history and current funded | T2 |
| IsAirDropBefore | Fact_CustomerAction + Dim_Instrument | IsAirDrop, InstrumentTypeID | ETL-computed: 1 if stock airdrop position in last 30 days and is depositor | T2 |
| SignedW8Date | — | — | Not actively updated by current SP | T3 |
| LastCashoutDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=8 | T2 |
| LastPublishedPostDate | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID=21 (as DATE) | T2 |
| LastActionDateForLifeStage | Fact_CustomerAction | Occurred | MAX(Occurred) WHERE ActionTypeID IN (1,15,17) (as DATE) | T2 |
