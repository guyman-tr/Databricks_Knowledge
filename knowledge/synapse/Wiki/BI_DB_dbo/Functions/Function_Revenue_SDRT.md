# Function_Revenue_SDRT

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 34 (T1: 31, T2: 3) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns UK **SDRT** (Stamp Duty Reserve Tax) style fee rows from the customer action position distribution (`ActionTypeID` 35, `IsFeeDividend` 3), with amount flipped to revenue sign as `SDRT`, copy and margin flags, and instrument type from `Dim_Instrument`. (SQL header comment refers generically to dividend/fee distribution; business filter is `IsFeeDividend` = 3.)

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
| 5 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID | Direct | T2 |
| 6 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | Direct | T5 |
| 7 | MirrorID | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID | Direct | T1 |
| 8 | Leverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage | Direct | T1 |
| 9 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop | Direct | T2 |
| 10 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID | Direct | T2 |
| 11 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID | Direct | T2 |
| 12 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID | Direct | T2 |
| 13 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID | Direct | T2 |
| 14 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID | Direct | T2 |
| 15 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID | Direct | T2 |
| 16 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID | Direct | T2 |
| 17 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID | Direct | T2 |
| 18 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID | Direct | T2 |
| 19 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID | Direct | T2 |
| 20 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID | Direct | T2 |
| 21 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID | Direct | T2 |
| 22 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID | Direct | T2 |
| 23 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor | Direct | T2 |
| 24 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID | Direct | T2 |
| 25 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID | Direct | T2 |
| 26 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer | Direct | T2 |
| 27 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB | Direct | T2 |
| 28 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID | Direct | T2 |
| 29 | SDRT | BI_DB_Fact_Customer_Action_Position_Distribution.Amount | -1 * Amount WHERE ActionTypeID = 35 AND IsFeeDividend = 3 | T2 |
| 30 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | Direct | T1 |
| 31 | IsCopy | BI_DB_Fact_Customer_Action_Position_Distribution | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | T2 |
| 32 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 33 | SettlementTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | Direct | T1 |
| 34 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 20250309 | Guy M | Added IsFutures (instrument typing via Dim_Instrument) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
