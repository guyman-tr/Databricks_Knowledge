# Column Lineage: main.etoro_kpi_prep.v_fact_customeraction_w_metrics

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_fact_customeraction_w_metrics.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_fact_customeraction_w_metrics.json` (rows: 97, mismatches: 41) |
| **Primary upstream** | `main.etoro_kpi_prep.v_fact_customeraction_enriched` |
| **Generated** | 2026-05-17 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.bronze_etoro_trade_adminpositionlog` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\Trade\Tables\Trade.AdminPositionLog.md` |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_dim_instrument_enriched.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee_Reversals.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.etoro_kpi_prep.v_fact_customeraction_enriched` | Primary (FROM) | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_fact_customeraction_enriched.md` |
| `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | JOIN / referenced | ✓ `knowledge\ProdSchemas\ExperianceDBs\RecurringInvestment\Wiki\RecurringInvestment\Tables\RecurringInvestment.PlanInstances.md` |

## Lineage Chain

```
main.etoro_kpi_prep.v_fact_customeraction_enriched   ←── primary upstream
  + main.etoro_kpi_prep.v_dim_instrument_enriched   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban   (JOIN)
  + main.bi_db.bronze_etoro_trade_adminpositionlog   (JOIN)
  + main.general.bronze_recurringinvestment_recurringinvestment_planinstances   (JOIN)
  + main.dwh.dim_position   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_fact_customeraction_w_metrics   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `GCID` | `passthrough` | — | fca.GCID |
| 2 | `RealCID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `RealCID` | `passthrough` | — | fca.RealCID |
| 3 | `Occurred` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `Occurred` | `passthrough` | — | fca.Occurred |
| 4 | `ActionTypeID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `ActionTypeID` | `passthrough` | — | fca.ActionTypeID |
| 5 | `PlatformTypeID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `PlatformTypeID` | `passthrough` | — | fca.PlatformTypeID |
| 6 | `InstrumentID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `InstrumentID` | `passthrough` | — | fca.InstrumentID |
| 7 | `Amount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `Amount` | `passthrough` | — | fca.Amount |
| 8 | `Leverage` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `Leverage` | `passthrough` | — | fca.Leverage |
| 9 | `NetProfit` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `NetProfit` | `passthrough` | — | fca.NetProfit |
| 10 | `Commission` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `Commission` | `passthrough` | — | fca.Commission |
| 11 | `PositionID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `PositionID` | `passthrough` | — | fca.PositionID |
| 12 | `FundingTypeID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `FundingTypeID` | `passthrough` | — | fca.FundingTypeID |
| 13 | `MirrorID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `MirrorID` | `passthrough` | — | fca.MirrorID |
| 14 | `WithdrawID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `WithdrawID` | `passthrough` | — | fca.WithdrawID |
| 15 | `DateID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `DateID` | `passthrough` | — | fca.DateID |
| 16 | `CompensationReasonID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CompensationReasonID` | `passthrough` | — | fca.CompensationReasonID |
| 17 | `WithdrawPaymentID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `WithdrawPaymentID` | `passthrough` | — | fca.WithdrawPaymentID |
| 18 | `CommissionOnClose` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CommissionOnClose` | `passthrough` | — | fca.CommissionOnClose |
| 19 | `DepositID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `DepositID` | `passthrough` | — | fca.DepositID |
| 20 | `FullCommission` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `FullCommission` | `passthrough` | — | fca.FullCommission |
| 21 | `FullCommissionOnClose` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `FullCommissionOnClose` | `passthrough` | — | fca.FullCommissionOnClose |
| 22 | `RedeemID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `RedeemID` | `passthrough` | — | fca.RedeemID |
| 23 | `RedeemStatus` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `RedeemStatus` | `passthrough` | — | fca.RedeemStatus |
| 24 | `IsRedeem` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsRedeem` | `passthrough` | — | fca.IsRedeem |
| 25 | `ReopenForPositionID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `ReopenForPositionID` | `passthrough` | — | fca.ReopenForPositionID |
| 26 | `IsReOpen` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsReOpen` | `passthrough` | — | fca.IsReOpen |
| 27 | `CommissionOnCloseOrig` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CommissionOnCloseOrig` | `passthrough` | — | fca.CommissionOnCloseOrig |
| 28 | `FullCommissionOnCloseOrig` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `FullCommissionOnCloseOrig` | `passthrough` | — | fca.FullCommissionOnCloseOrig |
| 29 | `OriginalPositionID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `OriginalPositionID` | `passthrough` | — | fca.OriginalPositionID |
| 30 | `IsPartialCloseParent` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsPartialCloseParent` | `passthrough` | — | fca.IsPartialCloseParent |
| 31 | `IsPartialCloseChild` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsPartialCloseChild` | `passthrough` | — | fca.IsPartialCloseChild |
| 32 | `PaymentStatusID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `PaymentStatusID` | `passthrough` | — | fca.PaymentStatusID |
| 33 | `IsDiscounted` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsDiscounted` | `passthrough` | — | fca.IsDiscounted |
| 34 | `IsSettled` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsSettled` | `passthrough` | — | fca.IsSettled |
| 35 | `CommissionByUnits` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CommissionByUnits` | `passthrough` | — | fca.CommissionByUnits |
| 36 | `FullCommissionByUnits` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `FullCommissionByUnits` | `passthrough` | — | fca.FullCommissionByUnits |
| 37 | `IsFTD` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsFTD` | `passthrough` | — | fca.IsFTD |
| 38 | `IsFeeDividend` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsFeeDividend` | `passthrough` | — | fca.IsFeeDividend |
| 39 | `IsAirDrop` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsAirDrop` | `passthrough` | — | fca.IsAirDrop |
| 40 | `DividendID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `DividendID` | `passthrough` | — | fca.DividendID |
| 41 | `MoveMoneyReasonID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `MoveMoneyReasonID` | `passthrough` | — | fca.MoveMoneyReasonID |
| 42 | `SettlementTypeID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `SettlementTypeID` | `passthrough` | — | fca.SettlementTypeID |
| 43 | `etr_y` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `etr_y` | `passthrough` | — | fca.etr_y |
| 44 | `etr_ym` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `etr_ym` | `passthrough` | — | fca.etr_ym |
| 45 | `etr_ymd` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `etr_ymd` | `passthrough` | — | fca.etr_ymd |
| 46 | `DLTOpen` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `DLTOpen` | `passthrough` | — | fca.DLTOpen |
| 47 | `DLTClose` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `DLTClose` | `passthrough` | — | fca.DLTClose |
| 48 | `OpenMarkupByUnits` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `OpenMarkupByUnits` | `passthrough` | — | fca.OpenMarkupByUnits |
| 49 | `Description` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `Description` | `passthrough` | — | fca.Description |
| 50 | `IsBuy` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `IsBuy` | `passthrough` | — | fca.IsBuy |
| 51 | `CreditID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CreditID` | `passthrough` | — | fca.CreditID |
| 52 | `OpenDateID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `OpenDateID` | `passthrough` | — | fca.OpenDateID |
| 53 | `CloseDateID` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `CloseDateID` | `passthrough` | — | fca.CloseDateID |
| 54 | `TicketFeeAction` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `TicketFeeAction` | `passthrough` | — | fca.TicketFeeAction |
| 55 | `RollOverFee` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 35 AND isfeedividend = 1 THEN -1 * fca.Amount ELSE 0 END AS RollOverFee |
| 56 | `Dividend` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 35 AND isfeedividend = 2 THEN fca.Amount ELSE 0 END AS Dividend |
| 57 | `SDRT` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 35 AND isfeedividend = 3 THEN -1 * fca.Amount ELSE 0 END AS SDRT |
| 58 | `AdminFee` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 117 THEN -1 * fca.Amount ELSE 0 END AS AdminFee |
| 59 | `SpotAdjustFee` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 118 THEN -1 * fca.Amount ELSE 0 END AS SpotAdjustFee |
| 60 | `ConversionFeeDeposit` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (7, 44) AND NOT dwfd.DepositID IS NULL THEN dwfd.PIPsCalculation ELSE 0 END AS ConversionFeeDeposit |
| 61 | `ConversionFeeWithdraw` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (8, 45) AND NOT dwfw.WithdrawPaymentID IS NULL THEN dwfw.PIPsCalculation ELSE 0 END AS ConversionFeeWithdraw |
| 62 | `ConversionFeeReversal` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | `—` | `case` | — | CASE WHEN NOT dwfdr.depositid IS NULL THEN -1 * dwfdr.PIPsCalculation ELSE 0 END AS ConversionFeeReversal |
| 63 | `CashoutFeeExludingRedeem` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 30 AND isredeem = 0 THEN Commission ELSE 0 END AS CashoutFeeExludingRedeem |
| 64 | `TransferCoinFee` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 30 AND isredeem = 1 THEN Commission ELSE 0 END AS TransferCoinFee |
| 65 | `DormantFee` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 30 THEN -1 * fca.Amount ELSE 0 END AS DormantFee |
| 66 | `ShareLendingFeeEtoroShare` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 119 THEN fca.Amount ELSE 0 END AS ShareLendingFeeEtoroShare |
| 67 | `ShareLendingFeeUserShare` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 119 THEN fca.Amount ELSE 0 END AS ShareLendingFeeUserShare |
| 68 | `ShareLendingFeeBrokerShare` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 119 THEN fca.Amount / ROUND(0.425, 1) - 2 * (fca.Amount) ELSE 0 END AS ShareLendingFe |
| 69 | `ShareLendingGrossAmount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 119 THEN 2 * fca.Amount + fca.Amount / ROUND(0.425, 1) - 2 * (fca.Amount) ELSE 0 END  |
| 70 | `CashoutAdjustment` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID IN (41, 51) THEN fca.Amount ELSE 0 END AS CashoutAdjustment |
| 71 | `NewCopyAmount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 17 THEN -1 * fca.Amount ELSE 0 END AS NewCopyAmount |
| 72 | `StopCopyAmount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 18 THEN fca.Amount ELSE 0 END AS StopCopyAmount |
| 73 | `AddToCopyAmount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 15 THEN -1 * fca.Amount ELSE 0 END AS AddToCopyAmount |
| 74 | `RemoveFromCopyAmount` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 16 THEN fca.Amount ELSE 0 END AS RemoveFromCopyAmount |
| 75 | `CryptoToPosition` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 134 THEN fca.Amount ELSE 0 END AS CryptoToPosition |
| 76 | `BonusCompensation` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 9 THEN fca.Amount ELSE 0 END AS BonusCompensation |
| 77 | `PnLAdjustment` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 36 AND CompensationReasonID = 22 THEN fca.Amount ELSE 0 END AS PnLAdjustment |
| 78 | `InvestedAmountIn` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (1, 2, 3, 39) THEN fca.Amount ELSE 0 END AS InvestedAmountIn |
| 79 | `InvestedAmountOut` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (4, 5, 6, 28, 40) THEN fca.Amount ELSE 0 END AS InvestedAmountOut |
| 80 | `VolumeOpen` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (1, 2, 3, 39) THEN fca.VolumeOnOpen ELSE 0 END AS VolumeOpen |
| 81 | `VolumeClose` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (4, 5, 6, 28, 40) THEN fca.VolumeOnClose ELSE 0 END AS VolumeClose |
| 82 | `TicketFeeOpen` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 35 AND IsFeeDividend = 4 AND ticketfeeaction = 'Open' THEN -1 * fca.Amount ELSE 0 END AS TicketFeeOpen |
| 83 | `TicketFeeClose` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid = 35 AND IsFeeDividend = 4 AND ticketfeeaction = 'Close' THEN -1 * fca.Amount ELSE 0 END AS TicketFeeClose |
| 84 | `FullCommissionCloseAdjustment` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN fca.actiontypeid IN (4, 5, 6, 28, 40) THEN (fca.FullCommissionOnClose - fca.FullCommissionByUnits) ELSE 0 END AS FullCommissionClo |
| 85 | `CommissionCloseAdjustment` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN fca.actiontypeid IN (4, 5, 6, 28, 40) THEN (fca.CommissionOnClose - fca.CommissionByUnits) ELSE 0 END AS CommissionCloseAdjustment |
| 86 | `FullCommissionTotal` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (1, 2, 3, 39) THEN fca.FullCommission WHEN actiontypeid IN (4, 5, 6, 28, 40) THEN (fca.FullCommissionOnClose - fca |
| 87 | `CommissionTotal` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (1, 2, 3, 39) THEN fca.Commission WHEN actiontypeid IN (4, 5, 6, 28, 40) THEN (fca.CommissionOnClose - fca.Commiss |
| 88 | `IsActiveTrade` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN (fca.actiontypeid = 1 AND COALESCE(fca.IsAirDrop, 0) = 0 AND fca.mirrorid = 0) OR actiontypeid IN (15, 17) THEN 1 ELSE 0 END AS Is |
| 89 | `IsSQF` | `main.etoro_kpi_prep.v_dim_instrument_enriched` | `—` | `case` | — | CASE WHEN di.IsSQF = 1 THEN 1 ELSE 0 END AS IsSQF |
| 90 | `Is_245_Instrument` | `main.etoro_kpi_prep.v_dim_instrument_enriched` | `—` | `case` | — | CASE WHEN di.Is_245_Instrument = 1 THEN 1 ELSE 0 END AS Is_245_Instrument |
| 91 | `IsCopyFund` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `—` | `case` | — | CASE WHEN dm.mirrortypeid = 4 THEN 1 ELSE 0 END AS IsCopyFund |
| 92 | `ParentCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentCID` | `join_enriched` | (Tier 1 — Trade.Mirror) | dm.ParentCID |
| 93 | `ParentUserName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentUserName` | `join_enriched` | (Tier 1 — Trade.Mirror) | dm.ParentUserName |
| 94 | `IsOpenFromIBAN` | `—` | `—` | `case` | — | CASE WHEN NOT ofi.TreeID IS NULL THEN 1 ELSE 0 END AS IsOpenFromIBAN |
| 95 | `IsClosedToIBAN` | `—` | `—` | `case` | — | CASE WHEN NOT cti.positionid IS NULL THEN 1 ELSE 0 END AS IsClosedToIBAN |
| 96 | `IsRecurring` | `main.etoro_kpi_prep.v_fact_customeraction_enriched` | `—` | `case` | — | CASE WHEN actiontypeid IN (1, 2, 3, 39, 4, 5, 6, 28, 40, 35) AND NOT rip.positionid IS NULL THEN 1 WHEN actiontypeid = 36 AND CompensationRe |
| 97 | `IsC2P` | `—` | `—` | `case` | — | CASE WHEN NOT apl.positionid IS NULL THEN 1 ELSE 0 END AS IsC2P |

## Cross-check vs system.access.column_lineage

- Total target columns: **97**
- OK: **56**, WARN: **0**, ERROR: **41**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RollOverFee` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isfeedividend` | ERROR |
| `Dividend` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isfeedividend` | ERROR |
| `SDRT` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isfeedividend` | ERROR |
| `AdminFee` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `SpotAdjustFee` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `ConversionFeeDeposit` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.depositid`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.pipscalculation`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid` | ERROR |
| `ConversionFeeWithdraw` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.pipscalculation`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.withdrawpaymentid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid` | ERROR |
| `ConversionFeeReversal` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals.depositid`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals.pipscalculation` | ERROR |
| `CashoutFeeExludingRedeem` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commission`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isredeem` | ERROR |
| `TransferCoinFee` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commission`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isredeem` | ERROR |
| `DormantFee` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `ShareLendingFeeEtoroShare` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `ShareLendingFeeUserShare` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `ShareLendingFeeBrokerShare` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `ShareLendingGrossAmount` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `CashoutAdjustment` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `NewCopyAmount` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `StopCopyAmount` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `AddToCopyAmount` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `RemoveFromCopyAmount` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `CryptoToPosition` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `BonusCompensation` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `PnLAdjustment` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid` | ERROR |
| `InvestedAmountIn` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `InvestedAmountOut` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount` | ERROR |
| `VolumeOpen` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.volumeonopen` | ERROR |
| `VolumeClose` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.volumeonclose` | ERROR |
| `TicketFeeOpen` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isfeedividend`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.ticketfeeaction` | ERROR |
| `TicketFeeClose` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.amount`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isfeedividend`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.ticketfeeaction` | ERROR |
| `FullCommissionCloseAdjustment` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.fullcommissionbyunits`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.fullcommissiononclose` | ERROR |
| `CommissionCloseAdjustment` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commissionbyunits`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commissiononclose` | ERROR |
| `FullCommissionTotal` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.fullcommission`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.fullcommissionbyunits`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.fullcommissiononclose` | ERROR |
| `CommissionTotal` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commission`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commissionbyunits`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.commissiononclose` | ERROR |
| `IsActiveTrade` | — | `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.isairdrop`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.mirrorid` | ERROR |
| `IsSQF` | — | `main.etoro_kpi_prep.v_dim_instrument_enriched.issqf` | ERROR |
| `Is_245_Instrument` | — | `main.etoro_kpi_prep.v_dim_instrument_enriched.is_245_instrument` | ERROR |
| `IsCopyFund` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrortypeid` | ERROR |
| `IsOpenFromIBAN` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban.treeid` | ERROR |
| `IsClosedToIBAN` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban.positionid` | ERROR |
| `IsRecurring` | — | `main.dwh.dim_position.positionid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.actiontypeid`, `main.etoro_kpi_prep.v_fact_customeraction_enriched.compensationreasonid`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.depositid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **43**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.etoro_kpi_prep.v_dim_instrument_enriched AS di ON fca.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee AS dwfd ON fca.depositid = dwfd.DepositID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee AS dwfw ON fca.WithdrawPaymentID = dwfw.WithdrawPaymentID AND dwfw.TransactionType = 'Withdraw'
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals AS dwfdr ON fca.CreditID = dwfdr.CreditID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror AS dm ON fca.MirrorID = dm.MirrorID
- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT TreeID FROM main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban) AS ofi ON fca.PositionID = ofi.TreeID
- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT PositionID FROM main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban) AS cti ON fca.PositionID = cti.PositionID
- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT PositionID FROM recurring_positions WHERE NOT PositionID IS NULL) AS rip ON fca.PositionID = rip.PositionID
- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT DepositID FROM recurring_positions WHERE NOT DepositID IS NULL) AS ripdep ON fca.DepositID = ripdep.DepositID
- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT positionid FROM main.bi_db.bronze_etoro_trade_adminpositionlog WHERE CompensationReasonID = 134) AS apl ON fca.PositionID = apl.positionid
