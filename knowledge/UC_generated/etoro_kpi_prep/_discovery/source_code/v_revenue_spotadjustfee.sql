-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_spotadjustfee
-- Captured: 2026-05-19T12:23:35Z
-- ==========================================================================

SELECT
  CAST(PositionID AS BIGINT) as PositionID,
  CAST(RealCID AS INT) as RealCID,
  fca.Occurred,
  CAST(DateID AS INT) as DateID,
  fca.etr_ymd,
  CAST(-1 * Amount AS DECIMAL(38, 6)) AS SpotAdjustFee,
  fca.IsSettled,
  fca.MirrorID,
  fca.SettlementTypeID
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
WHERE
  fca.ActionTypeID IN (36)
  AND fca.CompensationReasonID = 118
