-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_adminfee
-- Captured: 2026-05-18T08:10:53Z
-- ==========================================================================

SELECT
  CAST(fca.PositionID AS BIGINT) as PositionID,
  CAST(fca.RealCID AS INT) as RealCID,
  CAST(fca.DateID AS INT) as DateID,
  fca.Occurred,
  CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS AdminFee,
  CAST(fca.IsSettled AS INT) as IsSettled,
  CAST(fca.MirrorID AS INT) as MirrorID,
  CAST(fca.SettlementTypeID AS INT) as SettlementTypeID
FROM
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution fca
WHERE
  fca.ActionTypeID IN (36)
  AND fca.CompensationReasonID = 117
