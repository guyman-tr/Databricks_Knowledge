# Semantic Index - Synapse DWH

*Generated: 2026-03-15 | Objects: 4*

## Business Concepts

| Concept | Primary Object(s) | Related Objects | Description |
|---------|-------------------|-----------------|-------------|
| Position Lifecycle | `DWH_dbo.Dim_Position` | `Fact_CustomerAction` (ActionTypeID 1-6, 28, 39-40), `Dim_ClosePositionReason`, `Dim_Regulation` | Every open and historically-closed trading position as an end-of-day snapshot |
| Customer Activity | `DWH_dbo.Fact_CustomerAction` | `Dim_Position` (33 shared columns), `Dim_ActionType`, `Dim_Customer`, `Dim_Instrument` | Unified customer event log — position opens/closes, deposits, cashouts, logins, fees, social, copy-trade |
| Copy Trading | `DWH_dbo.Dim_Position` (MirrorID, ParentPositionID, OrigParentPositionID, TreeID) | `Fact_CustomerAction` (MirrorID), upstream `Trade.Mirror` | Position hierarchy and copy-trade linkage via mirror relationships |
| Settlement Types | `DWH_dbo.Dim_Position` (SettlementTypeID, IsSettled, IsSettledOnOpen) | `Fact_CustomerAction` (SettlementTypeID), upstream `Dictionary.SettlementTypes` | CFD (0), Real Stock (1), TRS (2), Commitment (3), Real Futures (4), Margin Trade (5) |
| Partial Close | `DWH_dbo.Dim_Position` (IsPartialCloseParent, IsPartialCloseChild, OriginalPositionID) | `Fact_CustomerAction` (IsPartialCloseParent, IsPartialCloseChild) | Position splitting — parent retains original ID, child is the closed portion |
| Reopen Positions | `DWH_dbo.Dim_Position` (IsReOpen, ReopenForPositionID) | `Fact_CustomerAction` (IsReOpen, ReopenForPositionID) | Positions reopened after close — commission adjustments via Orig columns |
| Regulation | `DWH_dbo.Dim_Regulation` | `Dim_Position` (RegulationIDOnOpen), `Fact_CustomerAction` (RegulationIDOnOpen), `Fact_BillingDeposit` (ProcessRegulationID) | Regulatory jurisdiction at position open or deposit processing (CySEC, FCA, ASIC, etc.) |
| Hedge Types | `DWH_dbo.Dim_Position` (InitHedgeType, EndHedgeType, HedgeServerID) | upstream `Trade.HBCExecutionLog` | CBH vs HBC hedge routing for position execution |
| Deposit Transactions | `DWH_dbo.Fact_BillingDeposit` | `Dim_Currency`, `Dim_PaymentStatus`, `Dim_FundingType`, `Dim_BillingDepot`, `Dim_Country`, `Dim_CountryBin`, `Fact_CustomerAction` | Central deposit fact table recording every monetary deposit attempt. Key filter: PaymentStatusID=2 for approved |
| Payment Methods | `DWH_dbo.Fact_BillingDeposit` (FundingTypeID, DepotID, CardTypeIDAsInteger) | `Dim_FundingType`, `Dim_BillingDepot`, `Dim_CardType` | Payment instruments used for deposits: CreditCard, WireTransfer, PayPal, Skrill, ACH, eToroMoney, etc. |
| First Time Deposits (FTD) | `DWH_dbo.Fact_BillingDeposit` (IsFTD) | `Fact_CustomerAction` (ActionTypeID=14 for deposit) | Binary flag indicating customer's first-ever deposit. Critical KPI for acquisition funnels |
| XML Payment Provider Data | `DWH_dbo.Fact_BillingDeposit` (~70 AsString columns) | upstream `Billing.Deposit.PaymentData`, `Billing.Funding.FundingData` | Payment provider response fields extracted from XML blobs via ExtractXMLValue during ETL |

|| Customer Lifecycle Milestones | `BI_DB_dbo.BI_DB_CIDFirstDates` | `Dim_Customer`, `Fact_CustomerAction`, `Fact_BillingDeposit`, `Dim_Mirror`, `Fact_SnapshotCustomer` | One row per CID tracking registration, first/last dates for deposit, login, position, copy-trade, cashout, verification status |
|| FTD Fast-Track | `BI_DB_dbo.BI_DB_CIDFirstDates` (FTDIsLessThanAWeek) | `Dim_Customer`, `Fact_BillingDeposit` | Whether first deposit occurred within 7 days of registration — key acquisition metric |
|| Funded Status | `BI_DB_dbo.BI_DB_CIDFirstDates` (IsFundedNew, FirstNewFundedDate, LastNewFundedDate) | `Function_Population_Funded`, `Function_Population_First_Time_Funded` | Complex UDF-determined funded status — meeting active depositor criteria |
|| Verification Cascade | `BI_DB_dbo.BI_DB_CIDFirstDates` (VerificationLevel1-3Date) | `Fact_SnapshotCustomer`, `Dim_VerificationLevel` | Backfilling lower verification levels when higher levels are achieved |
|| Sentinel Date Convention | `BI_DB_dbo.BI_DB_CIDFirstDates` (FirstDepositDate, BirthDate, etc.) | — | 1900-01-01 means "no event" / "not applicable" — must filter with YEAR(col) != 1900 |
|| Acquisition Attribution | `BI_DB_dbo.BI_DB_CIDFirstDates` (Channel, SubChannel, SerialID, BannerID, FunnelName) | `Dim_Channel`, `Dim_Affiliate`, `Dim_Funnel`, `Dim_Label` | Multi-level acquisition channel attribution: Channel → SubChannel → Affiliate → Banner → Funnel |

## Shared Elements

| Element Name | Appears In | Description |
|-------------|-----------|-------------|
| PositionID | `Dim_Position` (PK), `Fact_CustomerAction`, `BI_DB_PositionPnL`, `Dim_PositionChangeLog`, `BI_DB_V_StockMargin_*` views | Globally unique position identifier |
| CID | `Dim_Position`, `Fact_CustomerAction` (as RealCID/CID), `Fact_BillingDeposit` | Customer account ID |
| InstrumentID | `Dim_Position`, `Fact_CustomerAction`, `Dim_Instrument` (PK) | Financial instrument reference |
| MirrorID | `Dim_Position`, `Fact_CustomerAction` | Copy-trade relationship identifier (0=manual) |
| RegulationIDOnOpen | `Dim_Position`, `Fact_CustomerAction` | Regulation at open (joined from BackOffice.Customer) |
| ClosePositionReasonID | `Dim_Position`, `Dim_ClosePositionReason` (PK) | Close reason enum (0-29) |
| SettlementTypeID | `Dim_Position`, `Fact_CustomerAction` | Position settlement type (CFD/Real/TRS/etc.) |
| Commission / CommissionOnClose | `Dim_Position`, `Fact_CustomerAction` | eToro spread markup at open/close |
| IsPartialCloseChild / IsPartialCloseParent | `Dim_Position`, `Fact_CustomerAction` | Partial close flags (ETL-computed) |
| IsReOpen / ReopenForPositionID | `Dim_Position`, `Fact_CustomerAction` | Reopen flags (ETL-computed) |
| DepositID | `Fact_BillingDeposit` (PK) | Globally unique deposit transaction identifier |
| PaymentStatusID | `Fact_BillingDeposit`, `Dim_PaymentStatus` | Payment lifecycle status. Key filter: =2 for approved |
| FundingTypeID | `Fact_BillingDeposit`, `Dim_FundingType` | Payment method type (1=CreditCard, 2=Wire, 3=PayPal, etc.) |
| DepotID | `Fact_BillingDeposit`, `Dim_BillingDepot` | Payment processor/depot identifier |
| CurrencyID | `Dim_Position`, `Fact_BillingDeposit`, `Dim_Currency` | Currency identifier (1=USD, 2=EUR, etc.) |
| SessionID | `Fact_BillingDeposit`, `Fact_CustomerAction` | Session identifier linking deposit to customer activity |
| PlatformID | `Fact_BillingDeposit` (from Fact_CustomerAction), `Fact_CustomerAction` | Platform identifier. Note: Fact_BillingDeposit values don't match Dim_Platform |
| IsFTD | `Fact_BillingDeposit` | First Time Deposit flag (1=first, 0=subsequent) |

## Production Lineage Map

| DWH Object | Production Source | Upstream Wiki Link |
|-----------|-------------------|-------------------|
| `DWH_dbo.Dim_Position` | `Trade.PositionTbl`, `Trade.PositionTreeInfo`, `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `BackOffice.Customer`, `PriceLog`, `Trade.HBCExecutionLog`, `Trade.PositionAirdropLog`, `History.Cost` | [Trade.PositionTbl](../../DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md) |
| `DWH_dbo.Fact_CustomerAction` | `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `History.Credit` (`History.ActiveCredit`), `STS_Audit_UserOperationsData`, `Billing.Login`, `Customer.CustomerStatic` | — |
| `DWH_dbo.Fact_BillingDeposit` | `Billing.Deposit`, `Billing.Funding` (XML extraction), `Billing.RecurringDeposit`, `Dim_Country`, `Dim_CountryBin`, `Fact_CustomerAction` (PlatformID) | — |
|| `BI_DB_dbo.BI_DB_CIDFirstDates` | `Dim_Customer`, `Fact_CustomerAction`, `Fact_BillingDeposit`, `V_Liabilities`, `Dim_Mirror`, `Fact_SnapshotCustomer`, `ComplianceStateDB`, `BI_DB_UsageTracking_SF`, `BI_DB_AppFlyer_Reports` | — |
