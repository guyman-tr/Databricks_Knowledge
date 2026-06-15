-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.v_ddr_non_revenue_actions
-- Captured: 2026-05-19T15:17:35Z
-- ==========================================================================

WITH
financial_actions AS (
  SELECT
    fca.DateID,
    fca.RealCID,
    CASE
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (53,54) THEN 'CompensationRAFInvitedInviting'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 22 THEN 'PnLAdjustment'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 41 THEN 'CompensationPIWithCashout'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 50 THEN 'CompensationPINoCashout'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 51 THEN 'CompensationToAffiliateWithCashout'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 52 THEN 'CompensationToAffiliateNoCashout'
      WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 134 THEN 'C2P'
      WHEN fca.ActionTypeID = 36 THEN 'CompensationOther'
      WHEN fca.ActionTypeID = 9 THEN 'BonusComp'
      WHEN fca.ActionTypeID = 32 THEN 'EditStoploss'
      WHEN fca.ActionTypeID IN (1,2,3,39) THEN 'InvestmentAmountInNewTrades'
      WHEN fca.ActionTypeID IN (4,5,6,28,40) THEN 'InvestmentAmountClosedTrades'
      WHEN fca.ActionTypeID = 15 THEN 'AddToCopy'
      WHEN fca.ActionTypeID = 16 THEN 'RemoveFromCopy'
      WHEN fca.ActionTypeID = 17 THEN 'NewCopy'
      WHEN fca.ActionTypeID = 18 THEN 'StopCopy'
    END AS ActionType,
    CASE
      WHEN fca.ActionTypeID = 36 THEN fca.Amount
      WHEN fca.ActionTypeID = 9 THEN fca.Amount
      WHEN fca.ActionTypeID = 32 THEN -1 * fca.Amount
      WHEN fca.ActionTypeID IN (1,2,3,39) THEN -1 * fca.Amount
      WHEN fca.ActionTypeID IN (4,5,6,28,40) THEN fca.Amount
      WHEN fca.ActionTypeID = 15 THEN -1 * fca.Amount
      WHEN fca.ActionTypeID = 16 THEN fca.Amount
      WHEN fca.ActionTypeID = 17 THEN -1 * fca.Amount
      WHEN fca.ActionTypeID = 18 THEN fca.Amount
      ELSE 0
    END AS Amount,
    fca.IsCopyFund
  FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics fca
  WHERE fca.ActionTypeID IN (1,2,3,4,5,6,9,15,16,17,18,28,32,36,39,40)
),
non_financial_actions AS (
  SELECT
    fca.DateID,
    fca.RealCID,
    CASE
      WHEN fca.ActionTypeID = 14 AND fsc.RealCID IS NOT NULL THEN 'DepositorsLoggedIn'
      WHEN fca.ActionTypeID = 14 THEN 'LoggedIn'
      WHEN fca.ActionTypeID = 41 THEN 'Registred'
    END AS ActionType,
    CAST(0 AS DECIMAL(11,2)) AS Amount,
    0 AS IsCopyFund
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
    AND fca.DateID BETWEEN fsc.FromDateID AND fsc.ToDateID
    AND fsc.IsDepositor = 1
  WHERE fca.ActionTypeID IN (14,41)
),
all_actions AS (
  SELECT * FROM financial_actions
  UNION ALL
  SELECT * FROM non_financial_actions
)
SELECT
  DateID,
  RealCID,
  ActionType,
  SUM(Amount) AS Amount,
  COUNT(*) AS CountActions,
  IsCopyFund
FROM all_actions
WHERE ActionType IS NOT NULL
GROUP BY DateID, RealCID, ActionType, IsCopyFund
