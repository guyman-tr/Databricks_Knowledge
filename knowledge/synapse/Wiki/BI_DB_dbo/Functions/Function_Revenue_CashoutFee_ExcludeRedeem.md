# Function_Revenue_CashoutFee_ExcludeRedeem

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 45 (T1: 44, T2: 1) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns **cashout fee** (`Fact_CustomerAction.Commission`) for **ActionTypeID IN (30)** with **ISNULL(IsRedeem, 0) = 0** (cashout fees excluding redeem flows). Customer attributes come from `Fact_SnapshotCustomer` aligned to the action date via `Dim_Range`.

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
| 3 | DateID | Fact_CustomerAction.DateID | Direct | T2 |
| 4 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 5 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 6 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 7 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T2 |
| 8 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 9 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T4 |
| 10 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 11 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T4 |
| 12 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 13 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 14 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T2 |
| 15 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T4 |
| 16 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T4 |
| 17 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 18 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 19 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 20 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 21 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 22 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 23 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T2 |
| 24 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 25 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T2 |
| 26 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T2 |
| 27 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 28 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 29 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T2 |
| 30 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 31 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T2 |
| 32 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T2 |
| 33 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T2 |
| 34 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T2 |
| 35 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 36 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |
| 37 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 38 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 39 | Address | Fact_SnapshotCustomer.Address | Direct | T2 |
| 40 | Zip | Fact_SnapshotCustomer.Zip | Direct | T2 |
| 41 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T2 |
| 42 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T2 |
| 43 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T2 |
| 44 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T2 |
| 45 | CashoutFeeExcludeRedeem | Fact_CustomerAction.Commission | Commission WHERE ActionTypeID IN (30) AND ISNULL(IsRedeem, 0) = 0 | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
