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
| 3 | DateID | Fact_CustomerAction.DateID | Direct | T2 |
| 4 | ShareLendingFeeEtoroShare | Fact_CustomerAction.Amount | Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 5 | ShareLendingFeeUserShare | Fact_CustomerAction.Amount | Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 6 | ShareLendingFeeBrokerShare | Fact_CustomerAction.Amount | Amount / ROUND(0.425,1,1) - 2 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 7 | ShareLendingGrossAmount | Fact_CustomerAction.Amount | 2 * Amount + Amount / ROUND(0.425,1,1) - 2 * Amount WHERE ActionTypeID = 36 AND CompensationReasonID = 119 | T2 |
| 8 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 9 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 10 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 11 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 12 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 13 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 14 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 15 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 16 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 17 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 18 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 19 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 20 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 21 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 22 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 23 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 24 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 25 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 26 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-05-11 | Guy M | Fixed computations (infer gross from compensation); rounding down to match BNY reporting |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
