python : Profile: name-of-profile  Warehouse: 208214768b0e0308
At C:\Users\guyman\AppData\Local\Temp\2\ps-script-c13fca73-027a-43f8-b19e-636ca2ef1cf2.ps1:78 char:1
+ python tools\dbx_query.py "SELECT routine_definition FROM main.inform ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Profile: name-o...08214768b0e0308:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
1 row(s)

routine_definition
BEGIN
  DECLARE v_date_id INT;
  DECLARE v_target STRING DEFAULT 'main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions';
  DECLARE v_month_start INT;
  DECLARE v_staking_src_from INT;
  DECLARE v_staking_src_to INT;
  DECLARE v_sql STRING;

  IF p_date = '' OR p_date IS NULL THEN
    SET v_date_id = CAST(DATE_FORMAT(DATEADD(DAY, -1, CURRENT_DATE()), 'yyyyMMdd') AS INT);
  ELSE
    SET v_date_id = CAST(p_date AS INT);
  END IF;

  SET v_month_start = CAST(DATE_FORMAT(DATE_TRUNC('MONTH', to_date(CAST(v_date_id AS STRING), 'yyyyMMdd')), 'yyyyMMdd') AS INT);
  SET v_staking_src_from = CAST(DATE_FORMAT(DATE_TRUNC('MONTH', DATEADD(MONTH, -1, to_date(CAST(v_date_id AS STRING), 'yyyyMMdd'))), 'yyyyMMdd') AS INT);
  SET v_staking_src_to = CAST(DATE_FORMAT(LAST_DAY(DATEADD(MONTH, -1, to_date(CAST(v_date_id AS STRING), 'yyyyMMdd'))), 'yyyyMMdd') AS INT);

  -- STEP 1: Delete/Truncate
  IF p_mode = 'FULL' THEN
    EXECUTE IMMEDIATE CONCAT('TRUNCATE TABLE ', v_target);
  ELSE
    EXECUTE IMMEDIATE CONCAT('DELETE FROM ', v_target, ' WHERE DateID = ', v_date_id);
  END IF;

  -- STEP 1: Insert main revenue (exclude Staking and Options)
  SET v_sql = CONCAT(
    'INSERT INTO ', v_target, ' ',
    '(DateID, Date, RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsSettled, IsCopy, ',
    'Metric, Amount, CountTransactions, IncludedInTotalRevenue, CountAsActiveTrade, UpdateDate, ',
    'IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring, ',
    'IsAirDrop, IsSQF, RevenueMetricID, RevenueMetricCategoryID, IsMarginTrade, IsC2P) ',
    'SELECT v.DateID, CAST(to_date(CAST(v.DateID AS STRING), ', CHR(39), 'yyyyMMdd', CHR(39), ') AS TIMESTAMP), ',
    'v.RealCID, v.ActionTypeID, v.ActionType, v.InstrumentTypeID, v.IsSettled, v.IsCopy, v.Metric, ',
    'CAST(v.Amount AS DECIMAL(16,6)), CAST(v.CountTransactions AS INT), v.IncludedInTotalRevenue, ',
    'CAST(v.CountAsActiveTrade AS INT), current_timestamp(), v.IsBuy, v.IsLeveraged, v.IsFuture, ',
    'v.IsCopyFund, v.IsOpenedFromIBAN, v.IsClosedToIBAN, v.IsRecurring, v.IsAirDrop, v.IsSQF, ',
    'drm.RevenueMetricID, drm.RevenueMetricCategoryID, ',
    'v.IsMarginTrade, v.IsC2P ',
    'FROM main.etoro_kpi_prep.v_ddr_revenues v ',
    'LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics drm ON v.Metric = drm.Metric ',
    'WHERE v.Metric NOT IN (', CHR(39), 'StakingFee', CHR(39), ', ', CHR(39), 'Options_PFOF', CHR(39), ') ',
    'AND v.DateID ', CASE WHEN p_mode = 'FULL' THEN '> 0' ELSE CONCAT('= ', v_date_id) END
  );
  EXECUTE IMMEDIATE v_sql;

  -- STEP 2: Options - delete all + reinsert all time
  EXECUTE IMMEDIATE CONCAT('DELETE FROM ', v_target, ' WHERE RevenueMetricID = 18');
  
  SET v_sql = CONCAT(
    'INSERT INTO ', v_target, ' ',
    '(DateID, Date, RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsSettled, IsCopy, ',
    'Metric, Amount, CountTransactions, IncludedInTotalRevenue, CountAsActiveTrade, UpdateDate, ',
    'IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring, ',
    'IsAirDrop, IsSQF, RevenueMetricID, RevenueMetricCategoryID, IsMarginTrade, IsC2P) ',
    'SELECT o.DateID, CAST(to_date(CAST(o.DateID AS STRING), ', CHR(39), 'yyyyMMdd', CHR(39), ') AS TIMESTAMP), ',
    'o.RealCID, o.ActionTypeID, o.ActionType, o.InstrumentTypeID, o.IsSettled, o.IsCopy, ',
    'o.Metric, CAST(o.Amount AS DECIMAL(16,6)), ',
    'CAST(o.CountTransactions AS INT), o.IncludedInTotalRevenue, ',
    'CAST(o.CountAsActiveTrade AS INT), current_timestamp(), ',
    'o.IsBuy, o.IsLeveraged, o.IsFuture, ',
    'o.IsCopyFund, o.IsOpenedFromIBAN, o.IsClosedToIBAN, ',
    'o.IsRecurring, o.IsAirDrop, 0, 18, 5, 0, NULL ',
    'FROM main.etoro_kpi_prep.v_revenue_optionsplatform o'
  );
  EXECUTE IMMEDIATE v_sql;

  -- STEP 3: Staking - delete current month + insert prev month shifted +1
  -- Uses TotalUSDDistributed (total pool, matching Synapse)
  IF p_mode = 'FULL' THEN
    EXECUTE IMMEDIATE CONCAT('DELETE FROM ', v_target, ' WHERE RevenueMetricID = 12');
  ELSE
    EXECUTE IMMEDIATE CONCAT('DELETE FROM ', v_target, ' WHERE RevenueMetricID = 12 AND DateID BETWEEN ', v_month_start, ' AND ', v_date_id);
  END IF;

  SET v_sql = CONCAT(
    'INSERT INTO ', v_target, ' ',
    '(DateID, Date, RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsSettled, IsCopy, ',
    'Metric, Amount, CountTransactions, IncludedInTotalRevenue, CountAsActiveTrade, UpdateDate, ',
    'IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring, ',
    'IsAirDrop, IsSQF, RevenueMetricID, RevenueMetricCategoryID, IsMarginTrade, IsC2P) ',
    'SELECT CAST(DATE_FORMAT(DATEADD(MONTH,1,to_date(CAST(s.DateID AS STRING),', CHR(39), 'yyyyMMdd', CHR(39), ')),', CHR(39), 'yyyyMMdd', CHR(39), ') AS INT), ',
    'CAST(DATEADD(MONTH,1,to_date(CAST(s.DateID AS STRING),', CHR(39), 'yyyyMMdd', CHR(39), ')) AS TIMESTAMP), ',
    'CAST(s.CID AS INT), NULL, ', CHR(39), 'Staking', CHR(39), ', 10, 1, NULL, ', CHR(39), 'StakingLagOneMonth', CHR(39), ', ',
    'CAST(SUM(s.TotalUSDDistributed) AS DECIMAL(16,6)), 0, 1, 0, current_timestamp(), ',
    '1, 0, 0, 0, NULL, NULL, NULL, NULL, NULL, 12, 4, NULL, NULL ',
    'FROM main.etoro_kpi_prep.v_revenue_stakingfee s ',
    'WHERE s.DateID ', CASE WHEN p_mode = 'FULL' THEN '> 0' ELSE CONCAT('BETWEEN ', v_staking_src_from, ' AND ', v_staking_src_to) END, ' ',
    'GROUP BY s.CID, s.DateID'
  );
  EXECUTE IMMEDIATE v_sql;

END
