# Function_Revenue_Share_Lending

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 26 (T1: 22, T2: 4) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Surfaces share-lending compensation actions (`ActionTypeID` 36, `CompensationReasonID` 119) with customer snapshot attributes, splitting the booked `Amount` into eToro share, user share, inferred broker share, and gross using the BNY-style split formula (`round(0.425,1,1)`).

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
| 4 | ShareLendingFeeEtoroShare | Fact_CustomerAction.Amount | Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 5 | ShareLendingFeeUserShare | Fact_CustomerAction.Amount | Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 6 | ShareLendingFeeBrokerShare | Fact_CustomerAction.Amount | Amount / ROUND(0.425,1,1) - 2 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 7 | ShareLendingGrossAmount | Fact_CustomerAction.Amount | 2 * Amount + Amount / ROUND(0.425,1,1) - 2 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 8 | GCID | Fact_SnapshotCustomer.GCID | Direct | T1 |
| 9 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T1 |
| 10 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T1 |
| 11 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T1 |
| 12 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T1 |
| 13 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T1 |
| 14 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T1 |
| 15 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T1 |
| 16 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T1 |
| 17 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T1 |
| 18 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T1 |
| 19 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T1 |
| 20 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T1 |
| 21 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T1 |
| 22 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T1 |
| 23 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T1 |
| 24 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T1 |
| 25 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T1 |
| 26 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T1 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-05-11 | Guy M | Fixed computations (infer gross from compensation); rounding down to match BNY reporting |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
