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
| 1 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 2 | Occurred | Fact_History_Cost.Occurred | Timestamp when the cost event occurred. Business event time. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) (via Fact_History_Cost) | T2 |
| 3 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.Instrument) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 4 | PositionID | Fact_History_Cost.PositionID | Position that generated this cost. JOINs to Fact_Position. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) (via Fact_History_Cost) | T2 |
| 5 | DateID | Fact_History_Cost.DateID | Date of the cost event in YYYYMMDD integer format. Computed as CONVERT(INT, CONVERT(VARCHAR(10), Occurred, 112)). PK component. (Tier 2 — SP_Fact_History_Cost_DL_To_Synapse) (via Fact_History_Cost) | T2 |
| 6 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | 1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 — Expert Review) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T5 |
| 7 | MirrorID | Fact_History_Cost.MirrorID | Copy trading mirror relationship ID if cost is related to a copy trade. NULL if direct trade. (Tier 2 — DWH_staging.HistoryCosts_History_Costs) (via Fact_History_Cost) | T2 |
| 8 | Leverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.PositionTbl) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 9 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop | 1 = position was created via an airdrop event (crypto). ISNULL(COALESCE(dp, fca), 0) — defaults to 0. (Tier 2 — SP_Dim_Position_DL_To_Synapse) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 10 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID | Global Customer ID — cross-platform identifier linking RealCID to demo and external systems. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 11 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID | Customer's registered country. DEFAULT 0. FK to Dim_Country. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 12 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. FK to Dim_Label. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 13 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID | KYC verification level. DEFAULT -1. FK to Dim_VerificationLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 14 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 15 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID | Customer risk assessment status. DEFAULT 0. FK to Dim_RiskStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 16 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. FK to Dim_RiskClassification. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 17 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. FK to Dim_GuruStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 18 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. FK to Dim_Regulation. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 19 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID | Account enabled/suspended status. DEFAULT 0. FK to Dim_AccountStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 20 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. FK to Dim_Manager. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 21 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. FK to Dim_PlayerLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 22 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. FK to Dim_AccountType. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 23 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Never reverted to 0 once set. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 24 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 25 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. FK to Dim_MifidCategorization. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 26 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 27 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 28 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 29 | TicketFeeByPercent | Fact_History_Cost.ValueInAccountCurrency | `CASE WHEN DateID < 20250525 THEN 0 ELSE ValueInAccountCurrency END` AS TicketFeeByPercent WHERE `CostSubTypeID = 4`, `CalculationTypeID IN (4,7)`, `ISNULL(ValueInAccountCurrency,0) > 0`, `DateID BETWEEN @sdateInt AND @edateInt`; **Open branch:** `OperationTypeID IN (14,24)` and join `fcapd.TicketFeeAction = 'Open'`; **Close branch:** `OperationTypeID IN (12,13)` and `TicketFeeAction = 'Close'` | T2 |
| 30 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | 1 = Long/Buy, 0 = Short/Sell. Resolved via COALESCE(dp.IsBuy, fca.IsBuy): prefers Dim_Position value, falls back to Fact_CustomerAction. NULL if both sources are NULL. (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 31 | IsCopy | Fact_History_Cost.MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END | T2 |
| 32 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 33 | TicketFeeByPercentAction | — | Literal 'Open' or 'Close' by branch | T2 |
| 34 | IsFuture | Dim_Instrument.IsFuture | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument) | T2 |
| 35 | SettlementTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.SettlementTypeID | Modern settlement classification from Dim_Position. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. DWH note: switched from FCA to Dim_Position source (2025-10-15) because FCA shows NULL on overnights. (Tier 1 — Trade.PositionTbl) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
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
