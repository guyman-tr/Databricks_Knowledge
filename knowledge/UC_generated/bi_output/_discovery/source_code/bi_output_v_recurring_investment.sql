-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_v_recurring_investment
-- Captured: 2026-06-19T14:29:38Z
-- ==========================================================================

select
  *,
  CASE
    WHEN
      MAX(ActivePlan) over (partition by ID order by NextOrderDate) = 1
      and ActivePlan = 0
    THEN
      1
    else 0
  END IsChurnPlan,
  CASE
    WHEN
      sum(ActivePlan) over (partition by CID, activemonth order by NextOrderDate ASC) >= 1
    --and ActivePlan = 0
    THEN
      1
    else 0
  END IsActiveUser --  isActiveUser = 0 is churn...
from
  (
    select
      DATE(date_trunc('month', ipi.NextOrderDate)) AS ActiveDate,
      date_format(ipi.NextOrderDate, 'yyyy-MM') AS ActiveMonth,
      ip.ID,
      ip.PlanType,
      pt.Name as PlaneTypeName,
      ip.GCID,
      ip.CID,
      ip.InstrumentID,
      ip.RecurringDepositID,
      ip.Amount,
      ip.CurrencyID,
      ip.PlanStatusID,
      ps.StatusName AS PlanStatusName,
      ip.DepositPlanStatusID,
      ip.StatusReasonID,
      ip.CreationDate AS PlanCreationDate,
      ip.EndDate,
      ip.ValidFrom,
      ip.ValidTo,
      ip.DepositStartDate,
      ip.RepeatsOn,
      ip.FrequencyID,
      ip.FundingID,
      ip.CopyType,
      ct.Name AS CopyTypeName,
      ip.Trace,
      ipi.InstanceID,
      ipi.InstanceStatusID,
      isi.InstanceStatusID AS InstanceStatusName,
      ipi.InstanceStatusReasonID,
      pec.EventName AS InstanceStatusReasonName,
      ipi.NextOrderDate,
      ipi.CreationDate,
      ipi.DepositID,
      ipi.DepositAmountUsd,
      ipi.DepositDate,
      ipi.DepositCycleNumber,
      ipi.HighLevelDepositStatusId,
      ipi.DepositStatusID,
      ipi.OrderID,
      ipi.OrderTradeDate,
      ipi.OrderStatusId,
      ipi.PositionExecutionDate,
      ipi.ValidFrom ValidFromInstance,
      ipi.ValidTo ValidToInstance,
      ipi.PositionFailErrorCode,
      ipi.MirrorID,
      ipi.MirrorOrderCreated,
      ipi.CopyPositionStatusID,
      ipi.CopyFailErrorCode,
      ipi.DepositFailReason,
      ipi.Trace TraceInstance,
      ip.CopyParentCID,
      ip.CopyparentGCID,
      ip.HasBackupPayment,
      ipi.PositionStatus PositionStatusID,
      ps2.PositionStatus PositionStatusName,
      CASE
        WHEN STRING(ipi.InstanceStatusID) in ('3', '4') THEN 1
        else 0
      END IsSkip,
      CASE
        WHEN
          max(DepositID) over (partition by ip.ID order by ipi.NextOrderDate ASC) is not null
          and ip.EndDate is null
          and ipi.DepositStatusID = 2
        THEN
          1
        else 0
      END ActivePlan,
      ipi.positionamountusd as PositionAmountUSD,
      ip.amountusd AS AmountUSD
    from
      main.general.bronze_recurringinvestment_recurringinvestment_planinstances ipi
        left join (
          select
            ID,
            GCID,
            CID,
            InstrumentID,
            RecurringDepositID,
            Amount,
            CurrencyID,
            PlanStatusID,
            DepositPlanStatusID,
            StatusReasonID,
            CreationDate,
            EndDate,
            DepositStartDate,
            FrequencyID,
            RepeatsOn,
            FundingID,
            Trace,
            ValidFrom,
            ValidTo,
            PlanType,
            CopyParentCID,
            CopyParentGCID,
            CopyType,
            HasBackupPayment,
            AmountUsd
          from
            main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans ip
          union all
          select
            ID,
            GCID,
            CID,
            InstrumentID,
            RecurringDepositID,
            Amount,
            CurrencyID,
            PlanStatusID,
            DepositPlanStatusID,
            StatusReasonID,
            CreationDate,
            EndDate,
            DepositStartDate,
            FrequencyID,
            RepeatsOn,
            FundingID,
            Trace,
            ValidFrom,
            ValidTo,
            PlanType,
            CopyParentCID,
            CopyParentGCID,
            CopyType,
            HasBackupPayment,
            AmountUsd
          from
            main.general.bronze_recurringinvestment_recurringinvestment_plans
        ) ip
          on ip.ID = ipi.PlanID
        left join main.bi_db.bronze_recurringinvestment_dictionary_planstatus ps
          on ip.PlanStatusID = ps.ID
        left join main.experience.bronze_recurringinvestment_dictionary_plantype pt
          on ip.PlanType = pt.ID
        left join main.experience.bronze_recurringinvestment_dictionary_copytype ct
          on ip.CopyType = ct.ID
        left join main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid isi
          on ipi.InstanceStatusID = isi.ID
        left join main.bi_db.bronze_recurringinvestment_dictionary_planeventcode pec
          on ipi.InstanceStatusReasonID = pec.ID
        left join main.experience.bronze_recurringinvestment_dictionary_positionstatus ps2
          on ipi.positionStatus = ps2.ID
    where
      ip.ValidFrom <= last_day(ipi.NextOrderDate)
      and ip.ValidTo >= last_day(ipi.NextOrderDate)
  ) q1
