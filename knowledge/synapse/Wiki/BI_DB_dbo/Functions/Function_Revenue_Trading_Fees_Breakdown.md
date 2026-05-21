# Function_Revenue_Trading_Fees_Breakdown

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Output Columns** | 34 (T1: 29, T2: 5) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Trading-fee detail from `BI_DB_Fact_Customer_Action_Position_Distribution` as two combined sets: (1) `ActionTypeID = 36` with `CompensationReasonID IN (117, 118)`, `TradingFeeName` from `Dim_CompensationReason`, and `PositionID` parsed from `Description` when the trailing token is numeric; (2) ticket-fee rows with `ActionTypeID = 35` AND `IsFeeDividend = 4`, labeled `TradingFeeName = 'TicketFee'`. Revenue sign uses `-1 * Amount` on the outer projection.

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
| Dim_CompensationReason | DWH_dbo |
| Dim_Instrument | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID | Direct | T2 |
| 2 | ActionTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.ActionTypeID | Direct | T1 |
| 3 | TradingFeeName | Dim_CompensationReason.Name; literal | `dcr.Name` WHERE `ActionTypeID = 36` AND `CompensationReasonID IN (117,118)`; literal `'TicketFee'` WHERE `ActionTypeID = 35` AND `IsFeeDividend = 4` | T2 |
| 4 | Amount | BI_DB_Fact_Customer_Action_Position_Distribution.Amount | `-1 * Amount` WHERE (`ActionTypeID = 36` AND `CompensationReasonID IN (117,118)`) OR (`ActionTypeID = 35` AND `IsFeeDividend = 4`) | T2 |
| 5 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID | Direct | T1 |
| 6 | PositionID | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID, Description | **Compensation branch:** TRY_CAST of last token of `Description`; **TicketFee branch:** `PositionID` direct WHERE `ActionTypeID = 35` AND `IsFeeDividend = 4` | T2 |
| 7 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Direct | T1 |
| 8 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 9 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | Direct | T5 |
| 10 | MirrorID | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID | Direct | T1 |
| 11 | Leverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage | Direct | T1 |
| 12 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop | Direct | T2 |
| 13 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | Direct | T1 |
| 14 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID | Direct | T2 |
| 15 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID | Direct | T2 |
| 16 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID | Direct | T2 |
| 17 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID | Direct | T2 |
| 18 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID | Direct | T2 |
| 19 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID | Direct | T2 |
| 20 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID | Direct | T2 |
| 21 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID | Direct | T2 |
| 22 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID | Direct | T2 |
| 23 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID | Direct | T2 |
| 24 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID | Direct | T2 |
| 25 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID | Direct | T2 |
| 26 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID | Direct | T2 |
| 27 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor | Direct | T2 |
| 28 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID | Direct | T2 |
| 29 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID | Direct | T2 |
| 30 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer | Direct | T2 |
| 31 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB | Direct | T2 |
| 32 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID | Direct | T2 |
| 33 | UpdateDate | BI_DB_Fact_Customer_Action_Position_Distribution.UpdateDate | Direct | T5 |
| 34 | CompensationReasonID | BI_DB_Fact_Customer_Action_Position_Distribution.CompensationReasonID | Direct | T1 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
