# Function_Revenue_FullCommissions

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Revenue |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 62 (T1: 54, T2: 8) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns full trading commission components (open, close, and close adjustment) per customer action and position, enriched with snapshot customer attributes and instrument type. Used to analyze commission revenue by action type, copy trading, margin settlement, and single-quote futures (SQF) instruments.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Range | DWH_dbo |
| Fact_CustomerAction | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID | Direct | T1 |
| 2 | Occurred | Fact_CustomerAction.Occurred | Direct | T1 |
| 3 | ActionTypeID | Fact_CustomerAction.ActionTypeID | Direct | T1 |
| 4 | InstrumentID | Fact_CustomerAction.InstrumentID | Direct | T1 |
| 5 | Leverage | Fact_CustomerAction.Leverage | Direct | T1 |
| 6 | PositionID | Fact_CustomerAction.PositionID | Direct | T1 |
| 7 | DateID | Fact_CustomerAction.DateID | Direct | T1 |
| 8 | IsSettled | Fact_CustomerAction.IsSettled | Direct | T1 |
| 9 | MirrorID | Fact_CustomerAction.MirrorID | Direct | T1 |
| 10 | IsAirDrop | Fact_CustomerAction | ISNULL(IsAirDrop,0) | T2 |
| 11 | SettlementTypeID | Fact_CustomerAction.SettlementTypeID | Direct | T1 |
| 12 | IsMarginTrade | Fact_CustomerAction.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 13 | GCID | Fact_SnapshotCustomer.GCID | Direct | T1 |
| 14 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T1 |
| 15 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T1 |
| 16 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T1 |
| 17 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T1 |
| 18 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T1 |
| 19 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T1 |
| 20 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T1 |
| 21 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T1 |
| 22 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T1 |
| 23 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T1 |
| 24 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T1 |
| 25 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T1 |
| 26 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T1 |
| 27 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T1 |
| 28 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T1 |
| 29 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T1 |
| 30 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T1 |
| 31 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T1 |
| 32 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T1 |
| 33 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T1 |
| 34 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T1 |
| 35 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T1 |
| 36 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T1 |
| 37 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T1 |
| 38 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T1 |
| 39 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T1 |
| 40 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T1 |
| 41 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T1 |
| 42 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T1 |
| 43 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T1 |
| 44 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T1 |
| 45 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T1 |
| 46 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 47 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 48 | Address | Fact_SnapshotCustomer.Address | Direct | T1 |
| 49 | Zip | Fact_SnapshotCustomer.Zip | Direct | T1 |
| 50 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T1 |
| 51 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T1 |
| 52 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T1 |
| 53 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T1 |
| 54 | FullCommissionOnOpen | Fact_CustomerAction | CASE WHEN ActionTypeID IN (1,2,3,39) THEN FullCommission ELSE 0 END | T2 |
| 55 | FullCommissionCloseAdjustment | Fact_CustomerAction | CASE WHEN ActionTypeID IN (1,2,3,39) THEN 0 WHEN ActionTypeID IN (4,5,6,28,40) THEN FullCommissionOnClose - FullCommissionByUnits ELSE 0 END | T2 |
| 56 | FullCommissionOnClose | Fact_CustomerAction | CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN FullCommissionOnClose ELSE 0 END | T2 |
| 57 | IsBuy | Fact_CustomerAction.IsBuy | Direct | T1 |
| 58 | IsCopy | Fact_CustomerAction | CASE WHEN ActionTypeID IN (2,3,5,6) THEN 1 ELSE 0 END | T2 |
| 59 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 60 | IsFuture | Dim_Instrument.IsFuture | Direct | T1 |
| 61 | TotalFullCommission | Fact_CustomerAction | CASE WHEN ActionTypeID IN (1,2,3,39) THEN FullCommissionOnOpen WHEN ActionTypeID IN (4,5,6,28,40) THEN FullCommissionCloseAdjustment END | T2 |
| 62 | IsSQF | Function_Instrument_Snapshot_Enriched.InstrumentID | CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2024-09-25 | Guy M | With the addition of IsBuy to FactCustomerAction, removed the inefficient join to Dim_Position |
| 2024-11-07 | Guy M | Add commission on close |
| 2025-03-09 | Guy M | Add IsFuture |
| 2025-06-23 | Guy M | Add IsSQF |
| 2025-09-11 | Guy M | Add SettlementTypeID |
| 2025-10-15 | Guy M | Add margin trades |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
