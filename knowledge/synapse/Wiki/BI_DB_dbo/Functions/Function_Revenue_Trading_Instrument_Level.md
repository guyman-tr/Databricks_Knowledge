# Function_Revenue_Trading_Instrument_Level

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 38 (T1: 27, T2: 11) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Combines multiple trading revenue TVFs (full commissions, rollover, ticket fees, percent ticket fees, admin fee, spot adjustment) at instrument and position grain, then adds copy-fund, IBAN, and recurring-investment flags before aggregating to customer × date × instrument × metric. Produces large datasets suitable for asset-level revenue attribution.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_CopyFund_Positions | BI_DB_dbo |
| BI_DB_Positions_Closed_To_IBAN | BI_DB_dbo |
| BI_DB_Positions_Opened_From_IBAN | BI_DB_dbo |
| BI_DB_RecurringInvestment_Positions | BI_DB_dbo |
| BI_DB_Fact_Customer_Action_Position_Distribution | BI_DB_dbo |
| Fact_CustomerAction | DWH_dbo |
| Fact_History_Cost | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Function_Revenue_AdminFee | BI_DB_dbo |
| Function_Revenue_FullCommissions | BI_DB_dbo |
| Function_Revenue_RolloverFee | BI_DB_dbo |
| Function_Revenue_SpotAdjustFee | BI_DB_dbo |
| Function_Revenue_TicketFee | BI_DB_dbo |
| Function_Revenue_TicketFeeByPercent | BI_DB_dbo |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID, Fact_CustomerAction.RealCID | Direct via nested TVFs | T1 |
| 2 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID, Fact_CustomerAction.DateID, Fact_History_Cost.DateID | Direct via nested TVFs | T2 |
| 3 | Metric | — | Literal per UNION branch: TotalFullCommission, RolloverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee | T2 |
| 4 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID, Fact_CustomerAction (via snapshot join in FullCommissions) | Direct via nested TVFs | T2 |
| 5 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID, Fact_SnapshotCustomer.CountryID | Direct via nested TVFs | T2 |
| 6 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID, Fact_SnapshotCustomer.LabelID | Direct via nested TVFs | T1 |
| 7 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID, Fact_SnapshotCustomer.VerificationLevelID | Direct via nested TVFs | T1 |
| 8 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID, Fact_SnapshotCustomer.PlayerStatusID | Direct via nested TVFs | T1 |
| 9 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID, Fact_SnapshotCustomer.RiskStatusID | Direct via nested TVFs | T1 |
| 10 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID, Fact_SnapshotCustomer.RiskClassificationID | Direct via nested TVFs | T1 |
| 11 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID, Fact_SnapshotCustomer.GuruStatusID | Direct via nested TVFs | T1 |
| 12 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID, Fact_SnapshotCustomer.RegulationID | Direct via nested TVFs | T1 |
| 13 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID, Fact_SnapshotCustomer.AccountStatusID | Direct via nested TVFs | T1 |
| 14 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID, Fact_SnapshotCustomer.AccountManagerID | Direct via nested TVFs | T1 |
| 15 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID, Fact_SnapshotCustomer.PlayerLevelID | Direct via nested TVFs | T1 |
| 16 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID, Fact_SnapshotCustomer.AccountTypeID | Direct via nested TVFs | T1 |
| 17 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor, Fact_SnapshotCustomer.IsDepositor | Direct via nested TVFs | T1 |
| 18 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID, Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct via nested TVFs | T1 |
| 19 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID, Fact_SnapshotCustomer.MifidCategorizationID | Direct via nested TVFs | T1 |
| 20 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer, Fact_SnapshotCustomer.IsValidCustomer | Direct via nested TVFs | T1 |
| 21 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB, Fact_SnapshotCustomer.IsCreditReportValidCB | Direct via nested TVFs | T1 |
| 22 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID, Fact_SnapshotCustomer.AffiliateID | Direct via nested TVFs | T1 |
| 23 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct via nested TVFs | T1 |
| 24 | IsFuture | Dim_Instrument.IsFuture | Direct via nested TVFs | T2 |
| 25 | IsSQF | Function_Instrument_Snapshot_Enriched.InstrumentID | CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END (via nested TVFs) | T2 |
| 26 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID, Fact_CustomerAction.InstrumentID | Direct via nested TVFs | T1 |
| 27 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy, Fact_CustomerAction.IsBuy | Direct via nested TVFs | T1 |
| 28 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop, Fact_CustomerAction.IsAirDrop | Direct via nested TVFs | T2 |
| 29 | IsLeverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage, Fact_CustomerAction.Leverage | CASE WHEN Leverage > 1 THEN 1 ELSE 0 END | T2 |
| 30 | IsCopy | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID, Fact_CustomerAction.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END | T2 |
| 31 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled, Fact_CustomerAction.IsSettled | Direct | T5 |
| 32 | IsActiveTrade | Function_Revenue_FullCommissions (computed from MirrorID + IsAirDrop); literal in other UNION branches | TotalFullCommission branch: `CASE WHEN ISNULL(IsAirDrop,0)=0 AND MirrorID=0 THEN 1 ELSE 0 END`. RolloverFee/AdminFee/SpotAdjustFee: literal `0`. TicketFee/TicketFeeByPercent: literal `1` | T2 |
| 33 | IsCopyFund | BI_DB_CopyFund_Positions.PositionID | CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 34 | IsIBANTrade | BI_DB_Positions_Closed_To_IBAN.PositionID, BI_DB_Positions_Opened_From_IBAN.PositionID | CASE WHEN closed OR opened IBAN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 35 | IsRecurring | BI_DB_RecurringInvestment_Positions.PositionID | CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 36 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID, Fact_CustomerAction.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END (from nested TVFs) | T2 |
| 37 | Amount | Fee columns from nested TVFs (TotalFullCommission, RolloverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee) | `SUM(Amount)` after UNION ALL of nested TVFs — each source TVF applies its own predicates (e.g. commission `ActionTypeID` set; rollover `ActionTypeID = 35` / `IsFeeDividend`; ticket / percent-ticket / admin / spot-adjust rules as in those functions) | T2 |
| 38 | CountPositions | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID, Fact_CustomerAction.PositionID | COUNT(PositionID) | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
