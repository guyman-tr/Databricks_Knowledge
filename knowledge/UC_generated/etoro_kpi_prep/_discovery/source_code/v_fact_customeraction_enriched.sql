-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_fact_customeraction_enriched
-- Captured: 2026-05-18T08:05:28Z
-- ==========================================================================

WITH passive_actions_enriched AS (
  SELECT
    fca.HistoryID, fca.GCID, fca.RealCID, fca.DemoCID, fca.Occurred, fca.IPNumber, fca.IsReal,
    fca.ActionTypeID, fca.PlatformTypeID,
    COALESCE(dp.InstrumentID, fca.InstrumentID) AS InstrumentID,
    fca.Amount,
    COALESCE(dp.Leverage, fca.Leverage) AS Leverage,
    fca.NetProfit, fca.Commission,
    CASE
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118)
      THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, CHARINDEX(' ', REVERSE(fca.Description)) - 1)) AS BIGINT)
      ELSE fca.PositionID
    END AS PositionID,
    fca.CampaignID, fca.BonusTypeID, fca.FundingTypeID, fca.LoginID,
    CASE WHEN fca.Occurred > dm.Occurred THEN 0 ELSE COALESCE(dp.MirrorID, fca.MirrorID) END AS MirrorID,
    fca.WithdrawID, fca.DurationInSeconds, fca.PostID, fca.CaseID, fca.UpdateDate, fca.DateID, fca.TimeID, fca.StatusID,
    fca.PreviousOccurred, fca.CompensationReasonID, fca.WithdrawPaymentID, fca.CommissionOnClose, fca.IsPlug,
    fca.DepositID, fca.PostRootID, fca.FullCommission, fca.FullCommissionOnClose, fca.RedeemID, fca.RedeemStatus,
    fca.SessionID, fca.IsRedeem, fca.RegulationIDOnOpen, fca.PlatformID, fca.ReopenForPositionID, fca.IsReOpen,
    fca.CommissionOnCloseOrig, fca.FullCommissionOnCloseOrig, fca.OriginalPositionID, fca.IsPartialCloseParent,
    fca.IsPartialCloseChild, fca.InitialUnits, fca.PaymentStatusID, fca.IsDiscounted,
    COALESCE(dp.IsSettled, fca.IsSettled) AS IsSettled,
    fca.CommissionByUnits, fca.FullCommissionByUnits, fca.IsFTD, fca.CountryIDByIP, fca.IsAnonymousIP, fca.ProxyType,
    fca.IsFeeDividend,
    COALESCE(dp.IsAirDrop, fca.IsAirDrop) AS IsAirDrop,
    fca.DividendID, fca.MoveMoneyReasonID,
    COALESCE(dp.SettlementTypeID, fca.SettlementTypeID) AS SettlementTypeID,
    fca.etr_y, fca.etr_ym, fca.etr_ymd, fca.DLTOpen, fca.DLTClose, fca.OpenMarkupByUnits, fca.Description,
    COALESCE(dp.IsBuy, fca.IsBuy) AS IsBuy,
    fca.CreditID,
    -- Replicated Date IDs
    CAST(dp.OpenDateID AS INT) AS OpenDateID,
    CAST(dp.CloseDateID AS INT) AS CloseDateID,
    -- Volume set to NULL for Passive Actions to prevent aggregation duplication
    CAST(NULL AS DECIMAL(38,6)) AS VolumeOnOpen,
    CAST(NULL AS DECIMAL(38,6)) AS VolumeOnClose,
    CASE
      WHEN fca.Description = 'OpenTotalFees' THEN 'Open'
      WHEN fca.Description = 'CloseTotalFees' THEN 'Close'
      ELSE NULL
    END AS TicketFeeAction
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.dim_position dp 
    ON CASE
         WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118)
         THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, CHARINDEX(' ', REVERSE(fca.Description)) - 1)) AS BIGINT)
         ELSE fca.PositionID
       END = dp.PositionID
  LEFT JOIN (
    SELECT PositionID, MAX(Occurred) as Occurred
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    WHERE ActionTypeID = 19
    GROUP BY PositionID
  ) dm ON fca.PositionID = dm.PositionID
  WHERE (fca.ActionTypeID = 35 OR (fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (56, 117, 118)) OR fca.ActionTypeID = 32 OR fca.ActionTypeID = 19)
),
-- ACTIVE ACTIONS: Enriched with Date IDs and Volume
active_actions AS (
  SELECT
    fca.HistoryID, fca.GCID, fca.RealCID, fca.DemoCID, fca.Occurred, fca.IPNumber, fca.IsReal,
    fca.ActionTypeID, fca.PlatformTypeID, fca.InstrumentID, fca.Amount, fca.Leverage, fca.NetProfit,
    fca.Commission, fca.PositionID, fca.CampaignID, fca.BonusTypeID, fca.FundingTypeID, fca.LoginID,
    fca.MirrorID, fca.WithdrawID, fca.DurationInSeconds, fca.PostID, fca.CaseID, fca.UpdateDate,
    fca.DateID, fca.TimeID, fca.StatusID, fca.PreviousOccurred, fca.CompensationReasonID, fca.WithdrawPaymentID,
    fca.CommissionOnClose, fca.IsPlug, fca.DepositID, fca.PostRootID, fca.FullCommission, fca.FullCommissionOnClose,
    fca.RedeemID, fca.RedeemStatus, fca.SessionID, fca.IsRedeem, fca.RegulationIDOnOpen, fca.PlatformID,
    fca.ReopenForPositionID, fca.IsReOpen, fca.CommissionOnCloseOrig, fca.FullCommissionOnCloseOrig,
    fca.OriginalPositionID, fca.IsPartialCloseParent, fca.IsPartialCloseChild, fca.InitialUnits,
    fca.PaymentStatusID, fca.IsDiscounted, fca.IsSettled, fca.CommissionByUnits, fca.FullCommissionByUnits,
    fca.IsFTD, fca.CountryIDByIP, fca.IsAnonymousIP, fca.ProxyType, fca.IsFeeDividend, fca.IsAirDrop,
    fca.DividendID, fca.MoveMoneyReasonID, fca.SettlementTypeID, fca.etr_y, fca.etr_ym, fca.etr_ymd,
    fca.DLTOpen, fca.DLTClose, fca.OpenMarkupByUnits, fca.Description, fca.IsBuy, fca.CreditID,
    -- Replicated Date IDs
    CAST(dp.OpenDateID AS INT) AS OpenDateID,
    CAST(dp.CloseDateID AS INT) AS CloseDateID,
    -- VolumeOnOpen: use ORIGINAL volume (not pro-rated post partial close)
    CAST(ROUND(dp.InitialUnits * dp.InitForexRate * dp.InitConversionRate) AS DECIMAL(38,6)) AS VolumeOnOpen,
    CAST(dp.VolumeOnClose AS DECIMAL(38,6)) AS VolumeOnClose,
    NULL AS TicketFeeAction
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.dim_position dp ON fca.PositionID = dp.PositionID
  WHERE NOT (fca.ActionTypeID = 35 OR (fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (56, 117, 118)) OR fca.ActionTypeID = 32 OR fca.ActionTypeID = 19)
)
SELECT * FROM passive_actions_enriched
UNION ALL
SELECT * FROM active_actions
