# Function_Revenue_Dividend

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 35 (T1: 32, T2: 3) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns **dividend fee** revenue rows from the distributed customer-action fact for `ActionTypeID` 35 with `IsFeeDividend` = 2, enriched with instrument type/future flags and copy/margin indicators for analytics.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_Fact_Customer_Action_Position_Distribution | BI_DB_dbo |
| Dim_Instrument | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID | Direct | T1 |
| 2 | Occurred | BI_DB_Fact_Customer_Action_Position_Distribution.Occurred | Direct | T1 |
| 3 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Direct | T1 |
| 4 | PositionID | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID | Direct | T1 |
| 5 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID | Direct | T1 |
| 6 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | Direct | T1 |
| 7 | MirrorID | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID | Direct | T1 |
| 8 | Leverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage | Direct | T1 |
| 9 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop | Direct | T1 |
| 10 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID | Direct | T1 |
| 11 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID | Direct | T1 |
| 12 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID | Direct | T1 |
| 13 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID | Direct | T1 |
| 14 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID | Direct | T1 |
| 15 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID | Direct | T1 |
| 16 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID | Direct | T1 |
| 17 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID | Direct | T1 |
| 18 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID | Direct | T1 |
| 19 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID | Direct | T1 |
| 20 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID | Direct | T1 |
| 21 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID | Direct | T1 |
| 22 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID | Direct | T1 |
| 23 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor | Direct | T1 |
| 24 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID | Direct | T1 |
| 25 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID | Direct | T1 |
| 26 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer | Direct | T1 |
| 27 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB | Direct | T1 |
| 28 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID | Direct | T1 |
| 29 | Dividend | BI_DB_Fact_Customer_Action_Position_Distribution.Amount | Amount WHERE ActionTypeID IN (35) AND IsFeeDividend = 2 | T2 |
| 30 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | Direct | T1 |
| 31 | IsCopy | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | T2 |
| 32 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 33 | IsFuture | Dim_Instrument.IsFuture | Direct | T1 |
| 34 | SettlementTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | Direct | T1 |
| 35 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 20250309 | Guy M | Added IsFutures |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
