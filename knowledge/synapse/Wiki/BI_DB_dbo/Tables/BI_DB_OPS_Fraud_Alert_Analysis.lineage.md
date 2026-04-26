# Column Lineage: BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|---------------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary source — customer identity, demographics, compliance, registration | Base table (alias c/dc) |
| DWH_dbo.Dim_Country | DWH_dbo | Country name resolution (x2: Country + CountryByIP) | cc.CountryID = c.CountryID; dc1.CountryID = c.CountryIDByIP |
| DWH_dbo.Dim_Language | DWH_dbo | Language name resolution (x2: ClientLanguage + ClientCommunicationLanguage) | dl.LanguageID = c.LanguageID; dl1.LanguageID = c.CommunicationLanguageID |
| DWH_dbo.Dim_EvMatchStatus | DWH_dbo | EV match status name resolution | ems.EvMatchStatusID = c.EvMatchStatus |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Player status name resolution | ps.PlayerStatusID = c.PlayerStatusID |
| DWH_dbo.Dim_PhoneVerified | DWH_dbo | Phone verification status name | dp.PhoneVerifiedID = c.PhoneVerifiedID |
| DWH_dbo.Dim_PlayerStatusReasons | DWH_dbo | Player status reason name | psr.PlayerStatusReasonID = dc.PlayerStatusReasonID |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH_dbo | Player status sub-reason name | pssr.PlayerStatusSubReasonID = dc.PlayerStatusSubReasonID |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Club (player level) name | pl.PlayerLevelID = dc.PlayerLevelID |
| general.etoro_History_BackOfficeCustomer | general | Verification level date history | hc.CID = cc.RealCID |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | POI/POA document upload tracking | cd.CID = p.RealCID |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | BI_DB_dbo | Document type classification | cdt.DocumentID = cd.DocumentID |
| DWH_dbo.Fact_BillingDeposit | DWH_dbo | Total approved deposits | bd.CID = sr.RealCID, PaymentStatusID=2 |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | BI_DB_dbo | Total commissions (Revenue_Total) | bd.CID = sr.RealCID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough |
| FirstName | DWH_dbo.Dim_Customer | FirstName | Passthrough |
| LastName | DWH_dbo.Dim_Customer | LastName | Passthrough |
| Email | DWH_dbo.Dim_Customer | Email | Passthrough |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | Passthrough |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| ClientLanguage | DWH_dbo.Dim_Language | Name | Dim-lookup passthrough (dl.Name via c.LanguageID) |
| ClientCommunicationLanguage | DWH_dbo.Dim_Language | Name | Dim-lookup passthrough (dl1.Name via c.CommunicationLanguageID) |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough (cc.Name via c.CountryID) |
| CountryByIP | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough (dc1.Name via c.CountryIDByIP) |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | Dim-lookup passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Dim-lookup passthrough (ps.Name via c.PlayerStatusID) |
| IP | DWH_dbo.Dim_Customer | IP | Passthrough |
| FakeFirstNameFlag | DWH_dbo.Dim_Customer | FirstName | ETL-computed: CASE with 50+ LIKE patterns for gibberish, keyboard walks, repeating chars, sequential letters, digits, test/fake/demo/sample words |
| FakeLastNameFlag | DWH_dbo.Dim_Customer | LastName | ETL-computed: CASE with 40+ LIKE patterns, same logic as FakeFirstNameFlag |
| FakeEmailPatternFlag | DWH_dbo.Dim_Customer | Email | ETL-computed: CASE with disposable domain detection (mailinator, tempmail, yopmail, guerrillamail), keyboard walks, short local parts (<=4 chars), numeric-prefix local parts |
| InvalidDOBFlag | DWH_dbo.Dim_Customer | BirthDate, RegisteredReal | ETL-computed: 1 when age < 18 OR BirthDate = CAST(RegisteredReal AS DATE) |
| LanguageCountryMismatchFlag | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country | LanguageID, CommunicationLanguageID, CountryID | ETL-computed: 18-country language expectation matrix (Germany, France, Spain, Italy, UK, Russia, Turkey, Ukraine, Poland, Brazil, Mexico, China, India, Pakistan, Iran, Egypt, US, Vietnam) |
| CountryMismatchFlag | DWH_dbo.Dim_Country | Name (x2) | ETL-computed: 1 when Country != CountryByIP |
| PhoneVerifiedName | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | Dim-lookup passthrough (dp.PhoneVerifiedName via c.PhoneVerifiedID) |
| 2FA | DWH_dbo.Dim_Customer | 2FA | Passthrough |
| FailedEVMatchFlag | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | ETL-computed: 1 when EvMatchStatusName = 'NotVerified' |
| VerificationLevel3Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID = 3 |
| VerificationLevel2Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID = 2 |
| VerificationLevel1Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID = 1 |
| VerificationLeveL0Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID = 0 |
| EVMatchStatusDate | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE EvMatchStatus = 2 |
| Time_L0To_L1_Min | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: DATEDIFF(MINUTE, VerificationLeveL0Date, VerificationLevel1Date) |
| Time_L1To_L2_Min | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: DATEDIFF(MINUTE, VerificationLevel1Date, VerificationLevel2Date) |
| Time_L2To_L3_Min | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: DATEDIFF(MINUTE, VerificationLevel2Date, VerificationLevel3Date) |
| FastLOL1Flag | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: 1 when Time_L0To_L1_Min < 1 |
| FastL1L2Flag | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: 1 when Time_L1To_L2_Min < 1 |
| FastL2L3Flag | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: 1 when Time_L2To_L3_Min < 1 |
| FastEVMatchFlag | general.etoro_History_BackOfficeCustomer + DWH_dbo.Dim_Customer | ValidFrom, RegisteredReal | ETL-computed: 1 when DATEDIFF(MINUTE, RegisteredReal, EVMatchStatusDate) <= 5 |
| RepeatedIPAddressFlag | DWH_dbo.Dim_Customer | IP | ETL-computed: 1 when COUNT(DISTINCT RealCID) per IP >= 20 |
| WeightedSuspiciousScore | Multiple | Multiple | ETL-computed: sum of 15 individual fraud signal scores (0-1 each), max possible 15 |
| Combo_FastRegistration_FakeEmail | Multiple | Multiple | ETL-computed: 1 when FastL0L1Flag=1 AND FakeEmailPatternFlag=1 |
| Combo_SuspiciousDomain_FakeName | Multiple | Multiple | ETL-computed: 1 when FakeEmailPatternFlag=1 AND (FakeFirstNameFlag=1 OR FakeLastNameFlag=1) |
| Combo_IPRepeat_FakeEmail | Multiple | Multiple | ETL-computed: 1 when IPUserCount>=20 AND FakeEmailPatternFlag=1 |
| Combo_FastVerification_GeoMismatch | Multiple | Multiple | ETL-computed: 1 when CountryMismatchFlag=1 AND FastL0L1=1 AND FastL1L2=1 |
| ClusteredIP_RegistrationFlag | DWH_dbo.Dim_Customer | IP, RegisteredReal | ETL-computed: 1 when same IP has >=20 registrations within same minute |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| CountryTimeClustersFlag | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country | CountryID, CountryIDByIP, RegisteredReal | ETL-computed: 1 when Country+CountryByIP+Minute cluster has >10 registrations |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Dim-lookup passthrough (psr.Name via dc.PlayerStatusReasonID) |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Dim-lookup passthrough (pssr.PlayerStatusSubReasonName via dc.PlayerStatusSubReasonID) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough (pl.Name via dc.PlayerLevelID) |
| TotalDeposits | DWH_dbo.Fact_BillingDeposit | AmountUSD | ETL-computed: SUM(AmountUSD) WHERE PaymentStatusID=2 |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Passthrough |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough |
| POIUploaded | External_etoro_BackOffice_CustomerDocument | SuggestedDocumentTypeID | ETL-computed: 1 when SuggestedDocumentTypeID=2 (Proof of Identity) exists |
| POIDefined | External_etoro_BackOffice_CustomerDocumentToDocumentType | DocumentTypeID | ETL-computed: 1 when DocumentTypeID=2 (Proof of Identity) exists |
| POAUploaded | External_etoro_BackOffice_CustomerDocument | SuggestedDocumentTypeID | ETL-computed: 1 when SuggestedDocumentTypeID=1 (Proof of Address) exists |
| POADefined | External_etoro_BackOffice_CustomerDocumentToDocumentType | DocumentTypeID | ETL-computed: 1 when DocumentTypeID=1 (Proof of Address) exists |
| UpdateDate | — | — | ETL-computed: GETDATE() |
