# Function_Revenue_CryptoToFiat_C2F

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 55 (T1: 51, T2: 4) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Surfaces completed **crypto-to-fiat (C2F)** conversions from the E2E pipeline (`ConversionCycle` = `Full Cycle`), with fee and amount fields, platform metadata, and customer snapshot attributes aligned to the **last modification** date derived from the greatest of several event timestamps.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| EXW_C2F_E2E | EXW_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | EXW_C2F_E2E.RealCID | Direct | T2 |
| 2 | LastModificationDate | EXW_C2F_E2E | GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) | T2 |
| 3 | LastModificationDateID | EXW_C2F_E2E | CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT) | T2 |
| 4 | TotalFeePercentage | EXW_C2F_E2E.TotalFeePercentage | TotalFeePercentage WHERE ConversionCycle = 'Full Cycle' AND CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE),'yyyyMMdd') AS INT) BETWEEN @sdateInt AND @edateInt | T2 |
| 5 | TotalFeeUSD | EXW_C2F_E2E.TotalFeeUSD | TotalFeeUSD WHERE ConversionCycle = 'Full Cycle' AND same LastModificationDateID between params (snapshot DateRange join on that date) | T2 |
| 6 | FiatAmount | EXW_C2F_E2E.FiatAmount | Direct | T1 |
| 7 | CryptoAmount | EXW_C2F_E2E.CryptoAmount | Direct | T1 |
| 8 | FiatCurrency | EXW_C2F_E2E.FiatCurrency | Direct | T2 |
| 9 | UsdAmount | EXW_C2F_E2E.UsdAmount | Direct | T1 |
| 10 | Crypto | EXW_C2F_E2E.Crypto | Direct | T2 |
| 11 | TargetPlatformID | EXW_C2F_E2E.TargetPlatformID | Direct | T1 |
| 12 | TargetPlatform | EXW_C2F_E2E.TargetPlatform | Direct | T2 |
| 13 | DepositID | EXW_C2F_E2E.DepositID | Direct | T2 |
| 14 | eMoneyTransactionID | EXW_C2F_E2E.eMoneyTransactionID | Direct | T2 |
| 15 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 16 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 17 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 18 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T2 |
| 19 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 20 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T4 |
| 21 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 22 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T4 |
| 23 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 24 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 25 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T2 |
| 26 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T4 |
| 27 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T4 |
| 28 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 29 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 30 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 31 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 32 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 33 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 34 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T2 |
| 35 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 36 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T2 |
| 37 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T2 |
| 38 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 39 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 40 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T2 |
| 41 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 42 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T2 |
| 43 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T2 |
| 44 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T2 |
| 45 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T2 |
| 46 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 47 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |
| 48 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 49 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 50 | Address | Fact_SnapshotCustomer.Address | Direct | T2 |
| 51 | Zip | Fact_SnapshotCustomer.Zip | Direct | T2 |
| 52 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T2 |
| 53 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T2 |
| 54 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T2 |
| 55 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-12-01 | Guy M | More E2E metadata to distinguish fiats and platforms |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
