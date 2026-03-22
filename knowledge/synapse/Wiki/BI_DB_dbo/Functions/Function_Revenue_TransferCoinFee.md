# Function_Revenue_TransferCoinFee

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Output Columns** | 45 (T1: 44, T2: 1) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Transfer-to-coin redeem commission revenue: `Fact_CustomerAction` rows with `ActionTypeID` 30 and `IsRedeem` 1, exposed as `TransferCoinFee` from `Commission`, with full snapshot customer profile columns for segmentation.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Range | DWH_dbo |
| Fact_CustomerAction | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID | Direct | T1 |
| 2 | Occurred | Fact_CustomerAction.Occurred | Direct | T1 |
| 3 | DateID | Fact_CustomerAction.DateID | Direct | T1 |
| 4 | GCID | Fact_SnapshotCustomer.GCID | Direct | T1 |
| 5 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T1 |
| 6 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T1 |
| 7 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T1 |
| 8 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T1 |
| 9 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T1 |
| 10 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T1 |
| 11 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T1 |
| 12 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T1 |
| 13 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T1 |
| 14 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T1 |
| 15 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T1 |
| 16 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T1 |
| 17 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T1 |
| 18 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T1 |
| 19 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T1 |
| 20 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T1 |
| 21 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T1 |
| 22 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T1 |
| 23 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T1 |
| 24 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T1 |
| 25 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T1 |
| 26 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T1 |
| 27 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T1 |
| 28 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T1 |
| 29 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T1 |
| 30 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T1 |
| 31 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T1 |
| 32 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T1 |
| 33 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T1 |
| 34 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T1 |
| 35 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T1 |
| 36 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T1 |
| 37 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 38 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 39 | Address | Fact_SnapshotCustomer.Address | Direct | T1 |
| 40 | Zip | Fact_SnapshotCustomer.Zip | Direct | T1 |
| 41 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T1 |
| 42 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T1 |
| 43 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T1 |
| 44 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T1 |
| 45 | TransferCoinFee | Fact_CustomerAction.Commission | Commission AS TransferCoinFee WHERE ActionTypeID = 30 AND IsRedeem = 1 | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
