CREATE OR REPLACE FUNCTION main.etoro_kpi_prep.tvf_pnl_single_day(target_date DATE)
RETURNS TABLE (
    DateID INT COMMENT '@dateID. Source: . (T2 — Function_PnL_Single_Day)',
    CID INT COMMENT 'Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    PositionID BIGINT COMMENT 'Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    UnrealizedPnLStart DECIMAL(26,4) COMMENT 'SUM(UnrealizedPnLStart). Source: . (T2 — Function_PnL_Single_Day)',
    UnrealizedPnLEnd DECIMAL(26,4) COMMENT 'SUM(UnrealizedPnLEnd). Source: . (T2 — Function_PnL_Single_Day)',
    UnrealizedPnLChange DECIMAL(28,4) COMMENT 'SUM(UnrealizedPnLChange). Source: . (T2 — Function_PnL_Single_Day)',
    NetProfit DECIMAL(29,4) COMMENT 'SUM(NetProfit). Source: . (T2 — Function_PnL_Single_Day)',
    InstrumentID INT COMMENT 'FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    MirrorID INT COMMENT 'FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    Leverage INT COMMENT 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    IsBuy BOOLEAN COMMENT '1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    IsSettled INT COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    HedgeServerID INT COMMENT 'FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    SettlementTypeID INT COMMENT 'Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) (via Dim_Position). Source: . (T1 — Function_PnL_Single_Day)',
    ClosedOnDate INT COMMENT 'ISNULL(dp.ClosedOnDate, 0) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: 1 when (dp.CloseDateID = @dateID) OR 0 (fallback); where dp = DWH_dbo.Dim_Position. Source: . (T1 — Function_PnL_Single_Day)',
    IsFuture INT COMMENT '1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) (via Dim_Instrument). Source: . (T1 — Function_PnL_Single_Day)',
    IsCopyFund INT COMMENT 'CASE WHEN NOT cpt.PositionID IS NULL THEN 1 ELSE 0 END (sql-derived [case] from Function_PnL_Single_Day); where cpt = BI_DB_dbo.BI_DB_CopyFund_Positions. Source: . (T1 — Function_PnL_Single_Day)',
    IsMarginTrade INT COMMENT 'COALESCE(dp.IsMarginTrade, upl.IsMarginTrade) (sql-derived [coalesce, DIVERGENT] from Function_PnL_Single_Day); branches: CASE WHEN dp.SettlementTypeID = 5 THEN 1 ELSE 0 END OR CASE WHEN bdppl.SettlementTypeID = 5 THEN 1 ELSE 0 END; where dp = DWH_dbo.Dim_Position, bdppl = BI_DB_dbo.BI_DB_PositionPnL. Source: . (T1 — Function_PnL_Single_Day)',
    IsSQF INT COMMENT 'case when InstrumentID is not null then 1 else 0 end. Source: . (T2 — Function_PnL_Single_Day)'
)
LANGUAGE SQL
DETERMINISTIC
READS SQL DATA
RETURN
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