# G3 Stratified Review Sheet

Source: `audits\_desc_quality_rewrite_corpus9\proposed_fixes.csv`

Sample size: **30**  (sql=3, v_liabilities=7, other=20)

Random seed: 42

Mark each item as `APPROVE / REJECT / EDIT(<your note>)` in the `VERDICT` line.

---

## [1/30] [SQL-derived] `ClosedOnDate` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `ClosedOnDate`
- **old**: Direct
- **new**: ISNULL(dp.ClosedOnDate, 0) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: 1 when (dp.CloseDateID = @dateID) OR 0 (fallback); where dp = DWH_dbo.Dim_Position
- **trace**:
```
  hop[0] Function_PnL_Single_Day.ClosedOnDate [TRIVIAL] note='sql_walk:coalesce'
  sql_walk: kind=coalesce object=Function_PnL_Single_Day converge=False leaves=2
```
- **VERDICT**: _________________________________

---

## [2/30] [SQL-derived] `IsCopyFund` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `IsCopyFund`
- **old**: Direct
- **new**: CASE WHEN NOT cpt.PositionID IS NULL THEN 1 ELSE 0 END (sql-derived [case] from Function_PnL_Single_Day); where cpt = BI_DB_dbo.BI_DB_CopyFund_Positions
- **trace**:
```
  hop[0] Function_PnL_Single_Day.IsCopyFund [TRIVIAL] note='sql_walk:coalesce'
  sql_walk: kind=coalesce object=Function_PnL_Single_Day converge=True leaves=3
```
- **VERDICT**: _________________________________

---

## [3/30] [SQL-derived] `IsMarginTrade` — `Function_PnL_Single_Day.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md`
- **column**: `IsMarginTrade`
- **old**: Direct
- **new**: COALESCE(dp.IsMarginTrade, upl.IsMarginTrade) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END OR CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END; where dp = DWH_dbo.Dim_Position, bdppl = BI_DB_dbo.BI_DB_PositionPnL
- **trace**:
```
  hop[0] Function_PnL_Single_Day.IsMarginTrade [TRIVIAL] note='sql_walk:coalesce'
  sql_walk: kind=coalesce object=Function_PnL_Single_Day converge=False leaves=3
```
- **VERDICT**: _________________________________

---

## [4/30] [V_Liabilities] `PositionPnLStocksReal` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `PositionPnLStocksReal`
- **old**: Direct
- **new**: Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) (via Fact_CustomerUnrealized_PnL)
- **trace**:
```
  hop[0] V_Liabilities.PositionPnLStocksReal [TRIVIAL] src='Fact_CustomerUnrealized_PnL.PositionPnLStocksReal'
  hop[1] Fact_CustomerUnrealized_PnL.PositionPnLStocksReal [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [5/30] [V_Liabilities] `MirrorStocksPositionPnL` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `MirrorStocksPositionPnL`
- **old**: Direct
- **new**: Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) (via Fact_CustomerUnrealized_PnL)
- **trace**:
```
  hop[0] V_Liabilities.MirrorStocksPositionPnL [TRIVIAL] src='Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL'
  hop[1] Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [6/30] [V_Liabilities] `CopyCryptoPositionPnL_TRS` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `CopyCryptoPositionPnL_TRS`
- **old**: Direct
- **new**: Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) (via Fact_CustomerUnrealized_PnL)
- **trace**:
```
  hop[0] V_Liabilities.CopyCryptoPositionPnL_TRS [TRIVIAL] src='Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS'
  hop[1] Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [7/30] [V_Liabilities] `Notional_CFD` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `Notional_CFD`
- **old**: Direct
- **new**: Absolute USD exposure for all CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) (via Fact_CustomerUnrealized_PnL)
- **trace**:
```
  hop[0] V_Liabilities.Notional_CFD [TRIVIAL] src='Fact_CustomerUnrealized_PnL.Notional_CFD'
  hop[1] Fact_CustomerUnrealized_PnL.Notional_CFD [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [8/30] [V_Liabilities] `CommissionOnOpen` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `CommissionOnOpen`
- **old**: Direct
- **new**: Sum of opening commissions (Commission) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) (via Fact_CustomerUnrealized_PnL)
- **trace**:
```
  hop[0] V_Liabilities.CommissionOnOpen [TRIVIAL] src='Fact_CustomerUnrealized_PnL.CommissionOnOpen'
  hop[1] Fact_CustomerUnrealized_PnL.CommissionOnOpen [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [9/30] [V_Liabilities] `TotalStockMarginLoanValue` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `TotalStockMarginLoanValue`
- **old**: Direct
- **new**: Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) (via Fact_SnapshotEquity)
- **trace**:
```
  hop[0] V_Liabilities.TotalStockMarginLoanValue [TRIVIAL] src='Fact_SnapshotEquity.TotalStockMarginLoanValue'
  hop[1] Fact_SnapshotEquity.TotalStockMarginLoanValue [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [10/30] [V_Liabilities] `TotalRealFutures` — `V_Liabilities.md`

- **wiki**: `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md`
- **column**: `TotalRealFutures`
- **old**: Direct
- **new**: Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30. (Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount) (via Fact_SnapshotEquity)
- **trace**:
```
  hop[0] V_Liabilities.TotalRealFutures [TRIVIAL] src='Fact_SnapshotEquity.TotalRealFutures'
  hop[1] Fact_SnapshotEquity.TotalRealFutures [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [11/30] [other] `AffiliateID` — `Function_Revenue_SpotAdjustFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_SpotAdjustFee.md`
- **column**: `AffiliateID`
- **old**: Direct
- **new**: Affiliate/partner who referred this customer. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_SpotAdjustFee.AffiliateID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.AffiliateID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [12/30] [other] `EvMatchStatus` — `Function_Revenue_InterestFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_InterestFee.md`
- **column**: `EvMatchStatus`
- **old**: Direct
- **new**: eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_InterestFee.EvMatchStatus [TRIVIAL] src='Fact_SnapshotCustomer.EvMatchStatus'
  hop[1] Fact_SnapshotCustomer.EvMatchStatus [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [13/30] [other] `GuruStatusID` — `Function_Revenue_Dividend.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Dividend.md`
- **column**: `GuruStatusID`
- **old**: Direct
- **new**: Popular Investor (Guru) program status. DEFAULT 0. FK to Dim_GuruStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_Dividend.GuruStatusID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.GuruStatusID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [14/30] [other] `RiskClassificationID` — `Function_Revenue_StakingFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_StakingFee.md`
- **column**: `RiskClassificationID`
- **old**: Direct
- **new**: Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_StakingFee.RiskClassificationID [TRIVIAL] src='Fact_SnapshotCustomer.RiskClassificationID'
  hop[1] Fact_SnapshotCustomer.RiskClassificationID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [15/30] [other] `IsPhoneVerified` — `Function_Revenue_StakingFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_StakingFee.md`
- **column**: `IsPhoneVerified`
- **old**: Direct
- **new**: 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_StakingFee.IsPhoneVerified [TRIVIAL] src='Fact_SnapshotCustomer.IsPhoneVerified'
  hop[1] Fact_SnapshotCustomer.IsPhoneVerified [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [16/30] [other] `RealCID` — `Function_Revenue_SpotAdjustFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_SpotAdjustFee.md`
- **column**: `RealCID`
- **old**: Direct
- **new**: Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_SpotAdjustFee.RealCID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.RealCID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.RealCID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [17/30] [other] `CID` — `Function_Revenue_ConversionFee_WithPositionData.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.md`
- **column**: `CID`
- **old**: Direct
- **new**: Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID) (via BI_DB_DepositWithdrawFee)
- **trace**:
```
  hop[0] Function_Revenue_ConversionFee_WithPositionData.CID [TRIVIAL] src='BI_DB_DepositWithdrawFee.CID'
  hop[1] BI_DB_DepositWithdrawFee.CID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [18/30] [other] `BaseExchangeRate` — `Function_Revenue_ConversionFee_WithPositionData.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.md`
- **column**: `BaseExchangeRate`
- **old**: Direct
- **new**: Base FX rate from state. (Tier 2 -SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate) (via BI_DB_DepositWithdrawFee)
- **trace**:
```
  hop[0] Function_Revenue_ConversionFee_WithPositionData.BaseExchangeRate [TRIVIAL] src='BI_DB_DepositWithdrawFee.BaseExchangeRate'
  hop[1] BI_DB_DepositWithdrawFee.BaseExchangeRate [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [19/30] [other] `AffiliateID` — `Function_Revenue_InterestFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_InterestFee.md`
- **column**: `AffiliateID`
- **old**: Direct
- **new**: Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_InterestFee.AffiliateID [TRIVIAL] src='Fact_SnapshotCustomer.AffiliateID'
  hop[1] Fact_SnapshotCustomer.AffiliateID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [20/30] [other] `PendingClosureStatusID` — `Function_Revenue_DormantFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_DormantFee.md`
- **column**: `PendingClosureStatusID`
- **old**: Direct
- **new**: Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_DormantFee.PendingClosureStatusID [TRIVIAL] src='Fact_SnapshotCustomer.PendingClosureStatusID'
  hop[1] Fact_SnapshotCustomer.PendingClosureStatusID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [21/30] [other] `ActionTypeID` — `Function_Revenue_Trading_Fees_Breakdown.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Trading_Fees_Breakdown.md`
- **column**: `ActionTypeID`
- **old**: Direct
- **new**: Event type classifier. Filtered to 4 values: 35 (ticket fees, ~97%), 36 (compensations with reason 56/117/118), 32 (edit stop-loss), 19 (detach from mirror). FK to Dim_ActionType. (Tier 1 — DWH_dbo.Fact_CustomerAction) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_Trading_Fees_Breakdown.ActionTypeID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.ActionTypeID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.ActionTypeID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [22/30] [other] `LabelID` — `Function_Revenue_ConversionFee_WithPositionData.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.md`
- **column**: `LabelID`
- **old**: Direct
- **new**: Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_ConversionFee_WithPositionData.LabelID [TRIVIAL] src='Fact_SnapshotCustomer.LabelID'
  hop[1] Fact_SnapshotCustomer.LabelID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [23/30] [other] `CompanyInfo` — `Function_Instrument_Snapshot_Enriched.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md`
- **column**: `CompanyInfo`
- **old**: Direct
- **new**: Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) (via Dim_Instrument)
- **trace**:
```
  hop[0] Function_Instrument_Snapshot_Enriched.CompanyInfo [TRIVIAL] src='isn.CompanyInfo' note='alias:isn->Dim_Instrument'
  hop[1] Dim_Instrument.CompanyInfo [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [24/30] [other] `IsFuture` — `Function_Instrument_Snapshot_Enriched.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md`
- **column**: `IsFuture`
- **old**: Direct
- **new**: 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument)
- **trace**:
```
  hop[0] Function_Instrument_Snapshot_Enriched.IsFuture [TRIVIAL] src='isn.IsFuture' note='alias:isn->Dim_Instrument'
  hop[1] Dim_Instrument.IsFuture [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [25/30] [other] `LabelID` — `Function_Revenue_AdminFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_AdminFee.md`
- **column**: `LabelID`
- **old**: Direct
- **new**: Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. FK to Dim_Label. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_AdminFee.LabelID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.LabelID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.LabelID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [26/30] [other] `MifidCategorizationID` — `Function_Revenue_Dividend.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Dividend.md`
- **column**: `MifidCategorizationID`
- **old**: Direct
- **new**: MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. FK to Dim_MifidCategorization. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_Dividend.MifidCategorizationID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.MifidCategorizationID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [27/30] [other] `LanguageID` — `Function_Revenue_ConversionFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee.md`
- **column**: `LanguageID`
- **old**: Direct
- **new**: Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_ConversionFee.LanguageID [TRIVIAL] src='Fact_SnapshotCustomer.LanguageID'
  hop[1] Fact_SnapshotCustomer.LanguageID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [28/30] [other] `SuitabilityTestStatusID` — `Function_Revenue_CryptoToFiat_C2F.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CryptoToFiat_C2F.md`
- **column**: `SuitabilityTestStatusID`
- **old**: Direct
- **new**: MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_CryptoToFiat_C2F.SuitabilityTestStatusID [TRIVIAL] src='Fact_SnapshotCustomer.SuitabilityTestStatusID'
  hop[1] Fact_SnapshotCustomer.SuitabilityTestStatusID [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---

## [29/30] [other] `PlayerStatusID` — `Function_Revenue_RolloverFee.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_RolloverFee.md`
- **column**: `PlayerStatusID`
- **old**: Direct
- **new**: Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) (via BI_DB_Fact_Customer_Action_Position_Distribution)
- **trace**:
```
  hop[0] Function_Revenue_RolloverFee.PlayerStatusID [TRIVIAL] src='BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID'
  hop[1] BI_DB_Fact_Customer_Action_Position_Distribution.PlayerStatusID [HAS_SEMANTIC]
```
- **VERDICT**: _________________________________

---

## [30/30] [other] `IsPhoneVerified` — `Function_Revenue_FullCommissions.md`

- **wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_FullCommissions.md`
- **column**: `IsPhoneVerified`
- **old**: Direct
- **new**: 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer)
- **trace**:
```
  hop[0] Function_Revenue_FullCommissions.IsPhoneVerified [TRIVIAL] src='Fact_SnapshotCustomer.IsPhoneVerified'
  hop[1] Fact_SnapshotCustomer.IsPhoneVerified [HAS_TRANSFORMATION]
```
- **VERDICT**: _________________________________

---
