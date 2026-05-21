# Function_Revenue_Commissions

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

Returns **trading commission** components by customer action from `Fact_CustomerAction` where the first CTE restricts rows to **ActionTypeID IN (1,2,3,39,4,5,6,28,40)** (open-style vs close-style families). It joins snapshot context and `Dim_Instrument`. **CommissionOnOpen** applies when **ActionTypeID IN (1,2,3,39)**; **CommissionOnClose** / **CommissionCloseAdjustment** apply when **ActionTypeID IN (4,5,6,28,40)** (close adjustment uses `CommissionOnClose - CommissionByUnits`). **TotalCommission** selects open vs close branch by the same groupings. Adds copy and margin flags and **IsSQF** via `Function_Instrument_Snapshot_Enriched(@edateInt)`.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID | Direct | T1 |
| 2 | Occurred | Fact_CustomerAction.Occurred | Direct | T1 |
| 3 | ActionTypeID | Fact_CustomerAction.ActionTypeID | Direct | T1 |
| 4 | InstrumentID | Fact_CustomerAction.InstrumentID | Direct | T1 |
| 5 | Leverage | Fact_CustomerAction.Leverage | Direct | T1 |
| 6 | PositionID | Fact_CustomerAction.PositionID | Direct | T1 |
| 7 | DateID | Fact_CustomerAction.DateID | Direct | T2 |
| 8 | IsSettled | Fact_CustomerAction.IsSettled | Direct | T5 |
| 9 | MirrorID | Fact_CustomerAction.MirrorID | Direct | T1 |
| 10 | IsAirDrop | Fact_CustomerAction.IsAirDrop | ISNULL(IsAirDrop, 0) | T2 |
| 11 | SettlementTypeID | Fact_CustomerAction.SettlementTypeID | Direct | T1 |
| 12 | IsMarginTrade | Fact_CustomerAction.SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | T2 |
| 13 | GCID | Fact_SnapshotCustomer.GCID | Direct | T2 |
| 14 | CountryID | Fact_SnapshotCustomer.CountryID | Direct | T2 |
| 15 | LabelID | Fact_SnapshotCustomer.LabelID | Direct | T2 |
| 16 | LanguageID | Fact_SnapshotCustomer.LanguageID | Direct | T2 |
| 17 | VerificationLevelID | Fact_SnapshotCustomer.VerificationLevelID | Direct | T2 |
| 18 | DocsOK | Fact_SnapshotCustomer.DocsOK | Direct | T4 |
| 19 | PlayerStatusID | Fact_SnapshotCustomer.PlayerStatusID | Direct | T2 |
| 20 | Bankruptcy | Fact_SnapshotCustomer.Bankruptcy | Direct | T4 |
| 21 | RiskStatusID | Fact_SnapshotCustomer.RiskStatusID | Direct | T2 |
| 22 | RiskClassificationID | Fact_SnapshotCustomer.RiskClassificationID | Direct | T2 |
| 23 | CommunicationLanguageID | Fact_SnapshotCustomer.CommunicationLanguageID | Direct | T2 |
| 24 | PremiumAccount | Fact_SnapshotCustomer.PremiumAccount | Direct | T4 |
| 25 | Evangelist | Fact_SnapshotCustomer.Evangelist | Direct | T4 |
| 26 | GuruStatusID | Fact_SnapshotCustomer.GuruStatusID | Direct | T2 |
| 27 | RegulationID | Fact_SnapshotCustomer.RegulationID | Direct | T2 |
| 28 | AccountStatusID | Fact_SnapshotCustomer.AccountStatusID | Direct | T2 |
| 29 | AccountManagerID | Fact_SnapshotCustomer.AccountManagerID | Direct | T2 |
| 30 | PlayerLevelID | Fact_SnapshotCustomer.PlayerLevelID | Direct | T2 |
| 31 | AccountTypeID | Fact_SnapshotCustomer.AccountTypeID | Direct | T2 |
| 32 | DateRangeID | Fact_SnapshotCustomer.DateRangeID | Direct | T2 |
| 33 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Direct | T2 |
| 34 | PendingClosureStatusID | Fact_SnapshotCustomer.PendingClosureStatusID | Direct | T2 |
| 35 | DocumentStatusID | Fact_SnapshotCustomer.DocumentStatusID | Direct | T2 |
| 36 | SuitabilityTestStatusID | Fact_SnapshotCustomer.SuitabilityTestStatusID | Direct | T2 |
| 37 | MifidCategorizationID | Fact_SnapshotCustomer.MifidCategorizationID | Direct | T2 |
| 38 | IsEmailVerified | Fact_SnapshotCustomer.IsEmailVerified | Direct | T2 |
| 39 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | Direct | T2 |
| 40 | DesignatedRegulationID | Fact_SnapshotCustomer.DesignatedRegulationID | Direct | T2 |
| 41 | EvMatchStatus | Fact_SnapshotCustomer.EvMatchStatus | Direct | T2 |
| 42 | RegionID | Fact_SnapshotCustomer.RegionID | Direct | T2 |
| 43 | PlayerStatusReasonID | Fact_SnapshotCustomer.PlayerStatusReasonID | Direct | T2 |
| 44 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct | T2 |
| 45 | AffiliateID | Fact_SnapshotCustomer.AffiliateID | Direct | T2 |
| 46 | Email | Fact_SnapshotCustomer.Email | Direct | T1 |
| 47 | City | Fact_SnapshotCustomer.City | Direct | T1 |
| 48 | Address | Fact_SnapshotCustomer.Address | Direct | T2 |
| 49 | Zip | Fact_SnapshotCustomer.Zip | Direct | T2 |
| 50 | PhoneNumber | Fact_SnapshotCustomer.PhoneNumber | Direct | T2 |
| 51 | IsPhoneVerified | Fact_SnapshotCustomer.IsPhoneVerified | Direct | T2 |
| 52 | PhoneVerificationDateID | Fact_SnapshotCustomer.PhoneVerificationDateID | Direct | T2 |
| 53 | PlayerStatusSubReasonID | Fact_SnapshotCustomer.PlayerStatusSubReasonID | Direct | T2 |
| 54 | CommissionOnOpen | Fact_CustomerAction.Commission | CASE WHEN ActionTypeID IN (1,2,3,39) THEN Commission ELSE 0 END (prep rows already WHERE ActionTypeID IN (1,2,3,39,4,5,6,28,40)) | T2 |
| 55 | CommissionCloseAdjustment | Fact_CustomerAction.CommissionOnClose, CommissionByUnits | CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionOnClose - CommissionByUnits ELSE 0 END (same prep filter) | T2 |
| 56 | CommissionOnClose | Fact_CustomerAction.CommissionOnClose | CASE WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionOnClose ELSE 0 END (same prep filter) | T2 |
| 57 | IsBuy | Fact_CustomerAction.IsBuy | Direct | T1 |
| 58 | IsCopy | Fact_CustomerAction.ActionTypeID | CASE WHEN ActionTypeID IN (2,3,5,6) THEN 1 ELSE 0 END | T2 |
| 59 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 60 | IsFuture | Dim_Instrument.IsFuture | Direct | T2 |
| 61 | TotalCommission | Fact_CustomerAction.Commission, CommissionOnClose, CommissionByUnits | CASE WHEN ActionTypeID IN (1,2,3,39) THEN CommissionOnOpen WHEN ActionTypeID IN (4,5,6,28,40) THEN CommissionCloseAdjustment END (same prep filter) | T2 |
| 62 | IsSQF | Function_Instrument_Snapshot_Enriched | CASE WHEN InstrumentID IN (enriched WHERE IsSQF = 1) THEN 1 ELSE 0 END | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2024-09-25 | Guy M | IsBuy on Fact_CustomerAction; removed Dim_Position join |
| 2024-11-07 | Guy M | Commission on close |
| 2025-03-09 | Guy M | IsFuture |
| 2025-06-23 | Guy M | IsSQF |
| 2025-09-11 | Guy M | SettlementTypeID |
| 2025-10-15 | Guy M | Margin trades |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
