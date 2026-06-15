WITH
  -- Derive integer DateID and previous calendar day
  params AS (
    SELECT
      CAST(DATE_FORMAT(target_date, 'yyyyMMdd') AS INT) AS date_id,
      DATE_SUB(target_date, 1) AS prev_date
  ),
  -- End-of-day PnL (target date) - reads only 1 partition
  PnLEnd AS (
    SELECT
      bdppl.DateID, bdppl.PositionID, bdppl.CID, bdppl.PositionPnL,
      bdppl.InstrumentID, bdppl.MirrorID, bdppl.Leverage, bdppl.IsBuy,
      bdppl.IsSettled, bdppl.HedgeServerID, bdppl.SettlementTypeID,
      di.IsFuture,
      CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund,
      CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl bdppl
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      ON bdppl.InstrumentID = di.InstrumentID
    LEFT JOIN main.etoro_kpi_prep.v_copyfund_positions cpt
      ON bdppl.PositionID = cpt.PositionID
    WHERE bdppl.etr_ymd = target_date
  ),
  -- Start-of-day PnL (previous day) - reads only 1 partition
  PnLStart AS (
    SELECT
      bdppl.PositionID, bdppl.CID, bdppl.PositionPnL,
      bdppl.InstrumentID, bdppl.MirrorID, bdppl.Leverage, bdppl.IsBuy,
      bdppl.IsSettled, bdppl.HedgeServerID, bdppl.SettlementTypeID,
      di.IsFuture,
      CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund,
      CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl bdppl
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      ON bdppl.InstrumentID = di.InstrumentID
    LEFT JOIN main.etoro_kpi_prep.v_copyfund_positions cpt
      ON bdppl.PositionID = cpt.PositionID
    WHERE bdppl.etr_ymd = (SELECT prev_date FROM params)
  ),
  -- Unrealized PnL: FULL OUTER JOIN start vs end
  UnrealizedPnL AS (
    SELECT
      (SELECT date_id FROM params) AS DateID,
      COALESCE(e.PositionID, s.PositionID) AS PositionID,
      COALESCE(e.CID, s.CID) AS CID,
      s.PositionPnL AS UnrealizedPnLStart,
      e.PositionPnL AS UnrealizedPnLEnd,
      CASE
        WHEN s.PositionPnL IS NULL THEN e.PositionPnL
        WHEN e.PositionPnL IS NULL THEN -1 * s.PositionPnL
        ELSE e.PositionPnL - s.PositionPnL
      END AS UnrealizedPnLChange,
      COALESCE(e.InstrumentID, s.InstrumentID) AS InstrumentID,
      COALESCE(e.MirrorID, s.MirrorID) AS MirrorID,
      COALESCE(e.Leverage, s.Leverage) AS Leverage,
      COALESCE(e.IsBuy, s.IsBuy) AS IsBuy,
      COALESCE(e.IsSettled, s.IsSettled) AS IsSettled,
      COALESCE(e.HedgeServerID, s.HedgeServerID) AS HedgeServerID,
      COALESCE(e.SettlementTypeID, s.SettlementTypeID) AS SettlementTypeID,
      0 AS ClosedOnDate,
      COALESCE(e.IsFuture, s.IsFuture) AS IsFuture,
      COALESCE(e.IsCopyFund, s.IsCopyFund) AS IsCopyFund,
      COALESCE(e.IsMarginTrade, s.IsMarginTrade) AS IsMarginTrade
    FROM PnLEnd e
    FULL OUTER JOIN PnLStart s ON e.PositionID = s.PositionID
  ),
  -- Realized PnL: positions closed on this date
  RealizedPnL AS (
    SELECT
      (SELECT date_id FROM params) AS DateID,
      dp.PositionID,
      dp.NetProfit,
      dp.InstrumentID,
      dp.CID,
      dp.MirrorID,
      dp.Leverage,
      dp.IsBuy,
      dp.IsSettled,
      dp.HedgeServerID,
      dp.SettlementTypeID,
      1 AS ClosedOnDate,
      di.IsFuture,
      CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund,
      CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade
    FROM main.dwh.dim_position dp
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
      ON dp.InstrumentID = di.InstrumentID
    LEFT JOIN main.etoro_kpi_prep.v_copyfund_positions cpt
      ON dp.PositionID = cpt.PositionID
    WHERE dp.CloseDateID = (SELECT date_id FROM params)
  ),
  -- Combine unrealized + realized
  Combined AS (
    SELECT
      COALESCE(upl.DateID, rp.DateID) AS DateID,
      COALESCE(upl.PositionID, rp.PositionID) AS PositionID,
      COALESCE(upl.CID, rp.CID) AS CID,
      COALESCE(upl.UnrealizedPnLStart, 0) AS UnrealizedPnLStart,
      COALESCE(upl.UnrealizedPnLEnd, 0) AS UnrealizedPnLEnd,
      COALESCE(upl.UnrealizedPnLChange, 0) AS UnrealizedPnLChange,
      COALESCE(rp.NetProfit, 0) AS NetProfit,
      COALESCE(upl.InstrumentID, rp.InstrumentID) AS InstrumentID,
      COALESCE(upl.MirrorID, rp.MirrorID) AS MirrorID,
      COALESCE(upl.Leverage, rp.Leverage) AS Leverage,
      COALESCE(upl.IsBuy, rp.IsBuy) AS IsBuy,
      COALESCE(upl.IsSettled, rp.IsSettled) AS IsSettled,
      COALESCE(upl.HedgeServerID, rp.HedgeServerID) AS HedgeServerID,
      COALESCE(upl.SettlementTypeID, rp.SettlementTypeID) AS SettlementTypeID,
      COALESCE(rp.ClosedOnDate, upl.ClosedOnDate, 0) AS ClosedOnDate,
      COALESCE(upl.IsFuture, rp.IsFuture) AS IsFuture,
      COALESCE(upl.IsCopyFund, rp.IsCopyFund) AS IsCopyFund,
      COALESCE(upl.IsMarginTrade, rp.IsMarginTrade) AS IsMarginTrade
    FROM UnrealizedPnL upl
    FULL OUTER JOIN RealizedPnL rp
      ON rp.PositionID = upl.PositionID
  ),
  -- Aggregate (handles edge cases)
  FINAL AS (
    SELECT
      DateID, CID, PositionID,
      SUM(UnrealizedPnLStart) AS UnrealizedPnLStart,
      SUM(UnrealizedPnLEnd) AS UnrealizedPnLEnd,
      SUM(UnrealizedPnLChange) AS UnrealizedPnLChange,
      SUM(NetProfit) AS NetProfit,
      InstrumentID, MirrorID, Leverage, IsBuy, IsSettled,
      HedgeServerID, SettlementTypeID, ClosedOnDate,
      IsFuture, IsCopyFund, IsMarginTrade
    FROM Combined
    GROUP BY DateID, CID, PositionID, InstrumentID, MirrorID, Leverage,
             IsBuy, IsSettled, HedgeServerID, SettlementTypeID, ClosedOnDate,
             IsFuture, IsCopyFund, IsMarginTrade
  )
  -- Final output with IsSQF flag
  SELECT
    f.DateID, f.CID, f.PositionID,
    f.UnrealizedPnLStart, f.UnrealizedPnLEnd, f.UnrealizedPnLChange,
    f.NetProfit, f.InstrumentID, f.MirrorID, f.Leverage, f.IsBuy,
    f.IsSettled, f.HedgeServerID, f.SettlementTypeID, f.ClosedOnDate,
    f.IsFuture, f.IsCopyFund, f.IsMarginTrade,
    CASE WHEN sqf.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS IsSQF
  FROM FINAL f
  LEFT JOIN (
    SELECT DISTINCT InstrumentID
    FROM main.trading.bronze_etoro_trade_instrumentgroups
    WHERE GroupID = 59
  ) sqf ON f.InstrumentID = sqf.InstrumentID