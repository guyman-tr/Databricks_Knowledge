BEGIN
  DECLARE v_date STRING;
  DECLARE v_month_start STRING;
  DECLARE v_options_floor STRING;
  DECLARE v_insert_sql STRING;
  DECLARE v_staking_n BIGINT;
  DECLARE v_options_n BIGINT;
  DECLARE q STRING;
  SET q = CHR(39);

  SET v_insert_sql =
    'SELECT ' ||
    'v.DateID, ' ||
    'CAST(v.Date AS TIMESTAMP), ' ||
    'v.RealCID, ' ||
    'v.ActionTypeID, ' ||
    'v.ActionType, ' ||
    'v.InstrumentTypeID, ' ||
    'v.IsSettled, ' ||
    'v.IsCopy, ' ||
    'v.Metric, ' ||
    'CAST(v.Amount AS DECIMAL(16,6)), ' ||
    'CAST(v.CountTransactions AS INT), ' ||
    'v.IncludedInTotalRevenue, ' ||
    'CAST(v.CountAsActiveTrade AS INT), ' ||
    'current_timestamp(), ' ||
    'v.IsBuy, ' ||
    'v.IsLeveraged, ' ||
    'v.IsFuture, ' ||
    'v.IsCopyFund, ' ||
    'v.IsOpenedFromIBAN, ' ||
    'v.IsClosedToIBAN, ' ||
    'v.IsRecurring, ' ||
    'v.IsAirDrop, ' ||
    'v.IsSQF, ' ||
    'drm.RevenueMetricID, ' ||
    'drm.RevenueMetricCategoryID, ' ||
    'v.IsMarginTrade, ' ||
    'v.IsC2P ' ||
    'FROM main.etoro_kpi_prep.v_ddr_revenues v ' ||
    'LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics drm ' ||
    'ON v.Metric = drm.Metric';

  IF p_date = 'FULL' THEN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || target_table;
    EXECUTE IMMEDIATE 'INSERT INTO ' || target_table || ' ' || v_insert_sql;
  ELSE
    IF p_date IS NULL THEN
      SET v_date = CAST(CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), 'yyyyMMdd') AS INT) AS STRING);
    ELSE
      SET v_date = p_date;
    END IF;

    SET v_month_start = CAST(CAST(DATE_FORMAT(TRUNC(TO_DATE(v_date, 'yyyyMMdd'), 'MM'), 'yyyyMMdd') AS INT) AS STRING);
    SET v_options_floor = CAST(CAST(DATE_FORMAT(DATE_SUB(TO_DATE(v_date, 'yyyyMMdd'), 90), 'yyyyMMdd') AS INT) AS STRING);

    EXECUTE IMMEDIATE 'DELETE FROM ' || target_table || ' WHERE DateID = ' || v_date;
    EXECUTE IMMEDIATE 'INSERT INTO ' || target_table || ' ' || v_insert_sql || ' WHERE v.DateID = ' || v_date;

    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM main.etoro_kpi_prep.v_ddr_revenues WHERE Metric = ' || q || 'Options_PFOF' || q || ' AND DateID >= ' || v_options_floor INTO v_options_n;
    IF v_options_n > 0 THEN
      EXECUTE IMMEDIATE 'DELETE FROM ' || target_table || ' WHERE RevenueMetricID = 18 AND DateID >= ' || v_options_floor;
      EXECUTE IMMEDIATE 'INSERT INTO ' || target_table || ' ' || v_insert_sql || ' WHERE v.Metric = ' || q || 'Options_PFOF' || q || ' AND v.DateID >= ' || v_options_floor;
    END IF;

    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM main.etoro_kpi_prep.v_ddr_revenues WHERE Metric = ' || q || 'StakingLagOneMonth' || q || ' AND DateID BETWEEN ' || v_month_start || ' AND ' || v_date INTO v_staking_n;
    IF v_staking_n > 0 THEN
      EXECUTE IMMEDIATE 'DELETE FROM ' || target_table || ' WHERE DateID BETWEEN ' || v_month_start || ' AND ' || v_date || ' AND RevenueMetricID = 12';
      EXECUTE IMMEDIATE 'INSERT INTO ' || target_table || ' ' || v_insert_sql || ' WHERE v.Metric = ' || q || 'StakingLagOneMonth' || q || ' AND v.DateID BETWEEN ' || v_month_start || ' AND ' || v_date;
    END IF;
  END IF;
END