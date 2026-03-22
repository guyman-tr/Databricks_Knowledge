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
| 2 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID, Fact_CustomerAction.DateID, Fact_History_Cost.DateID | Direct via nested TVFs | T1 |
| 3 | Metric | — | Literal per UNION branch: TotalFullCommission, RolloverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee | T2 |
| 4 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID, Fact_CustomerAction (via snapshot join in FullCommissions) | Direct via nested TVFs | T1 |
| 5 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID, Fact_SnapshotCustomer.CountryID | Direct via nested TVFs | T1 |
| 6 | LabelID | Same lineage as CountryID | Direct | T1 |
| 7 | VerificationLevelID | Same lineage as CountryID | Direct | T1 |
| 8 | PlayerStatusID | Same lineage as CountryID | Direct | T1 |
| 9 | RiskStatusID | Same lineage as CountryID | Direct | T1 |
| 10 | RiskClassificationID | Same lineage as CountryID | Direct | T1 |
| 11 | GuruStatusID | Same lineage as CountryID | Direct | T1 |
| 12 | RegulationID | Same lineage as CountryID | Direct | T1 |
| 13 | AccountStatusID | Same lineage as CountryID | Direct | T1 |
| 14 | AccountManagerID | Same lineage as CountryID | Direct | T1 |
| 15 | PlayerLevelID | Same lineage as CountryID | Direct | T1 |
| 16 | AccountTypeID | Same lineage as CountryID | Direct | T1 |
| 17 | IsDepositor | Same lineage as CountryID | Direct | T1 |
| 18 | SuitabilityTestStatusID | Same lineage as CountryID | Direct | T1 |
| 19 | MifidCategorizationID | Same lineage as CountryID | Direct | T1 |
| 20 | IsValidCustomer | Same lineage as CountryID | Direct | T1 |
| 21 | IsCreditReportValidCB | Same lineage as CountryID | Direct | T1 |
| 22 | AffiliateID | Same lineage as CountryID | Direct | T1 |
| 23 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct via nested TVFs | T1 |
| 24 | IsFuture | Dim_Instrument.IsFuture | Direct via nested TVFs | T1 |
| 25 | IsSQF | Function_Instrument_Snapshot_Enriched.InstrumentID | CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END (via nested TVFs) | T2 |
| 26 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID, Fact_CustomerAction.InstrumentID | Direct via nested TVFs | T1 |
| 27 | IsBuy | Distribution / Fact_CustomerAction | Direct | T1 |
| 28 | IsAirDrop | Distribution / Fact_CustomerAction | Direct | T1 |
| 29 | IsLeverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage, Fact_CustomerAction.Leverage | CASE WHEN Leverage > 1 THEN 1 ELSE 0 END | T2 |
| 30 | IsCopy | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID, Fact_CustomerAction.MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END | T2 |
| 31 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled, Fact_CustomerAction.IsSettled | Direct | T1 |
| 32 | IsActiveTrade | MirrorID, IsAirDrop | CASE WHEN ISNULL(IsAirDrop,0) = 0 AND MirrorID = 0 THEN 1 ELSE 0 END; overridden 0/1 per metric branch | T2 |
| 33 | IsCopyFund | BI_DB_CopyFund_Positions.PositionID | CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 34 | IsIBANTrade | BI_DB_Positions_Closed_To_IBAN.PositionID, BI_DB_Positions_Opened_From_IBAN.PositionID | CASE WHEN closed OR opened IBAN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 35 | IsRecurring | BI_DB_RecurringInvestment_Positions.PositionID | CASE WHEN PositionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 36 | IsMarginTrade | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID, Fact_CustomerAction.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END (from nested TVFs) | T2 |
| 37 | Amount | Fee columns from nested TVFs (TotalFullCommission, RolloverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee) | `SUM(Amount)` after UNION ALL of nested TVFs — each source TVF applies its own predicates (e.g. commission `ActionTypeID` set; rollover `ActionTypeID = 35` / `IsFeeDividend`; ticket / percent-ticket / admin / spot-adjust rules as in those functions) | T2 |
| 38 | CountPositions | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID, Fact_CustomerAction.PositionID | COUNT(PositionID) | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
