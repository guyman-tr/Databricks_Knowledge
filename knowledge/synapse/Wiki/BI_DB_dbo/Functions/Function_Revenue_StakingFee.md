# Function_Revenue_StakingFee

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 61 (T1: 50, T2: 11) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Staking reward distribution economics per instrument and customer: rows from `Dealing_Staking_Results` filtered to attributed `DateID` (from `dateadd(MONTH,-1, UpdateDate)`) between `@sdateID` and `@edateID`, excluding bad `StakingMonthID` values (see `BadMonths` CTE). Normalizes month IDs (`left(StakingMonthID,6)`), splits eToro vs client USD using eligibility (`IsEligible`), and joins `Dim_Instrument` and `Fact_SnapshotCustomer` with EOM-aligned `Dim_Range` for customer attributes at month-end.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateID | INT | Start date (YYYYMMDD integer format) |
| @edateID | INT | End date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Instrument | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dealing_Staking_Results | Dealing_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | StakingMonthID | Dealing_Staking_Results | left(StakingMonthID,6) | T2 |
| 2 | Date | Dealing_Staking_Results | dateadd(MONTH,-1,UpdateDate) | T2 |
| 3 | DateID | Dealing_Staking_Results | CAST(FORMAT(CAST(dateadd(MONTH,-1,UpdateDate) AS DATE),'yyyyMMdd') as INT) | T2 |
| 4 | StakingMonth | Dealing_Staking_Results.StakingMonth | Direct | T1 |
| 5 | StakingYear | Dealing_Staking_Results.StakingYear | Direct | T1 |
| 6 | InstrumentID | Dealing_Staking_Results.InstrumentID | Direct | T1 |
| 7 | Instrument | Dim_Instrument.Name | Direct | T1 |
| 8 | CID | Dealing_Staking_Results.CID | Direct | T2 |
| 9 | IsEligible | Dealing_Staking_Results.IsEligible | Direct | T2 |
| 10 | NonEligible_PrimaryReason | Dealing_Staking_Results.NonEligible_PrimaryReason | Direct | T2 |
| 11 | IneligibleCustomerRewards | Dealing_Staking_Results.Etoro_Amount | CASE WHEN IsEligible = 0 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID (from dateadd(MONTH,-1,UpdateDate)) BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths (LEN>6 excluded) | T2 |
| 12 | RevShareCommission | Dealing_Staking_Results.Etoro_Amount | CASE WHEN IsEligible = 1 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 13 | ClientPercent | Dealing_Staking_Results | Client_Airdrop / nullif((Client_Airdrop + Etoro_Amount),0) ClientPercent | T2 |
| 14 | EtoroPercent | Dealing_Staking_Results | Etoro_Amount / nullif((Client_Airdrop + Etoro_Amount),0) EtoroPercent | T2 |
| 15 | ClientUSDDistributed | Dealing_Staking_Results.USD_Compensation | CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 16 | EtoroUSDDistributed | Dealing_Staking_Results.Etoro_Amount_USD | Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 17 | TotalUSDDistributed | Dealing_Staking_Results.USD_Compensation, Etoro_Amount_USD | CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END + Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths | T2 |
| 18 | AirDropDateID | Dealing_Staking_Results | CAST(FORMAT(CAST(AirdropOccurred AS DATE),'yyyyMMdd') as INT) | T2 |
| 19 | ActualCompensationType | Dealing_Staking_Results.ActualCompensationType | Direct | T1 |
| 20 | ClubCategory | Dealing_Staking_Results.ClubCategory | Direct | T2 |
| 21 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 22 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 23 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 24 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T2 |
| 25 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 26 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T4 |
| 27 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 28 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T4 |
| 29 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 30 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 31 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T2 |
| 32 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T4 |
| 33 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T4 |
| 34 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 35 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 36 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 37 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 38 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 39 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 40 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T2 |
| 41 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 42 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T2 |
| 43 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T2 |
| 44 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 45 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 46 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T2 |
| 47 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 48 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T2 |
| 49 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T2 |
| 50 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T2 |
| 51 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T2 |
| 52 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 53 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |
| 54 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 55 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 56 | Address | Fact_SnapshotCustomer.Address | Direct | T2 |
| 57 | Zip | Fact_SnapshotCustomer.Zip | Direct | T2 |
| 58 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T2 |
| 59 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T2 |
| 60 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T2 |
| 61 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-05-20 | Guy M | Handle bad StakingMonthID values (e.g. 20250300) by dividing by 10 / excluding long IDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
