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
| 1 | DateID | BI_DB_Fact_Customer_Action_Position_Distribution.DateID | Integer date key in YYYYMMDD format. DELETE+INSERT keyed on this column. 6,356 distinct dates from April 2008 to present. Passthrough from Fact_CustomerAction.DateID. (Tier 2 — DWH_dbo.Fact_CustomerAction) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 2 | ActionTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.ActionTypeID | Event type classifier. Filtered to 4 values: 35 (ticket fees, ~97%), 36 (compensations with reason 56/117/118), 32 (edit stop-loss), 19 (detach from mirror). FK to Dim_ActionType. (Tier 1 — DWH_dbo.Fact_CustomerAction) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 3 | TradingFeeName | Dim_CompensationReason.Name; literal | `dcr.Name` WHERE `ActionTypeID = 36` AND `CompensationReasonID IN (117,118)`; literal `'TicketFee'` WHERE `ActionTypeID = 35` AND `IsFeeDividend = 4` | T2 |
| 4 | Amount | BI_DB_Fact_Customer_Action_Position_Distribution.Amount | `-1 * Amount` WHERE (`ActionTypeID = 36` AND `CompensationReasonID IN (117,118)`) OR (`ActionTypeID = 35` AND `IsFeeDividend = 4`) | T2 |
| 5 | RealCID | BI_DB_Fact_Customer_Action_Position_Distribution.RealCID | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 6 | PositionID | BI_DB_Fact_Customer_Action_Position_Distribution.PositionID, Description | **Compensation branch:** TRY_CAST of last token of `Description`; **TicketFee branch:** `PositionID` direct WHERE `ActionTypeID = 35` AND `IsFeeDividend = 4` | T2 |
| 7 | InstrumentID | BI_DB_Fact_Customer_Action_Position_Distribution.InstrumentID | Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.Instrument) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 8 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) (via Dim_Instrument) | T1 |
| 9 | IsSettled | BI_DB_Fact_Customer_Action_Position_Distribution.IsSettled | 1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 — Expert Review) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T5 |
| 10 | MirrorID | BI_DB_Fact_Customer_Action_Position_Distribution.MirrorID | FK to Trade.Mirror. 0/NULL = manual trade. Positive = copy-trade position. DWH note: set to 0 if action Occurred after a detach-from-mirror event (ActionTypeID=19) for the same PositionID. COALESCE from Dim_Position. (Tier 1 — Trade.PositionTbl) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 11 | Leverage | BI_DB_Fact_Customer_Action_Position_Distribution.Leverage | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.PositionTbl) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 12 | IsAirDrop | BI_DB_Fact_Customer_Action_Position_Distribution.IsAirDrop | 1 = position was created via an airdrop event (crypto). ISNULL(COALESCE(dp, fca), 0) — defaults to 0. (Tier 2 — SP_Dim_Position_DL_To_Synapse) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 13 | IsBuy | BI_DB_Fact_Customer_Action_Position_Distribution.IsBuy | 1 = Long/Buy, 0 = Short/Sell. Resolved via COALESCE(dp.IsBuy, fca.IsBuy): prefers Dim_Position value, falls back to Fact_CustomerAction. NULL if both sources are NULL. (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |
| 14 | GCID | BI_DB_Fact_Customer_Action_Position_Distribution.GCID | Global Customer ID — cross-platform identifier linking RealCID to demo and external systems. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 15 | CountryID | BI_DB_Fact_Customer_Action_Position_Distribution.CountryID | Customer's registered country. DEFAULT 0. FK to Dim_Country. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 16 | LabelID | BI_DB_Fact_Customer_Action_Position_Distribution.LabelID | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. FK to Dim_Label. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 17 | VerificationLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.VerificationLevelID | KYC verification level. DEFAULT -1. FK to Dim_VerificationLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 18 | PlayerStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 19 | RiskStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskStatusID | Customer risk assessment status. DEFAULT 0. FK to Dim_RiskStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 20 | RiskClassificationID | BI_DB_Fact_Customer_Action_Position_Distribution.RiskClassificationID | Risk classification tier for compliance. DEFAULT 0. FK to Dim_RiskClassification. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 21 | GuruStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID | Popular Investor (Guru) program status. DEFAULT 0. FK to Dim_GuruStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 22 | RegulationID | BI_DB_Fact_Customer_Action_Position_Distribution.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. FK to Dim_Regulation. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 23 | AccountStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountStatusID | Account enabled/suspended status. DEFAULT 0. FK to Dim_AccountStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 24 | AccountManagerID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. FK to Dim_Manager. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 25 | PlayerLevelID | BI_DB_Fact_Customer_Action_Position_Distribution.PlayerLevelID | Account tier: 4=demo, other values=real tiers. DEFAULT 0. FK to Dim_PlayerLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 26 | AccountTypeID | BI_DB_Fact_Customer_Action_Position_Distribution.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. FK to Dim_AccountType. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 27 | IsDepositor | BI_DB_Fact_Customer_Action_Position_Distribution.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Never reverted to 0 once set. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 28 | SuitabilityTestStatusID | BI_DB_Fact_Customer_Action_Position_Distribution.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 29 | MifidCategorizationID | BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. FK to Dim_MifidCategorization. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 30 | IsValidCustomer | BI_DB_Fact_Customer_Action_Position_Distribution.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 31 | IsCreditReportValidCB | BI_DB_Fact_Customer_Action_Position_Distribution.IsCreditReportValidCB | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 32 | AffiliateID | BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID | Affiliate/partner who referred this customer. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T2 |
| 33 | UpdateDate | BI_DB_Fact_Customer_Action_Position_Distribution.UpdateDate | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T5 |
| 34 | CompensationReasonID | BI_DB_Fact_Customer_Action_Position_Distribution.CompensationReasonID | Compensation reason for compensation events (ActionTypeID=36). References BackOffice.CompensationReason. 0 for non-compensation events. Filtered to IN (56, 117, 118) when ActionTypeID=36. (Tier 1 — History.Credit) (via BI_DB_Fact_Customer_Action_Position_Distribution) | T1 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
