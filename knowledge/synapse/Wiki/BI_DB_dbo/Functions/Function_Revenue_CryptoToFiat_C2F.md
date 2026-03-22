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
| 1 | RealCID | EXW_C2F_E2E.RealCID | Direct | T1 |
| 2 | LastModificationDate | EXW_C2F_E2E | GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) | T2 |
| 3 | LastModificationDateID | EXW_C2F_E2E | CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE), 'yyyyMMdd') AS INT) | T2 |
| 4 | TotalFeePercentage | EXW_C2F_E2E.TotalFeePercentage | TotalFeePercentage WHERE ConversionCycle = 'Full Cycle' AND CAST(FORMAT(CAST(GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime) AS DATE),'yyyyMMdd') AS INT) BETWEEN @sdateInt AND @edateInt | T2 |
| 5 | TotalFeeUSD | EXW_C2F_E2E.TotalFeeUSD | TotalFeeUSD WHERE ConversionCycle = 'Full Cycle' AND same LastModificationDateID between params (snapshot DateRange join on that date) | T2 |
| 6 | FiatAmount | EXW_C2F_E2E.FiatAmount | Direct | T1 |
| 7 | CryptoAmount | EXW_C2F_E2E.CryptoAmount | Direct | T1 |
| 8 | FiatCurrency | EXW_C2F_E2E.FiatCurrency | Direct | T1 |
| 9 | UsdAmount | EXW_C2F_E2E.UsdAmount | Direct | T1 |
| 10 | Crypto | EXW_C2F_E2E.Crypto | Direct | T1 |
| 11 | TargetPlatformID | EXW_C2F_E2E.TargetPlatformID | Direct | T1 |
| 12 | TargetPlatform | EXW_C2F_E2E.TargetPlatform | Direct | T1 |
| 13 | DepositID | EXW_C2F_E2E.DepositID | Direct | T1 |
| 14 | eMoneyTransactionID | EXW_C2F_E2E.eMoneyTransactionID | Direct | T1 |
| 15 | GCID | Fact_SnapshotCustomer.GCID | Direct | T1 |
| 16 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T1 |
| 17 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T1 |
| 18 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T1 |
| 19 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T1 |
| 20 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T1 |
| 21 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T1 |
| 22 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T1 |
| 23 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T1 |
| 24 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T1 |
| 25 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T1 |
| 26 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T1 |
| 27 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T1 |
| 28 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T1 |
| 29 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T1 |
| 30 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T1 |
| 31 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T1 |
| 32 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T1 |
| 33 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T1 |
| 34 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T1 |
| 35 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T1 |
| 36 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T1 |
| 37 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T1 |
| 38 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T1 |
| 39 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T1 |
| 40 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T1 |
| 41 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T1 |
| 42 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T1 |
| 43 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T1 |
| 44 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T1 |
| 45 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T1 |
| 46 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T1 |
| 47 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T1 |
| 48 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 49 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 50 | Address | Fact_SnapshotCustomer.Address | Direct | T1 |
| 51 | Zip | Fact_SnapshotCustomer.Zip | Direct | T1 |
| 52 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T1 |
| 53 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T1 |
| 54 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T1 |
| 55 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T1 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-12-01 | Guy M | More E2E metadata to distinguish fiats and platforms |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
