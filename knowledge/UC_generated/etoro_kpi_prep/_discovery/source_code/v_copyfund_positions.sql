-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_copyfund_positions
-- Captured: 2026-05-19T12:08:55Z
-- ==========================================================================

WITH copyfund_mirrors AS (
  SELECT 
    MirrorID, 
    ParentCID, 
    ParentUserName, 
    MirrorTypeID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
  WHERE MirrorTypeID = 4
),
copyfund_positions AS (
  SELECT 
    dp.PositionID,
    dp.CID,
    dp.MirrorID,
    dp.OpenDateID,
    dp.CloseDateID,
    cfm.ParentCID,
    cfm.ParentUserName,
    cfm.MirrorTypeID,
    dp.IsPartialCloseChild
  FROM main.dwh.dim_position dp
  JOIN copyfund_mirrors cfm
    ON dp.MirrorID = cfm.MirrorID
  WHERE dp.MirrorID > 0
)
-- Deduplicate: in rare cases there can be duplicates, take max CloseDateID
SELECT 
  PositionID,
  CID,
  MirrorID,
  OpenDateID,
  MAX(CloseDateID) AS CloseDateID,
  ParentCID,
  ParentUserName,
  MirrorTypeID,
  IsPartialCloseChild
FROM copyfund_positions
GROUP BY 
  PositionID,
  CID,
  MirrorID,
  OpenDateID,
  ParentCID,
  ParentUserName,
  MirrorTypeID,
  IsPartialCloseChild
