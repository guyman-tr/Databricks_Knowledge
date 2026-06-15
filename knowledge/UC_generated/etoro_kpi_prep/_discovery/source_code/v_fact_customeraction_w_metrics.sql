-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_fact_customeraction_w_metrics
-- Captured: 2026-05-19T12:13:04Z
-- ==========================================================================

with recurring_positions as (
  select distinct
    dp.PositionID,
    rpi.DepositID
  from
    main.general.bronze_recurringinvestment_recurringinvestment_planinstances rpi
    left join main.dwh.dim_position dp
      on rpi.OrderID = dp.OrderID
)
select
  fca.GCID,
  fca.RealCID,
  fca.Occurred,
  fca.ActionTypeID,
  fca.PlatformTypeID,
  fca.InstrumentID,
  fca.Amount,
  fca.Leverage,
  fca.NetProfit,
  fca.Commission,
  fca.PositionID,
  fca.FundingTypeID,
  fca.MirrorID,
  fca.WithdrawID,
  fca.DateID,
  fca.CompensationReasonID,
  fca.WithdrawPaymentID,
  fca.CommissionOnClose,
  fca.DepositID,
  fca.FullCommission,
  fca.FullCommissionOnClose,
  fca.RedeemID,
  fca.RedeemStatus,
  fca.IsRedeem,
  fca.ReopenForPositionID,
  fca.IsReOpen,
  fca.CommissionOnCloseOrig,
  fca.FullCommissionOnCloseOrig,
  fca.OriginalPositionID,
  fca.IsPartialCloseParent,
  fca.IsPartialCloseChild,
  fca.PaymentStatusID,
  fca.IsDiscounted,
  fca.IsSettled,
  fca.CommissionByUnits,
  fca.FullCommissionByUnits,
  fca.IsFTD,
  fca.IsFeeDividend,
  fca.IsAirDrop,
  fca.DividendID,
  fca.MoveMoneyReasonID,
  fca.SettlementTypeID,
  fca.etr_y,
  fca.etr_ym,
  fca.etr_ymd,
  fca.DLTOpen,
  fca.DLTClose,
  fca.OpenMarkupByUnits,
  fca.Description,
  fca.IsBuy,
  fca.CreditID,
  fca.OpenDateID,
  fca.CloseDateID,
  fca.TicketFeeAction,
  case when actiontypeid = 35 and isfeedividend = 1 then -1 * fca.Amount else 0 end as RollOverFee,
  case when actiontypeid = 35 and isfeedividend = 2 then fca.Amount else 0 end as Dividend,
  case when actiontypeid = 35 and isfeedividend = 3 then -1 * fca.Amount else 0 end as SDRT,
  case when actiontypeid = 36 and CompensationReasonID = 117 then -1 * fca.Amount else 0 end as AdminFee,
  case when actiontypeid = 36 and CompensationReasonID = 118 then -1 * fca.Amount else 0 end as SpotAdjustFee,
  case when actiontypeid IN (7, 44) and dwfd.DepositID is not null then dwfd.PIPsCalculation else 0 end as ConversionFeeDeposit,
  case when actiontypeid IN (8, 45) and dwfw.WithdrawPaymentID is not null then dwfw.PIPsCalculation else 0 end as ConversionFeeWithdraw,
  case when dwfdr.depositid is not null then -1 * dwfdr.PIPsCalculation else 0 end as ConversionFeeReversal,
  case when actiontypeid = 30 and isredeem = 0 then Commission else 0 end as CashoutFeeExludingRedeem,
  case when actiontypeid = 30 and isredeem = 1 then Commission else 0 end as TransferCoinFee,
  case when actiontypeid = 36 and CompensationReasonID = 30 then -1 * fca.Amount else 0 end as DormantFee,
  case when actiontypeid = 36 and CompensationReasonID = 119 then fca.Amount else 0 end as ShareLendingFeeEtoroShare,
  case when actiontypeid = 36 and CompensationReasonID = 119 then fca.Amount else 0 end as ShareLendingFeeUserShare,
  case when actiontypeid = 36 and CompensationReasonID = 119 then fca.Amount / round(0.425, 1) - 2 * (fca.Amount) else 0 end as ShareLendingFeeBrokerShare,
  case when actiontypeid = 36 and CompensationReasonID = 119 then 2 * fca.Amount + fca.Amount / round(0.425, 1) - 2 * (fca.Amount) else 0 end as ShareLendingGrossAmount,
  case when actiontypeid = 36 and CompensationReasonID in (41, 51) then fca.Amount else 0 end as CashoutAdjustment,
  case when actiontypeid = 17 then -1 * fca.Amount else 0 end as NewCopyAmount,
  case when actiontypeid = 18 then fca.Amount else 0 end as StopCopyAmount,
  case when actiontypeid = 15 then -1 * fca.Amount else 0 end as AddToCopyAmount,
  case when actiontypeid = 16 then fca.Amount else 0 end as RemoveFromCopyAmount,
  case when actiontypeid = 36 and CompensationReasonID = 134 then fca.Amount else 0 end as CryptoToPosition,
  case when actiontypeid = 9 then fca.Amount else 0 end as BonusCompensation,
  case when actiontypeid = 36 and CompensationReasonID = 22 then fca.Amount else 0 end as PnLAdjustment,
  case when actiontypeid IN (1, 2, 3, 39) THEN fca.Amount else 0 end as InvestedAmountIn,
  case when actiontypeid IN (4, 5, 6, 28, 40) THEN fca.Amount else 0 end as InvestedAmountOut,
  case when actiontypeid IN (1, 2, 3, 39) THEN fca.VolumeOnOpen else 0 end as VolumeOpen,
  case when actiontypeid IN (4, 5, 6, 28, 40) THEN fca.VolumeOnClose else 0 end as VolumeClose,
  case when actiontypeid = 35 and IsFeeDividend = 4 and ticketfeeaction = 'Open' THEN -1 * fca.Amount else 0 end as TicketFeeOpen,
  case when actiontypeid = 35 and IsFeeDividend = 4 and ticketfeeaction = 'Close' THEN -1 * fca.Amount else 0 end as TicketFeeClose,
  case when fca.actiontypeid IN (4, 5, 6, 28, 40) then (fca.FullCommissionOnClose - fca.FullCommissionByUnits) else 0 end as FullCommissionCloseAdjustment,
  case when fca.actiontypeid IN (4, 5, 6, 28, 40) then (fca.CommissionOnClose - fca.CommissionByUnits) else 0 end as CommissionCloseAdjustment,
  case when actiontypeid IN (1, 2, 3, 39) then fca.FullCommission when actiontypeid IN (4, 5, 6, 28, 40) then (fca.FullCommissionOnClose - fca.FullCommissionByUnits) else 0 end as FullCommissionTotal,
  case when actiontypeid IN (1, 2, 3, 39) then fca.Commission when actiontypeid IN (4, 5, 6, 28, 40) then (fca.CommissionOnClose - fca.CommissionByUnits) else 0 end as CommissionTotal,
  case when (fca.actiontypeid = 1 and coalesce(fca.IsAirDrop, 0) = 0 and fca.mirrorid = 0) or actiontypeid in (15, 17) then 1 else 0 end as IsActiveTrade,
  case when di.IsSQF = 1 then 1 else 0 end as IsSQF,
  case when di.Is_245_Instrument = 1 then 1 else 0 end as Is_245_Instrument,
  case when dm.mirrortypeid = 4 then 1 else 0 end as IsCopyFund,
  dm.ParentCID,
  dm.ParentUserName,
  case when ofi.TreeID is not null then 1 else 0 end as IsOpenFromIBAN,
  case when cti.positionid is not null then 1 else 0 end as IsClosedToIBAN,
  case when actiontypeid IN (1,2,3,39,4,5,6,28,40,35) and rip.positionid is not null then 1
       when actiontypeid = 36 and CompensationReasonID IN (117,118) and rip.positionid is not null then 1
       when actiontypeid IN (7,44) and ripdep.depositid is not null then 1
       else 0 end as IsRecurring,
  case when apl.positionid is not null then 1 else 0 end as IsC2P
from main.etoro_kpi_prep.v_fact_customeraction_enriched fca
  left join main.etoro_kpi_prep.v_dim_instrument_enriched di
    on fca.InstrumentID = di.InstrumentID
  left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee dwfd
    on fca.depositid = dwfd.DepositID
  left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee dwfw
    on fca.WithdrawPaymentID = dwfw.WithdrawPaymentID and dwfw.TransactionType = 'Withdraw'
  left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals dwfdr
    on fca.CreditID = dwfdr.CreditID
  left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm
    on fca.MirrorID = dm.MirrorID
  left join (select distinct TreeID from main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban) ofi
    on fca.PositionID = ofi.TreeID
  left join (select distinct PositionID from main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban) cti
    on fca.PositionID = cti.PositionID
  left join (select distinct PositionID from recurring_positions where PositionID is not null) rip
    on fca.PositionID = rip.PositionID
  left join (select distinct DepositID from recurring_positions where DepositID is not null) ripdep
    on fca.DepositID = ripdep.DepositID
  left join (select distinct positionid from main.bi_db.bronze_etoro_trade_adminpositionlog where CompensationReasonID = 134) apl
    on fca.PositionID = apl.positionid
where ActionTypeID not in (14, 41)
