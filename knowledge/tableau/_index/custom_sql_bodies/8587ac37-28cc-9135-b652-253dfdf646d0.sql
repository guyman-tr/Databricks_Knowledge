WITH account_regulation AS (
  -- Deduplicated: one regulation per account to prevent fan-out
  SELECT am.AccountNumber, 
    COALESCE(r.Name, 'Unknown') AS Regulation
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  LEFT JOIN main.general.bronze_usabroker_apex_options op ON am.AccountNumber = op.OptionsApexID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.GCID = op.GCID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r ON r.ID = dc.RegulationID
  QUALIFY ROW_NUMBER() OVER (PARTITION BY am.AccountNumber ORDER BY r.Name) = 1
),

trading_dep AS (
  SELECT 
    TO_DATE(CAST(fca.DateID AS STRING), 'yyyyMMdd') AS ReportDate, 
    r.Name AS Regulation,
    COUNT(DISTINCT CASE WHEN fbd.IsFTD = 1 THEN fca.RealCID END) AS TradingFTDA_CIDCount,
    COUNT(DISTINCT CASE WHEN fbd.IsFTD = 0 THEN fca.RealCID END) AS TradingRedeposits_CIDCount,
    COUNT(DISTINCT fca.RealCID) AS TradingTotalDeposits_CIDCount,
    COUNT(DISTINCT CASE WHEN fbd.IsFTD = 1 THEN fca.DepositID END) AS TradingFTDACount,
    COUNT(DISTINCT CASE WHEN fbd.IsFTD = 0 THEN fca.DepositID END) AS TradingRedepositsCount,
    COUNT(DISTINCT fca.DepositID) AS TradingTotalDepositsCount,
    SUM(CASE WHEN fbd.IsFTD = 1 THEN fca.Amount END) AS TradingFTDASum,
    SUM(CASE WHEN fbd.IsFTD = 0 THEN fca.Amount END) AS TradingRedepositsSum,
    SUM(fca.Amount) AS TradingTotalDepositsSum
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
    ON fca.RealCID = dc1.RealCID 
    AND dc1.IsValidCustomer = 1
    AND dc1.RegulationID IN (14) 
    AND dc1.DesignatedRegulationID IN (14)
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc 
    ON dc1.CountryID = dc.CountryID 
    AND dc.MarketingRegionManualName = 'USA'
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft 
    ON fca.FundingTypeID = dft.FundingTypeID
    AND dft.FundingTypeID != 42
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd 
    ON fca.DepositID = fbd.DepositID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r 
    ON r.ID = dc1.RegulationID
  WHERE fca.ActionTypeID = 7
    AND TO_DATE(CAST(fca.DateID AS STRING), 'yyyyMMdd') >= CURRENT_DATE() - INTERVAL 10 WEEKS
  GROUP BY TO_DATE(CAST(fca.DateID AS STRING), 'yyyyMMdd'), r.Name 
),

-- Options daily deposits (deduplicated via account_regulation CTE)
daily_dep AS (
  SELECT 
    c.ProcessDate, 
    COALESCE(ar.Regulation, 'Unknown') AS Regulation,
    COUNT(DISTINCT c.AccountNumber) AS daily_ops_depositors_ct,
    SUM(ABS(c.Amount)) AS daily_ops_total_deposits_sum, 
    COUNT(DISTINCT c.ACATSControlNumber) AS daily_ops_total_deposits_ct
  FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity c
  LEFT JOIN account_regulation ar ON c.AccountNumber = ar.AccountNumber
  WHERE c.PayTypeCode = 'C' 
    AND c.EnteredBy IN ('ACH', 'WRD')
    AND c.OfficeCode IN ('4GS', '5GU') 
    AND c.RegisteredRepCode IN ('GAT', 'FO1')
    AND c.ProcessDate >= CURRENT_DATE() - INTERVAL 10 WEEKS
  GROUP BY c.ProcessDate, COALESCE(ar.Regulation, 'Unknown')
),

-- Deposit history per account/day (deduplicated)
dep_his AS (
  SELECT 
    ca.AccountNumber, 
    ca.ProcessDate, 
    COALESCE(ar.Regulation, 'Unknown') AS Regulation,
    COUNT(DISTINCT ca.ACATSControlNumber) AS FirstDayDepositsCt, 
    SUM(ABS(ca.Amount)) AS FirstDayDepositsTotal
  FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
  LEFT JOIN account_regulation ar ON ca.AccountNumber = ar.AccountNumber
  WHERE ca.OfficeCode IN ('4GS', '5GU') 
    AND ca.RegisteredRepCode IN ('GAT', 'FO1') 
    AND ca.PayTypeCode = 'C' 
    AND ca.EnteredBy IN ('ACH', 'WRD')
  GROUP BY ca.AccountNumber, ca.ProcessDate, COALESCE(ar.Regulation, 'Unknown')
),

-- Options first deposit date per account (deduplicated)
op_ftd AS (
  SELECT 
    ca1.AccountNumber,  
    MIN(ca1.ProcessDate) AS options_first_deposit,
    COALESCE(ar.Regulation, 'Unknown') AS Regulation
  FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca1
  LEFT JOIN account_regulation ar ON ca1.AccountNumber = ar.AccountNumber
  WHERE ca1.OfficeCode IN ('4GS', '5GU') 
    AND ca1.RegisteredRepCode IN ('GAT', 'FO1') 
    AND ca1.EnteredBy IN ('ACH', 'WRD')
    AND ca1.AccountNumber NOT IN ('4GS43999', '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007', '4GS00103', '4GS00104', '4GS00101', '4GS00100')
    AND ca1.PayTypeCode = 'C' 
  GROUP BY ca1.AccountNumber, COALESCE(ar.Regulation, 'Unknown')
),

-- Options FTDA aggregation
ops_ftda AS (
  SELECT  
    op_ftd.options_first_deposit, 
    op_ftd.Regulation,
    COUNT(DISTINCT op_ftd.AccountNumber) AS Ops_FTDA_ct,
    SUM(CASE 
      WHEN dep_his.FirstDayDepositsCt > 1 THEN dep_his.FirstDayDepositsTotal / dep_his.FirstDayDepositsCt 
      WHEN dep_his.FirstDayDepositsCt = 1 THEN dep_his.FirstDayDepositsTotal 
    END) AS Ops_Total_FTDA_Adj,
    SUM(CASE 
      WHEN dep_his.FirstDayDepositsCt > 1 THEN dep_his.FirstDayDepositsTotal / dep_his.FirstDayDepositsCt 
      WHEN dep_his.FirstDayDepositsCt = 1 THEN dep_his.FirstDayDepositsTotal 
    END) / NULLIF(COUNT(DISTINCT op_ftd.AccountNumber), 0) AS Ops_AFTDA_Adj
  FROM dep_his
  JOIN op_ftd
    ON dep_his.AccountNumber = op_ftd.AccountNumber 
    AND dep_his.ProcessDate = op_ftd.options_first_deposit
    AND dep_his.Regulation = op_ftd.Regulation
  WHERE op_ftd.options_first_deposit >= CURRENT_DATE() - INTERVAL 10 WEEKS
  GROUP BY op_ftd.options_first_deposit, op_ftd.Regulation
),

-- Combined options metrics
op_apex AS (
  SELECT 
    daily_dep.ProcessDate,
    daily_dep.Regulation, 
    daily_dep.daily_ops_depositors_ct,
    daily_dep.daily_ops_depositors_ct - COALESCE(ops_ftda.Ops_FTDA_ct, 0) AS daily_ops_redepositors_ct,
    daily_dep.daily_ops_total_deposits_ct,
    COALESCE(ops_ftda.Ops_FTDA_ct, 0) AS daily_ops_ftda_ct,
    daily_dep.daily_ops_total_deposits_ct - COALESCE(ops_ftda.Ops_FTDA_ct, 0) AS daily_ops_redeposits_ct, 
    daily_dep.daily_ops_total_deposits_sum, 
    COALESCE(ops_ftda.Ops_Total_FTDA_Adj, 0) AS daily_ops_ftda_sum,
    daily_dep.daily_ops_total_deposits_sum - COALESCE(ops_ftda.Ops_Total_FTDA_Adj, 0) AS daily_ops_redeposits_sum
  FROM daily_dep
  LEFT JOIN ops_ftda
    ON daily_dep.ProcessDate = ops_ftda.options_first_deposit
    AND daily_dep.Regulation = ops_ftda.Regulation
)

SELECT 
  COALESCE(trading_dep.ReportDate, op_apex.ProcessDate) AS ReportDate, 
  COALESCE(trading_dep.Regulation, op_apex.Regulation) AS Regulation,
  COALESCE(trading_dep.TradingFTDASum, 0) AS TradingFTDASum, 
  COALESCE(trading_dep.TradingRedepositsSum, 0) AS TradingRedepositsSum,
  COALESCE(trading_dep.TradingFTDASum, 0) + COALESCE(trading_dep.TradingRedepositsSum, 0) AS TradingTotalDepositsSum,
  
  COALESCE(op_apex.daily_ops_ftda_sum, 0) AS OptionsFTDASum,
  COALESCE(op_apex.daily_ops_redeposits_sum, 0) AS OptionsRedepositsSum,
  COALESCE(op_apex.daily_ops_total_deposits_sum, 0) AS OptionsTotalDepositsSum, 

  COALESCE(trading_dep.TradingFTDACount, 0) AS TradingFTDACount,
  COALESCE(trading_dep.TradingRedepositsCount, 0) AS TradingRedepositsCount,
  COALESCE(trading_dep.TradingTotalDepositsCount, 0) AS TradingTotalDepositsCount,

  COALESCE(op_apex.daily_ops_ftda_ct, 0) AS OptionsFTDACount,
  COALESCE(op_apex.daily_ops_redeposits_ct, 0) AS OptionsRedepositsCount,
  COALESCE(op_apex.daily_ops_total_deposits_ct, 0) AS OptionsTotalDepositsCount,

  COALESCE(trading_dep.TradingFTDA_CIDCount, 0) AS TradingFTDA_CIDCount,
  COALESCE(trading_dep.TradingRedeposits_CIDCount, 0) AS TradingRedeposits_CIDCount,
  COALESCE(trading_dep.TradingTotalDeposits_CIDCount, 0) AS TradingTotalDeposits_CIDCount,

  COALESCE(op_apex.daily_ops_redepositors_ct, 0) AS daily_ops_redepositors_ct,
  COALESCE(op_apex.daily_ops_depositors_ct, 0) AS daily_ops_depositors_ct
FROM trading_dep
FULL OUTER JOIN op_apex
  ON trading_dep.ReportDate = op_apex.ProcessDate 
  AND trading_dep.Regulation = op_apex.Regulation
WHERE 
COALESCE(trading_dep.Regulation, op_apex.Regulation) = 'NYDFS+FINRA'
ORDER BY 1 DESC, 2