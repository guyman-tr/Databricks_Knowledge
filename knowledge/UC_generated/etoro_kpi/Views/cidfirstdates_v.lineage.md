# Column Lineage: main.etoro_kpi.cidfirstdates_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.cidfirstdates_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\cidfirstdates_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\cidfirstdates_v.json` (rows: 105, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   ←── primary upstream
  + main.general.bronze_etoro_dictionary_regulation   (JOIN)
        │
        ▼
main.etoro_kpi.cidfirstdates_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CID` | `passthrough` | — | CID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `GCID` | `passthrough` | — | GCID |
| 3 | `OriginalCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `OriginalCID` | `passthrough` | — | OriginalCID |
| 4 | `UserName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `UserName` | `passthrough` | — | UserName |
| 5 | `Club` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Club` | `passthrough` | — | Club |
| 6 | `SerialID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SerialID` | `passthrough` | — | SerialID |
| 7 | `Channel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Channel` | `passthrough` | — | Channel |
| 8 | `SubChannel` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SubChannel` | `passthrough` | — | SubChannel |
| 9 | `LabelName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LabelName` | `passthrough` | — | LabelName |
| 10 | `Country` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Country` | `passthrough` | — | Country |
| 11 | `Language` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Language` | `passthrough` | — | Language |
| 12 | `Region` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Region` | `passthrough` | — | Region |
| 13 | `PotentialDesk` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `PotentialDesk` | `passthrough` | — | PotentialDesk |
| 14 | `Email` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Email` | `passthrough` | — | Email |
| 15 | `Credit` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Credit` | `passthrough` | — | Credit |
| 16 | `RealizedEquity` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `RealizedEquity` | `passthrough` | — | RealizedEquity |
| 17 | `SocialConnect` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SocialConnect` | `passthrough` | — | SocialConnect |
| 18 | `Verified` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Verified` | `passthrough` | — | Verified |
| 19 | `KYC` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `KYC` | `passthrough` | — | KYC |
| 20 | `DocsOK` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `DocsOK` | `passthrough` | — | DocsOK |
| 21 | `Blocked` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Blocked` | `passthrough` | — | Blocked |
| 22 | `IsSales` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `IsSales` | `passthrough` | — | IsSales |
| 23 | `HasPic` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `HasPic` | `passthrough` | — | HasPic |
| 24 | `Bankruptcy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Bankruptcy` | `passthrough` | — | Bankruptcy |
| 25 | `FunnelName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FunnelName` | `passthrough` | — | FunnelName |
| 26 | `DownloadID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `DownloadID` | `passthrough` | — | DownloadID |
| 27 | `registered` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `registered` | `passthrough` | — | registered |
| 28 | `FirstTimeUser` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstTimeUser` | `passthrough` | — | FirstTimeUser |
| 29 | `FirstLoggedIn` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstLoggedIn` | `passthrough` | — | FirstLoggedIn |
| 30 | `FirstDemoLoggedIn` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDemoLoggedIn` | `passthrough` | — | FirstDemoLoggedIn |
| 31 | `FirstDemoPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDemoPosOpenDate` | `passthrough` | — | FirstDemoPosOpenDate |
| 32 | `FirstDemoMirrorRegistrationDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDemoMirrorRegistrationDate` | `passthrough` | — | FirstDemoMirrorRegistrationDate |
| 33 | `LastDemoMirrorRegistrationDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDemoMirrorRegistrationDate` | `passthrough` | — | LastDemoMirrorRegistrationDate |
| 34 | `FirstDemoMirrorPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDemoMirrorPosOpenDate` | `passthrough` | — | FirstDemoMirrorPosOpenDate |
| 35 | `FirstCashierLogin` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCashierLogin` | `passthrough` | — | FirstCashierLogin |
| 36 | `FirstDepositAttempt` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAttempt` | `passthrough` | — | FirstDepositAttempt |
| 37 | `FirstDepositAttemptAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAttemptAmount` | `passthrough` | — | FirstDepositAttemptAmount |
| 38 | `FirstDepositAttemptProcessor` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAttemptProcessor` | `passthrough` | — | FirstDepositAttemptProcessor |
| 39 | `FirstDepositAttemptFundingType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAttemptFundingType` | `passthrough` | — | FirstDepositAttemptFundingType |
| 40 | `FirstDepositDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositDate` | `passthrough` | — | FirstDepositDate |
| 41 | `FirstDepositProcessor` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositProcessor` | `passthrough` | — | FirstDepositProcessor |
| 42 | `FirstDepositFundingType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositFundingType` | `passthrough` | — | FirstDepositFundingType |
| 43 | `FirstDepositAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAmount` | `passthrough` | — | FirstDepositAmount |
| 44 | `FirstEngagementDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstEngagementDate` | `passthrough` | — | FirstEngagementDate |
| 45 | `FirstPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstPosOpenDate` | `passthrough` | — | FirstPosOpenDate |
| 46 | `FirstMirrorRegistrationDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstMirrorRegistrationDate` | `passthrough` | — | FirstMirrorRegistrationDate |
| 47 | `LastMirrorRegistrationDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastMirrorRegistrationDate` | `passthrough` | — | LastMirrorRegistrationDate |
| 48 | `FirstMirrorPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstMirrorPosOpenDate` | `passthrough` | — | FirstMirrorPosOpenDate |
| 49 | `FirstLeadDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstLeadDate` | `passthrough` | — | FirstLeadDate |
| 50 | `FirstDepositAmountExtended` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDepositAmountExtended` | `passthrough` | — | FirstDepositAmountExtended |
| 51 | `ReferralID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `ReferralID` | `passthrough` | — | ReferralID |
| 52 | `LastDemoLoggedIn` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDemoLoggedIn` | `passthrough` | — | LastDemoLoggedIn |
| 53 | `LastDemoMirrorPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDemoMirrorPosOpenDate` | `passthrough` | — | LastDemoMirrorPosOpenDate |
| 54 | `LastDemoPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastDemoPosOpenDate` | `passthrough` | — | LastDemoPosOpenDate |
| 55 | `LastEngagementDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastEngagementDate` | `passthrough` | — | LastEngagementDate |
| 56 | `LastLoggedIn` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastLoggedIn` | `passthrough` | — | LastLoggedIn |
| 57 | `LastMirrorPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastMirrorPosOpenDate` | `passthrough` | — | LastMirrorPosOpenDate |
| 58 | `LastPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastPosOpenDate` | `passthrough` | — | LastPosOpenDate |
| 59 | `CertifiedGuru` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CertifiedGuru` | `passthrough` | — | CertifiedGuru |
| 60 | `FirstTimeBeingCopied` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstTimeBeingCopied` | `passthrough` | — | FirstTimeBeingCopied |
| 61 | `LastTimeBeingCopied` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastTimeBeingCopied` | `passthrough` | — | LastTimeBeingCopied |
| 62 | `Gender` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Gender` | `passthrough` | — | Gender |
| 63 | `CountryID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CountryID` | `passthrough` | — | CountryID |
| 64 | `FirstMenualPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstMenualPosOpenDate` | `passthrough` | — | FirstMenualPosOpenDate |
| 65 | `BirthDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `BirthDate` | `passthrough` | — | BirthDate |
| 66 | `CommunicationLanguage` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `CommunicationLanguage` | `passthrough` | — | CommunicationLanguage |
| 67 | `LastMenualPosOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastMenualPosOpenDate` | `passthrough` | — | LastMenualPosOpenDate |
| 68 | `FirstTimeSocialConnect` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstTimeSocialConnect` | `passthrough` | — | FirstTimeSocialConnect |
| 69 | `LastCashierLogin` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastCashierLogin` | `passthrough` | — | LastCashierLogin |
| 70 | `FirstCashoutDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCashoutDate` | `passthrough` | — | FirstCashoutDate |
| 71 | `FunnelFromName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FunnelFromName` | `passthrough` | — | FunnelFromName |
| 72 | `BannerID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `BannerID` | `passthrough` | — | BannerID |
| 73 | `SubAffiliateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SubAffiliateID` | `passthrough` | — | SubAffiliateID |
| 74 | `FirstCampaignID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCampaignID` | `passthrough` | — | FirstCampaignID |
| 75 | `FirstCampaignDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCampaignDate` | `passthrough` | — | FirstCampaignDate |
| 76 | `FirstCampaignAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstCampaignAmount` | `passthrough` | — | FirstCampaignAmount |
| 77 | `FirstStocksOpenDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstStocksOpenDate` | `passthrough` | — | FirstStocksOpenDate |
| 78 | `SevenDayRetained` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `SevenDayRetained` | `passthrough` | — | SevenDayRetained |
| 79 | `FirstToSevenDayRetained` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstToSevenDayRetained` | `passthrough` | — | FirstToSevenDayRetained |
| 80 | `FirstDateRetained` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstDateRetained` | `passthrough` | — | FirstDateRetained |
| 81 | `LastContactAttemptDate_ByPhone` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastContactAttemptDate_ByPhone` | `passthrough` | — | LastContactAttemptDate_ByPhone |
| 82 | `LastContactDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastContactDate` | `passthrough` | — | LastContactDate |
| 83 | `LastContactAttemptDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastContactAttemptDate` | `passthrough` | — | LastContactAttemptDate |
| 84 | `LastContactDate_ByPhone` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `LastContactDate_ByPhone` | `passthrough` | — | LastContactDate_ByPhone |
| 85 | `FirstContactAttemptDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstContactAttemptDate` | `passthrough` | — | FirstContactAttemptDate |
| 86 | `FirstContactAttemptDate_ByPhone` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstContactAttemptDate_ByPhone` | `passthrough` | — | FirstContactAttemptDate_ByPhone |
| 87 | `FirstContactDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstContactDate` | `passthrough` | — | FirstContactDate |
| 88 | `FirstContactDate_ByPhone` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstContactDate_ByPhone` | `passthrough` | — | FirstContactDate_ByPhone |
| 89 | `PremiumAccount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `PremiumAccount` | `passthrough` | — | PremiumAccount |
| 90 | `Evangelist` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Evangelist` | `passthrough` | — | Evangelist |
| 91 | `FirstToThirtyDayRetained` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstToThirtyDayRetained` | `passthrough` | — | FirstToThirtyDayRetained |
| 92 | `FirstWallEngagement` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FirstWallEngagement` | `passthrough` | — | FirstWallEngagement |
| 93 | `FeedUnBlocked` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FeedUnBlocked` | `passthrough` | — | FeedUnBlocked |
| 94 | `PrivacyPolicyID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `PrivacyPolicyID` | `passthrough` | — | PrivacyPolicyID |
| 95 | `IP` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `IP` | `passthrough` | — | IP |
| 96 | `FeedUnlocked` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `FeedUnlocked` | `passthrough` | — | FeedUnlocked |
| 97 | `Follow5UsersDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Follow5UsersDate` | `passthrough` | — | Follow5UsersDate |
| 98 | `NumberOfUsersFollowed` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `NumberOfUsersFollowed` | `passthrough` | — | NumberOfUsersFollowed |
| 99 | `PopularInvestor` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `PopularInvestor` | `passthrough` | — | PopularInvestor |
| 100 | `Manager` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Manager` | `passthrough` | — | Manager |
| 101 | `RegulationName` | `main.general.bronze_etoro_dictionary_regulation` | `Name` | `join_enriched` | — | r.Name AS RegulationName |
| 102 | `RegulationID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `RegulationID` | `passthrough` | — | c.RegulationID |
| 103 | `VerificationLevel1Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel1Date` | `passthrough` | — | c.VerificationLevel1Date |
| 104 | `VerificationLevel2Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel2Date` | `passthrough` | — | c.VerificationLevel2Date |
| 105 | `VerificationLevel3Date` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `VerificationLevel3Date` | `passthrough` | — | c.VerificationLevel3Date |

## Cross-check vs system.access.column_lineage

- Total target columns: **105**
- OK: **105**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.general.bronze_etoro_dictionary_regulation AS r ON (r.ID = c.RegulationID)
