# Lineage: BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

**Writer SP:** `BI_DB_dbo.SP_Client_Balance_Breakdown` (Author: Guy Manova, 2023-04-20)
**Grain:** One row per {DateID × InstrumentID × Regulation × RegTransferDirection × all dimension flag combination}. Dimension columns are GROUP BY keys; metric columns are SUM aggregates over all matching CID-position-level records. ROUND_ROBIN distributed, CCI.

---

## Upstream Sources

| Source | Role |
|--------|------|
| `DWH_dbo.Fact_CustomerAction` | PnL events (ActionTypeID 1–6, 28, 39, 40): NetProfit, Commission, FullCommission, CommissionOnClose, FullCommissionOnClose, CommissionByUnits, IsSettled, MirrorID |
| `DWH_dbo.Dim_Position` | Position attributes: CID, IsBuy, IsAirDrop, IsSettled, IsPartialCloseChild, Commission, FullCommission, CommissionOnClose, FullCommissionOnClose, CommissionByUnits, CommissionVersion, OpenDateID, CloseDateID |
| `DWH_dbo.Dim_Instrument` | InstrumentID, InstrumentTypeID, InstrumentType (joined via Dim_Position.InstrumentID) |
| `BI_DB_dbo.BI_DB_PositionPnL` | DailyPnL, PositionPnL for HODL positions (OpenBeforeNotClosed, OpenDuringNotClosed branches) |
| `DWH_dbo.Dim_Regulation` | Regulation.Name via DWHRegulationID (non-transfer CIDs path) |
| `DWH_dbo.Dim_Customer` (via `#fsc2days` FactSalesCustomer) | AccountStatusID, AccountTypeID, CountryID, RegionID, MifidCategorizationID, PlayerLevelID, PlayerStatusID, LabelID, IsCreditReportValidCB, IsValidCustomer, IsOutlier, Transition, IsGermanBaFIN, IsEtoroTradingCID, IsGlenEagleAccount |
| `DWH_dbo.Dim_AccountStatus` | AccountStatusName |
| `DWH_dbo.Dim_AccountType` | AccountType.Name |
| `DWH_dbo.Dim_Country` | Country.Name, MarketingRegionManualName (Region) |
| `DWH_dbo.Dim_State_and_Province` | US_State.ShortName (US clients only, CountryID=219) |
| `DWH_dbo.Dim_MifidCategorization` | MiFiDCategorization.Name |
| `DWH_dbo.Dim_PlayerLevel` | Club.Name (player level / CopyTrader tier) |
| `DWH_dbo.Dim_PlayerStatus` | PlayerStatus.Name |
| `DWH_dbo.Dim_Label` | Label.Name |
| `DWH_dbo.Dim_PositionChangeLog` | AmountInUnits for same-day partial-close commission recalculation (#sameDayChgLog) |
| `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | TanganyStatus, IsDLTUser (current-day Tangany crypto custody status snapshot) |
| `BI_DB_dbo.Function_Revenue_TicketFeeByPercent` | TicketFeeByPercentOnClose, TicketFeeByPercentOnOpen, IsTicketFeeByPercentPosition |
| `BI_DB_dbo.Function_Instrument_Snapshot_Enriched` | IsSQF, IsTicketFeePercentInstrument |
| `BI_DB_dbo.External_Bronze_etoro_Trade_AdminPositionLog` | IsC2P (CompensationReasonID=134) |
| `#regChangesFinal` (derived from FactSalesCustomer 2-day window) | Regulation, RegTransferDirection for CIDs that changed regulation on this date |

---

## Column Lineage

### Date Dimensions

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `DateID` | `@DateID` (SP parameter) | YYYYMMDD integer date key |
| `Date` | `@Date` (SP parameter) | Full DATE value |
| `UpdateDate` | `GETDATE()` at insert time | ETL run timestamp |

### Position Type Flags (GROUP BY keys from Dim_Position / Fact_CustomerAction)

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `IsSettled` | `#IsSettledIsMirror.IsSettled` | Priority: close action > open action > HODL. IsSettled=1 means settled (crypto/stock), 0=CFD |
| `IsMirror` | `#IsSettledIsMirror.IsMirror` | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`. Same priority logic as IsSettled |
| `IsLeverage` | `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END` | From Fact_CustomerAction.Leverage / Dim_Position.Leverage |
| `IsLeverageMoreThen20` | `CASE WHEN Leverage > 20 THEN 1 ELSE 0 END` | High-leverage position flag |
| `IsAirDrop` | `ISNULL(Dim_Position.IsAirDrop, 0)` | Crypto airdrop positions |
| `IsBuy` | `Dim_Position.IsBuy` | 1=long, 0=short |
| `SettlementTypeID` | `Fact_CustomerAction.SettlementTypeID` / `Dim_Position.SettlementTypeID` | References Dim_SettlementType |

### Instrument Dimensions

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `InstrumentID` | `DWH_dbo.Dim_Instrument.InstrumentID` | FK to Dim_Instrument, joined via Dim_Position.InstrumentID |
| `InstrumentTypeID` | `DWH_dbo.Dim_Instrument.InstrumentTypeID` | FK to Dim_InstrumentType |
| `InstrumentType` | `DWH_dbo.Dim_Instrument.InstrumentType` | Denormalized string: Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies |

### Regulation Assignment (complex dual-row logic)

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `Regulation` | `DWH_dbo.Dim_Regulation.Name` (non-transfer path) OR `#regChangesFinal.Regulation` (transfer path) | Derived from FactSalesCustomer → DWHRegulationID |
| `RegTransferDirection` | `1` (normal, 99.997% of rows) or `-1` (sending-regulation on transfer day) | CRITICAL: TWO rows per CID on regulation-transfer days — direction=1 receives PnL/commission, direction=-1 carries reversal. NEVER GROUP BY CID AND Regulation simultaneously |

### Customer Classification Flags (all from FactSalesCustomer + dimension joins)

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `IsCreditReportValidCB` | `FactSalesCustomer.IsCreditReportValidCB` | Customer balance validity flag |
| `IsValidCustomer` | `FactSalesCustomer.IsValidCustomer` | Trading activity validity flag |
| `AccountStatusName` | `DWH_dbo.Dim_AccountStatus.AccountStatusName` via FSC.AccountStatusID | E.g., 'Open', 'Suspended', 'Closed' |
| `AccountType` | `DWH_dbo.Dim_AccountType.Name` via FSC.AccountTypeID | E.g., 'Private', 'Corporate' |
| `Country` | `DWH_dbo.Dim_Country.Name` via FSC.CountryID | Client's registered country |
| `US_State` | `DWH_dbo.Dim_State_and_Province.ShortName` via FSC.RegionID (WHERE CountryID=219) | US state abbreviation; NULL for non-US clients |
| `Region` | `DWH_dbo.Dim_Country.MarketingRegionManualName` via FSC.CountryID | Marketing region (same Country record) |
| `MiFiDCategorization` | `DWH_dbo.Dim_MifidCategorization.Name` via FSC.MifidCategorizationID | E.g., 'Retail', 'Retail Pending', 'Professional' |
| `Club` | `DWH_dbo.Dim_PlayerLevel.Name` via FSC.PlayerLevelID | CopyTrader tier: Bronze, Silver, Gold, Platinum, Diamond, Titanium |
| `PlayerStatus` | `DWH_dbo.Dim_PlayerStatus.Name` via FSC.PlayerStatusID | E.g., 'Normal', 'Popular Investor' |
| `Label` | `DWH_dbo.Dim_Label.Name` via FSC.LabelID | Client brand label (e.g., 'eToro') |
| `IsOutlier` | `FactSalesCustomer.IsOutlier` | Outlier CID flag (excludes from standard cohort analytics) |
| `Transition` | `FactSalesCustomer.Transition` | Regulation migration status — always 'NoTransition' in current data (legacy field) |
| `IsGermanBaFIN` | `FactSalesCustomer.IsGermanBaFIN` | German regulatory client flag |
| `IsEtoroTradingCID` | `FactSalesCustomer.IsEtoroTradingCID` | eToro proprietary trading account flag |
| `IsGlenEagleAccount` | `FactSalesCustomer.IsGlenEagleAccount` | Glen Eagle (acquired entity) account flag |

### Tangany / DLT / Commission Version Flags

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `TanganyStatus` | `MAX(BI_DB_Client_Balance_CID_Level_New.TanganyStatus)` for DateID | Tangany crypto custody status (MiCA). NULL for ~89% of clients (pre-MiCA / non-crypto-custody). Values: Customer, ConsentCustomer, MicaCustomer, Inactive, Internal, Pending |
| `IsDLTUser` | `MAX(BI_DB_Client_Balance_CID_Level_New.IsDLTUser)` for DateID | 1=client uses DLT (blockchain) settlement |
| `CommissionVersion` | `DWH_dbo.Dim_Position.CommissionVersion` | Commission model version (1=legacy, 2=new half/half model for subsidiaries) |

### Ticket Fee by Percent Columns

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `TicketFeeByPercentPositionType` | `CASE WHEN IsTicketFeeByPercentInstrument=1 AND IsTicketFeeByPercentPosition=1 THEN 'New' WHEN IsTicketFeeByPercentInstrument=1 AND IsTicketFeeByPercentPosition=0 THEN 'Legacy' ELSE 'NotRelevantToTicketFeeByPercent' END` | Instrument eligible (Function_Instrument_Snapshot_Enriched) AND position opened after TicketFeeByPercent launch (Function_Revenue_TicketFeeByPercent) |
| `TicketFeeByPercentOnClose` | `SUM(Function_Revenue_TicketFeeByPercent(@DateID, @DateID, 0) WHERE Action='Close')` | Zero for RegTransferDirection=-1 rows |
| `TicketFeeByPercentOnOpen` | `SUM(Function_Revenue_TicketFeeByPercent(@DateID, @DateID, 0) WHERE Action='Open')` | Ticket fee accrual for positions opened on this date |
| `IsSQF` | `ISNULL(CASE WHEN sqfPositions.PositionID IS NOT NULL THEN 1 ELSE 0 END, 0)` | SQF (Sponsored/Qualified Flow) instrument flag via Function_Instrument_Snapshot_Enriched |
| `IsC2P` | `CASE WHEN AdminPositionLog.PositionID IS NOT NULL THEN 1 ELSE 0 END` | Copy-to-Portfolio position (CompensationReasonID=134 in External_Bronze_etoro_Trade_AdminPositionLog) |

### PnL Metrics (all SUM aggregations)

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `UnrealizedPnLChange` | `SUM(TotalUnrealizedPnLChangeFinal)` | Position-type–aware unrealized PnL delta: OpenBeforeNotClosed=DailyPnL; OpenDuringNotClosed=NewUnrealizedPnL; OpenBeforeClosedDuring=-Prev_EOD_OpenPnl; OpenDuringClosedDuring=0. RegTransferDirection=-1 rows: `-1 * Prev_EOD_OpenPnl` |
| `RealizedPnL` | `SUM(TotalRealizedPnLFinal)` | From Fact_CustomerAction.NetProfit for close actions (4,5,6,28,40). Zero for RegTransferDirection=-1 rows |
| `TotalPnL` | `UnrealizedPnLChange + RealizedPnL` | Total PnL: realized + unrealized change |

### Commission Metrics (all SUM aggregations)

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `UnrealizedCommissionChange` | `SUM(UnrealizedCommissionChange)` | Open-position commission delta: for new opens = CommissionOnOpen; for HODL=CommissionTransfer; for closed=−CommissionOnClose+CloseAdjustment. RegTransferDirection=-1: −CommissionTransfer |
| `RealizedCommission` | `SUM(RealizedCommission)` | From Fact_CustomerAction.CommissionOnClose for close events. Zero for RegTransferDirection=-1 |
| `UnrealizedFullCommissionChange` | `SUM(UnrealizedFullCommissionChange)` | Same logic as UnrealizedCommissionChange using FullCommission (includes spread component) |
| `RealizedFullCommission` | `SUM(RealizedFullCommission)` | Same as RealizedCommission using FullCommissionOnClose |
| `CommissionOnOpen` | `SUM(CommissionOnOpenFinal)` | From Fact_CustomerAction.Commission for open actions (1,2,3,39). Zero for pre-existing positions and RegTransferDirection=-1 |
| `FullCommissionOnOpen` | `SUM(FullCommissionOnOpenFinal)` | Same as CommissionOnOpen using FullCommission |
| `CommissionCloseAdjustment` | `SUM(CommissionCloseAdjustmentFinal)` | Partial-close adjustment: CommissionOnClose − CommissionByUnits (unit-proportional commission). Only for closed positions |
| `FullCommissionCloseAdjustment` | `SUM(FullCommissionCloseAdjustmentFinal)` | Same as CommissionCloseAdjustment using FullCommission |
| `TotalCommission` | `RealizedCommission + UnrealizedCommissionChange` | Total commission exposure (realized + unrealized) |
| `TotalFullCommission` | `RealizedFullCommission + UnrealizedFullCommissionChange` | Full commission total |
| `TotalZero` | `UnrealizedFullCommissionChange + UnrealizedPnLChange + RealizedFullCommission + RealizedPnL` | Balance reconciliation metric — should net ~zero when PnL and commission are correctly attributed. Used by CMR automation zero-check |

---

## Downstream Consumers

| Consumer | Type | Purpose |
|----------|------|---------|
| `BI_DB_dbo.SP_IFRS_15_Balance` | SP (reader) | IFRS 15 revenue recognition balance |
| `BI_DB_dbo.SP_M_Finance_Audit_Auxillary_Datapoints` | SP (reader) | Finance audit auxiliary datapoints |
| `BI_DB_dbo.SP_CMR_Automation_Zero_By_Instrument` | SP (reader) | CMR automation zero-reconciliation by instrument |
| `BI_DB_dbo.SP_CMR_Automation_Zero_By_Instrument_New` | SP (reader) | CMR automation zero-reconciliation (new version) |
| `BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations` | SP (reader) | EY audit unrealized PnL calculations |
| `BI_DB_dbo.SP_Client_Balance_Breakdown_Quick` | SP (reader) | Quick variant query |

---

## ETL Orchestration (OpsDB)

- **OpsDB Priority:** 20 (third wave — depends on P0 and P15 outputs)
- **Frequency:** `SB_Daily` (daily run)
- **ProcessType:** 3 (SQL & TIME)
- **Delete-Insert pattern:** DELETE WHERE DateID = @DateID, then INSERT from #withCIDData GROUP BY all dimension columns
- **Writer:** `BI_DB_dbo.SP_Client_Balance_Breakdown @Date`
