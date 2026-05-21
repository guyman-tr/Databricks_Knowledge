# Function_Revenue_TicketFeeByPercent

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 37 (T1: 32, T2: 5) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Percent-based ticket markup from `Fact_History_Cost` (cost subtype 4, calculation types 4 and 7 for DLT edge cases), joined to distribution for open vs close context; amounts before 2025-05-25 are zeroed so mistaken prod bookings stay in flat ticket fees. Output includes SQF tagging and margin settlement flags.

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
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_History_Cost | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID | Direct | T1 |
| 2 | Occurred | Fact_History_Cost.Occurred | Direct | T2 |
| 3 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Direct | T1 |
| 4 | PositionID | Fact_History_Cost.PositionID | Direct | T2 |
| 5 | DateID | Fact_History_Cost.DateID | Direct | T2 |
| 6 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | Direct | T5 |
| 7 | MirrorID | Fact_History_Cost.MirrorID | Direct | T2 |
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
| 29 | TicketFeeByPercent | Fact_History_Cost.ValueInAccountCurrency | `CASE WHEN DateID < 20250525 THEN 0 ELSE ValueInAccountCurrency END` AS TicketFeeByPercent WHERE `CostSubTypeID = 4`, `CalculationTypeID IN (4,7)`, `ISNULL(ValueInAccountCurrency,0) > 0`, `DateID BETWEEN @sdateInt AND @edateInt`; **Open branch:** `OperationTypeID IN (14,24)` and join `fcapd.TicketFeeAction = 'Open'`; **Close branch:** `OperationTypeID IN (12,13)` and `TicketFeeAction = 'Close'` | T2 |
| 30 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | Direct | T1 |
| 31 | IsCopy | Fact_History_Cost.MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | T2 |
| 32 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 33 | TicketFeeByPercentAction | — | Literal 'Open' or 'Close' by branch | T2 |
| 34 | IsFuture | Dim_Instrument.IsFuture | Direct | T2 |
| 35 | SettlementTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | Direct | T1 |
| 36 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 37 | IsSQF | Function_Instrument_Snapshot_Enriched.InstrumentID | CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-05-02 | Guy M | Note: mistaken % ticket fees in prod booked as regular ticket fees; pre-20250525 forced to 0 here |
| 2025-06-04 | Guy M | Bugfix: date range and valid customer params |
| 2025-06-04 | Guy M | Bugfix: separate open/close joins |
| 2025-06-14 | Guy M | DLT edge case: CalculationTypeID 7 |
| 2025-06-23 | Guy M | Add IsSQF |
| 2025-09-11 | Guy M | Add SettlementTypeID |
| 2025-10-15 | Guy M | Add IsMarginTrade |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
