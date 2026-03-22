# Function_Revenue_TicketFee

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

Ticket fee revenue with open/close context: before 2025-05-25 from distribution rows (`ActionTypeID` 35, `IsFeeDividend` 4); on/after 2025-05-25 from `Fact_History_Cost` joined to distribution for open vs close ticket fee actions, with SQF tagging. Amount sign convention differs by period (negated legacy amount vs direct cost value).

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
| 2 | Occurred | BI_DB_Fact_Customer_Action_Position_Distribution.Occurred; Fact_History_Cost.Occurred | Direct (UNION branches) | T1 |
| 3 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Direct | T1 |
| 4 | PositionID | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID; Fact_History_Cost.PositionID | Direct (UNION branches) | T1 |
| 5 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID; Fact_History_Cost.DateID | Direct (UNION branches) | T1 |
| 6 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | Direct | T1 |
| 7 | MirrorID | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID; Fact_History_Cost.MirrorID | Direct (UNION branches) | T1 |
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
| 29 | TicketFee | BI_DB_Fact_Customer_Action_Position_Distribution.Amount; Fact_History_Cost.ValueInAccountCurrency | **Pre-20250525:** `-1 * Amount` WHERE `ActionTypeID = 35` AND `IsFeeDividend = 4` AND `DateID < 20250525`. **Post-20250525 Open:** `ValueInAccountCurrency` from `Fact_History_Cost` WHERE `OperationTypeID IN (14,24)`, `CostSubTypeID IN (2,6)`, `CalculationTypeID IN (3,8)`, `DateID >= 20250525`, `ISNULL(ValueInAccountCurrency,0) <> 0`, join to distribution on `TicketFeeAction = 'Open'`. **Post-20250525 Close:** same cost filters with `OperationTypeID IN (12,13)` and `TicketFeeAction = 'Close'` | T2 |
| 30 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | Direct | T1 |
| 31 | IsCopy | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID; Fact_History_Cost.MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | T2 |
| 32 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 33 | TicketFeeAction | BI_DB_Fact_Customer_Action_Position_Distribution.TicketFeeAction; — | Pre-20250525: TicketFeeAction from distribution; Post-20250525: literal 'Open' or 'Close' | T2 |
| 34 | IsFuture | Dim_Instrument.IsFuture | Direct | T1 |
| 35 | SettlementTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | Direct | T1 |
| 36 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 37 | IsSQF | Function_Instrument_Snapshot_Enriched.InstrumentID | CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2024-09-25 | Guy M | Added the ticket fee action |
| 2025-03-09 | Guy M | Add IsFuture |
| 2025-05-02 | Guy M | Different query after 2025-05-25 for fee structure |
| 2025-06-04 | Guy M | Bugfix: date range and valid customer params for post-202505 portion |
| 2025-06-04 | Guy M | Bugfix: separate open/close joins to avoid duplication |
| 2025-06-23 | Guy M | Add IsSQF; SQF cost subtype edge case |
| 2025-10-08 | Guy M | Add SettlementTypeID and margin trade |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
