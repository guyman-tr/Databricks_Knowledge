# Review Needed: BI_DB_dbo.BI_DB_CIDFirstDates

## Deprecated Columns (44 columns)

The following 44 columns are present in the DDL but not populated by the current SP_CIDFirstDates. They carry NULL or 0 for all rows:

1. **SocialConnect** -- source table stopped updating Sep 2018
2. **KYC** -- nullified 2022-02-22 by Guy Manova
3. **DocsOK** -- nullified 2022-02-22
4. **IsSales** -- never populated by current SP
5. **HasPic** -- never populated by current SP
6. **Bankruptcy** -- nullified 2022-02-22
7. **FirstTimeUser** -- never populated
8. **FirstDemoLoggedIn** -- demo disabled 2017-01-26
9. **FirstDemoPosOpenDate** -- demo disabled
10. **FirstDemoMirrorRegistrationDate** -- demo disabled
11. **LastDemoMirrorRegistrationDate** -- demo disabled
12. **FirstDemoMirrorPosOpenDate** -- demo disabled
13. **LastDemoLoggedIn** -- demo disabled
14. **LastDemoMirrorPosOpenDate** -- demo disabled
15. **LastDemoPosOpenDate** -- demo disabled
16. **FirstEngagementDate** -- engagement section disabled in SP
17. **LastEngagementDate** -- engagement section disabled
18. **FirstLeadDate** -- set to 1900-01-01 sentinel
19. **CertifiedGuru** -- never populated
20. **FirstTimeSocialConnect** -- source stopped updating
21. **SevenDayRetained** -- never populated
22. **FirstToSevenDayRetained** -- never populated
23. **FirstDateRetained** -- never populated
24. **PremiumAccount** -- nullified 2022-02-22
25. **Evangelist** -- nullified 2022-02-22
26. **FirstToThirtyDayRetained** -- never populated
27. **FirstWallEngagement** -- never populated
28. **FeedUnBlocked** -- never populated
29. **FeedUnlocked** -- never populated
30. **Follow5UsersDate** -- never populated
31. **NumberOfUsersFollowed** -- never populated
32. **PopularInvestor** -- never populated
33. **SuitabilityTestCompletedAt** -- nullified 2022-02-22
34. **PassedSuitabilityTest** -- nullified 2022-02-22
35. **Model_FTDsOTDs** -- ML model, not populated
36. **Model_Leads** -- ML model, not populated
37. **Model_ReDepositor** -- ML model, not populated
38. **RiskGroup** -- disabled 2023-05-09
39. **DepositGroup** -- disabled 2023-05-09
40. **PEPCreatedTime** -- nullified 2022-02-22
41. **PEPStatusUpdatedDate** -- nullified 2022-02-22
42. **isPassedPEP** -- nullified 2022-02-22
43. **PEPStatusID** -- nullified 2022-02-22
44. **SignedW8Date** -- section disabled by Boris Slutski 2022-02-29

**Recommendation**: Consider DDL cleanup to remove deprecated columns. This would reduce the table width by ~32% and improve scan performance.

## Contact Attempt Columns (4 columns)

The following 4 columns exist in the DDL but are NOT updated by the current SP:
- `LastContactAttemptDate_ByPhone`
- `LastContactAttemptDate`
- `FirstContactAttemptDate`
- `FirstContactAttemptDate_ByPhone`

These may have been populated by a previous version of the SP or a separate process. Verify if any downstream consumers still read these columns.

## FirstDepositAmountExtended

Column exists in DDL but is not populated by the current SP. Purpose unclear -- may have been intended for extended deposit tracking across platforms.

## LastCampaignSentDate

Column exists but the section that updates it appears to reference `BI_DB_SFMC_Report` which was disabled (Daniel Kaplan, 2022-05-12). Verify if a separate process updates this.

## Region vs NewMarketingRegion

Both columns exist with potentially overlapping purposes:
- `Region` = Dim_Country.Region (marketing region from MarketingRegion dictionary)
- `NewMarketingRegion` = Dim_Country.MarketingRegionManualName (manual override)

These may differ for the same country. Downstream consumers should be aware of which field they need.

## Column Name Typos

- `FirstMenualPosOpenDate` / `LastMenualPosOpenDate` -- should be "Manual" (typo preserved from original design)
