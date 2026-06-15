-- ============================================================================
-- sp_ddr_customer_daily_status — aligned to Synapse SP_DDR_Customer_Daily_Status
-- ============================================================================
-- Date: 2026-06-01
-- Companion: sp_ddr_customer_daily_status.alignment.md (gap analysis)
--
-- Changes vs current DBX body:
--   (1) Added _tmp_ddr_mimo_coerced (eMoney + TP legs)
--   (2) Added _tmp_ddr_mimo_coerced_withdraw
--   (3) Bifurcated _tmp_ddr_mimo into coerced + non-coerced aggregation arms,
--       UNION ALL into single _tmp_ddr_mimo
--   (4) Extended _tmp_ddr_at with Options trading detection (parity with
--       Function_Population_Active_Traders ActiveOptions CTE)
--   (5) Final SELECT wrapped with ROW_NUMBER() ... WHERE rn = 1 dedup
--   (6) Canonical Options-MIMO view name: v_mimo_optionsplatform
--   (7) REQ-25250 - bad $1 FTD cohort depositor demotion (Bug #2). Final
--       UPDATE block zeros IsDepositor / IsDepositorGlobal / all FTD anchor
--       columns / FirstDeposited flags for cohort RealCIDs on p_date_id.
-- ============================================================================

CREATE OR REPLACE PROCEDURE main.de_output.sp_ddr_customer_daily_status(process_date DATE)
SQL SECURITY INVOKER
LANGUAGE SQL
AS BEGIN
  DECLARE p_date_id INT;
  DECLARE p_etr_ymd STRING;
  DECLARE p_etr_ym STRING;
  DECLARE p_etr_y STRING;

  SET p_date_id = CAST(DATE_FORMAT(process_date, 'yyyyMMdd') AS INT);
  SET p_etr_ymd = DATE_FORMAT(process_date, 'yyyy-MM-dd');
  SET p_etr_ym = DATE_FORMAT(process_date, 'yyyy-MM');
  SET p_etr_y = DATE_FORMAT(process_date, 'yyyy');

  -- ==========================================================================
  -- Population assembly (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_pop AS
  SELECT DISTINCT cb.CID AS RealCID, dc.FirstDepositDate,
         CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS FirstDepositDateID,
         dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new cb
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON cb.CID = dc.RealCID
  WHERE cb.etr_ymd = p_etr_ymd AND cb.DateID = p_date_id;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT sub.RealCID, sub.TxStatusModificationTime,
         CAST(DATE_FORMAT(CAST(sub.TxStatusModificationTime AS DATE), 'yyyyMMdd') AS INT),
         sub.USDAmountApprox, sub.FTDPlatformID
  FROM (SELECT mfts.CID AS RealCID, mfts.TxStatusModificationTime, mfts.USDAmountApprox,
               ROW_NUMBER() OVER (PARTITION BY mfts.CID ORDER BY mfts.TxStatusModificationTime) AS RN,
               dc.FTDPlatformID
        FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON mfts.CID = dc.RealCID
        WHERE mfts.TxStatusID = 2 AND mfts.TxTypeID IN (7,14) AND mfts.TxStatusModificationDateID <= p_date_id) sub
  LEFT JOIN main.de_output._tmp_ddr_pop p ON sub.RealCID = p.RealCID
  WHERE sub.RN = 1 AND p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT dc.RealCID, dc.FirstDepositDate,
         CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT),
         dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  LEFT JOIN main.de_output._tmp_ddr_pop p ON dc.RealCID = p.RealCID
  WHERE dc.FTDPlatformID = 2 AND p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT DISTINCT mop.RealCID, dc.FirstDepositDate,
         CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT),
         dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_optionsplatform mop
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON mop.RealCID = dc.RealCID
  LEFT JOIN main.de_output._tmp_ddr_pop p ON mop.RealCID = p.RealCID
  WHERE p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT dc.RealCID, dc.FirstDepositDate,
         CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT),
         dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  LEFT JOIN main.de_output._tmp_ddr_pop p ON dc.RealCID = p.RealCID
  WHERE dc.FTDPlatformID = 4 AND p.RealCID IS NULL;

  -- ==========================================================================
  -- Basic statuses (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_basic AS
  SELECT p.RealCID, p.FirstDepositDate, p.FirstDepositDateID, p.FirstDepositAmount,
      fsc.RegulationID, fsc.DesignatedRegulationID, fsc.PlayerStatusID, fsc.IsCreditReportValidCB,
      fsc.IsValidCustomer, fsc.AccountTypeID, fsc.CountryID, fsc.MifidCategorizationID, fsc.PlayerLevelID, fsc.IsDepositor,
      CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0 END AS IsFunded,
      CASE WHEN tf.FirstFundedDateID = p_date_id THEN 1 ELSE 0 END AS FirstTimeFunded,
      tf.FirstFundedDateID,
      CASE WHEN fa.FirstTradeDateID > p_date_id OR fa.FirstTradeDateID IS NULL THEN 'NoAction' ELSE fa.FirstActionType END AS FirstActionType,
      fa.FirstTradeDateID AS FirstActionDateID, tf.FirstIOBDateID, tf.FirstIOBTime
  FROM main.de_output._tmp_ddr_pop p
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      ON p.RealCID = fsc.RealCID AND p_date_id BETWEEN fsc.FromDateID AND fsc.ToDateID
  LEFT JOIN main.etoro_kpi_prep.v_population_funded f ON p.RealCID = f.RealCID AND f.DateID = p_date_id
  LEFT JOIN main.etoro_kpi_prep.v_population_first_time_funded tf ON p.RealCID = tf.RealCID
  LEFT JOIN (SELECT RealCID, FirstTradeDateID, FirstActionType FROM main.etoro_kpi_prep.v_population_first_trading_action WHERE IsDepositor) fa ON p.RealCID = fa.RealCID;

  -- ==========================================================================
  -- ALIGNED (gap 4): Active Traders — now includes Options trading detection
  -- via v_revenue_optionsplatform ActionTypeID = 1 (mirrors Synapse
  -- Function_Population_Active_Traders ActiveOptions CTE).
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_at AS
  WITH actions_prep AS (
    SELECT fca.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON fca.RealCID = fsc.RealCID AND p_date_id BETWEEN fsc.FromDateID AND fsc.ToDateID
    WHERE fca.etr_ymd = p_etr_ymd
      AND fca.ActionTypeID IN (1, 39, 15, 17)
      AND IFNULL(fca.IsAirDrop, 0) = 0
      AND fsc.IsValidCustomer = 1
  ),
  active_options AS (
    SELECT frop.RealCID
    FROM main.etoro_kpi_prep.v_revenue_optionsplatform frop
    WHERE frop.DateID = p_date_id
      AND frop.ActionTypeID = 1
  ),
  unioned AS (
    SELECT RealCID FROM actions_prep
    UNION
    SELECT RealCID FROM active_options
  )
  SELECT RealCID, 1 AS ActiveTraded FROM unioned GROUP BY RealCID;

  -- ==========================================================================
  -- Portfolio Only (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_po AS
  WITH position_holders AS (
    SELECT DISTINCT dp.CID AS RealCID
    FROM main.dwh.dim_position dp
    WHERE dp.OpenDateID <= p_date_id
      AND (dp.CloseDateID >= p_date_id OR dp.CloseDateID = 0)
      AND COALESCE(dp.IsAirDrop, 0) = 0
  ),
  options_aum AS (
    SELECT DISTINCT dc.RealCID
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
    INNER JOIN main.general.bronze_usabroker_apex_options op ON bps.AccountNumber = op.OptionsApexID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON op.GCID = dc.GCID
    WHERE bps.OfficeCode IN ('4GS', '5GU')
      AND bps.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
      AND CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT) = p_date_id
    GROUP BY dc.RealCID
    HAVING MAX(bps.PositionMarketValue) > 0
  ),
  all_holders AS (
    SELECT RealCID FROM position_holders
    UNION
    SELECT RealCID FROM options_aum
  )
  SELECT ah.RealCID, 1 AS Portfolio_Only
  FROM all_holders ah
  WHERE ah.RealCID NOT IN (SELECT RealCID FROM main.de_output._tmp_ddr_at);

  -- ==========================================================================
  -- Balance Only (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_bo AS
  WITH tp_equity AS (
    SELECT cb.CID AS RealCID
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new cb
    WHERE cb.etr_ymd = p_etr_ymd AND cb.DateID = p_date_id
    GROUP BY cb.CID
    HAVING SUM(COALESCE(cb.TotalLiability, 0) + COALESCE(cb.actualNWA, 0)) > 0
  ),
  iban_equity AS (
    SELECT mcb.CID AS RealCID
    FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance mcb
    WHERE mcb.etr_ymd = p_etr_ymd AND mcb.BalanceDateID = p_date_id AND mcb.ClosingBalanceCalc > 0
    GROUP BY mcb.CID
    HAVING SUM(COALESCE(mcb.ClosingBalanceBO, 0) * COALESCE(mcb.USDApproxRate, 0)) > 0
  ),
  options_equity AS (
    SELECT dc.RealCID
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
    INNER JOIN main.general.bronze_usabroker_apex_options op ON bps.AccountNumber = op.OptionsApexID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON op.GCID = dc.GCID
    WHERE bps.OfficeCode IN ('4GS', '5GU')
      AND bps.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
      AND CAST(DATE_FORMAT(CAST(bps.ProcessDate AS TIMESTAMP), 'yyyyMMdd') AS INT) = p_date_id
    GROUP BY dc.RealCID
    HAVING MAX(bps.TotalEquity) > 0
  ),
  all_equity AS (
    SELECT RealCID FROM tp_equity
    UNION
    SELECT RealCID FROM iban_equity
    UNION
    SELECT RealCID FROM options_equity
  )
  SELECT ae.RealCID
  FROM all_equity ae
  WHERE ae.RealCID NOT IN (SELECT RealCID FROM main.de_output._tmp_ddr_at)
    AND ae.RealCID NOT IN (SELECT RealCID FROM main.de_output._tmp_ddr_po);

  -- ==========================================================================
  -- Segments (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_segments AS
  SELECT bs.RealCID, IFNULL(at.ActiveTraded, 0) AS ActiveTraded,
         CASE WHEN bo.RealCID IS NOT NULL THEN 1 ELSE 0 END AS BalanceOnlyAccount,
         IFNULL(po.Portfolio_Only, 0) AS Portfolio_Only
  FROM main.de_output._tmp_ddr_basic bs
  LEFT JOIN main.de_output._tmp_ddr_at at ON bs.RealCID = at.RealCID
  LEFT JOIN main.de_output._tmp_ddr_bo bo ON bs.RealCID = bo.RealCID
  LEFT JOIN main.de_output._tmp_ddr_po po ON bs.RealCID = po.RealCID;

  -- ==========================================================================
  -- ALIGNED (gap 1/2): #mimo_coerced — date-coerce late-arriving FTDs
  -- eMoney leg: TxStatusModificationDate ≠ DimCustomer.FirstDepositDate
  --             AND DimCustomer.FirstDepositDate >= '2025-09-01'
  -- TP leg:     MIMO row date ≠ DimCustomer.FirstDepositDate
  --             AND DimCustomer.FTDRecoveryDate IS NOT NULL
  --             AND DimCustomer.FirstDepositDate >= '2025-09-01'
  -- Output row reflects DimCustomer's canonical date (the "true" FTD day).
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo_coerced AS
  WITH iban_tid AS (
    SELECT mfts.CID AS RealCID, mfts.TransactionID, mfts.SourceCugTransactionID,
           mfts.TxStatusModificationTime
    FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
    WHERE mfts.TxStatusID = 2 AND mfts.TxTypeID IN (7,14)
  )
  -- eMoney leg
  SELECT
      CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS DateID,
      CAST(dc.FirstDepositDate AS DATE) AS Date,
      ap.RealCID, ap.MIMOAction, ap.TransactionID, ap.FundingTypeID,
      ap.AmountUSD, ap.IsInternalTransfer, ap.IsRedeem, ap.IsTradeFromIBAN, ap.MIMOPlatform,
      1 AS IsPlatformFTD, 1 AS IsGlobalFTD,
      dc.FTDPlatformID, dc.FirstDepositAmount AS GlobalFTA
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ap
  JOIN iban_tid ac ON ap.TransactionID = ac.TransactionID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
      ON ac.SourceCugTransactionID = dc.FTDTransactionID AND dc.FTDPlatformID = 3
  WHERE ap.MIMOPlatform = 'eMoney' AND ap.MIMOAction = 'Deposit'
    AND CAST(ac.TxStatusModificationTime AS DATE) <> CAST(dc.FirstDepositDate AS DATE)
    AND dc.FirstDepositDate >= '2025-09-01'
  UNION ALL
  -- TP leg
  SELECT
      CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS DateID,
      CAST(dc.FirstDepositDate AS DATE) AS Date,
      ap.RealCID, ap.MIMOAction, ap.TransactionID, ap.FundingTypeID,
      ap.AmountUSD, ap.IsInternalTransfer, ap.IsRedeem, ap.IsTradeFromIBAN, ap.MIMOPlatform,
      1 AS IsPlatformFTD, 1 AS IsGlobalFTD,
      dc.FTDPlatformID, dc.FirstDepositAmount AS GlobalFTA
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ap
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
      ON ap.TransactionID = dc.FTDTransactionID AND dc.FTDPlatformID = 1
  WHERE ap.MIMOPlatform = 'TradingPlatform' AND ap.MIMOAction = 'Deposit'
    AND CAST(ap.Date AS DATE) <> CAST(dc.FirstDepositDate AS DATE)
    AND dc.FTDRecoveryDate IS NOT NULL
    AND dc.FirstDepositDate >= '2025-09-01';

  -- ==========================================================================
  -- ALIGNED (gap 3): #mimo_coerced_withdraw — withdraws for coerced CIDs
  -- consumed by GlobalCashedOut / Redeemed flags in the coerced agg arm.
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo_coerced_withdraw AS
  SELECT ap.RealCID,
         MAX(CASE WHEN ap.IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS GlobalCashedOut,
         MAX(CASE WHEN ap.IsRedeem = 1 THEN 1 ELSE 0 END) AS Redeemed
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ap
  WHERE ap.DateID = p_date_id
    AND ap.MIMOAction = 'Withdraw'
    AND ap.RealCID IN (SELECT RealCID FROM main.de_output._tmp_ddr_mimo_coerced)
  GROUP BY ap.RealCID;

  -- ==========================================================================
  -- ALIGNED (gap 1/2/3): bifurcated MIMO aggregation.
  --   _tmp_ddr_mimo_non_coerced: standard daily aggregation, excludes coerced CIDs
  --   _tmp_ddr_mimo_coerced_agg: aggregation from coerced rows (canonical day)
  -- Combined via UNION ALL into _tmp_ddr_mimo.
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo_non_coerced AS
  SELECT RealCID,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS GlobalDeposited,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsGlobalFTD = 1 AND IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS GlobalFirstDeposited,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsGlobalFTD = 0 AND IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS GlobalRedeposited,
      MAX(CASE WHEN MIMOAction = 'Withdraw' AND IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS GlobalCashedOut,
      MAX(CASE WHEN MIMOAction = 'Withdraw' AND IsRedeem = 1 THEN 1 ELSE 0 END) AS Redeemed,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND MIMOPlatform = 'TradingPlatform' AND IsPlatformFTD = 1 THEN 1 ELSE 0 END) AS TPFirstDeposited,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND IsPlatformFTD = 0 AND MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS ReDepositedTP,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS DepositedTP,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND MIMOPlatform = 'eMoney' AND IsPlatformFTD = 1 THEN 1 ELSE 0 END) AS IBANFirstDeposited,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND IsPlatformFTD = 0 AND MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS ReDepositedIBAN,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS DepositedIBAN,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND MIMOPlatform = 'Options' AND IsPlatformFTD = 1 THEN 1 ELSE 0 END) AS OptionsFirstDeposited,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND IsPlatformFTD = 0 AND MIMOPlatform = 'Options' THEN 1 ELSE 0 END) AS ReDepositedOptions,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND IsInternalTransfer = 0 AND MIMOPlatform = 'Options' THEN 1 ELSE 0 END) AS DepositedOptions,
      MAX(CASE WHEN MIMOAction = 'Deposit' AND MIMOPlatform = 'TradingPlatform' AND IsPlatformFTD = 1 AND IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS TPExternalFirstDeposited
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  WHERE DateID = p_date_id
    AND RealCID NOT IN (SELECT RealCID FROM main.de_output._tmp_ddr_mimo_coerced)
  GROUP BY RealCID;

  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo_coerced_agg AS
  SELECT mc.RealCID,
      1 AS GlobalDeposited,
      1 AS GlobalFirstDeposited,
      0 AS GlobalRedeposited,
      IFNULL(mcw.GlobalCashedOut, 0) AS GlobalCashedOut,
      IFNULL(mcw.Redeemed, 0) AS Redeemed,
      MAX(CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS TPFirstDeposited,
      0 AS ReDepositedTP,
      MAX(CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS DepositedTP,
      MAX(CASE WHEN mc.MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS IBANFirstDeposited,
      0 AS ReDepositedIBAN,
      MAX(CASE WHEN mc.MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS DepositedIBAN,
      MAX(CASE WHEN mc.MIMOPlatform = 'Options' THEN 1 ELSE 0 END) AS OptionsFirstDeposited,
      0 AS ReDepositedOptions,
      MAX(CASE WHEN mc.MIMOPlatform = 'Options' THEN 1 ELSE 0 END) AS DepositedOptions,
      MAX(CASE WHEN mc.MIMOPlatform = 'TradingPlatform' AND mc.IsInternalTransfer = 0 THEN 1 ELSE 0 END) AS TPExternalFirstDeposited
  FROM main.de_output._tmp_ddr_mimo_coerced mc
  LEFT JOIN main.de_output._tmp_ddr_mimo_coerced_withdraw mcw ON mc.RealCID = mcw.RealCID
  WHERE mc.DateID = p_date_id
  GROUP BY mc.RealCID, mcw.GlobalCashedOut, mcw.Redeemed;

  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo AS
  SELECT * FROM main.de_output._tmp_ddr_mimo_non_coerced
  UNION ALL
  SELECT * FROM main.de_output._tmp_ddr_mimo_coerced_agg;

  -- ==========================================================================
  -- FTDs pivot (unchanged) + login (unchanged)
  -- ==========================================================================
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_ftds AS
  SELECT RealCID,
      MAX(CASE WHEN FTDPlatform = 'TradingPlatform' THEN CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) END) AS TP_FTD_DateID,
      MAX(CASE WHEN FTDPlatform = 'TradingPlatform' THEN FirstDepositDate END) AS TP_FTD_Date,
      MAX(CASE WHEN FTDPlatform = 'TradingPlatform' THEN FirstDepositAmount END) AS TP_FTDA,
      MAX(CASE WHEN FTDPlatform = 'eMoney' THEN CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) END) AS IBAN_FTD_DateID,
      MAX(CASE WHEN FTDPlatform = 'eMoney' THEN FirstDepositDate END) AS IBAN_FTD_Date,
      MAX(CASE WHEN FTDPlatform = 'eMoney' THEN FirstDepositAmount END) AS IBAN_FTDA,
      MAX(CASE WHEN FTDPlatform = 'Options' THEN CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) END) AS Options_FTD_DateID,
      MAX(CASE WHEN FTDPlatform = 'Options' THEN FirstDepositDate END) AS Options_FTD_Date,
      MAX(CASE WHEN FTDPlatform = 'Options' THEN FirstDepositAmount END) AS Options_FTDA,
      MAX(CASE WHEN FTDPlatform = 'MoneyFarm' THEN CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) END) AS MoneyFarm_FTD_DateID,
      MAX(CASE WHEN FTDPlatform = 'MoneyFarm' THEN FirstDepositDate END) AS MoneyFarm_FTD_Date,
      MAX(CASE WHEN FTDPlatform = 'MoneyFarm' THEN FirstDepositAmount END) AS MoneyFarm_FTDA
  FROM main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms
  WHERE CAST(DATE_FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) <= p_date_id GROUP BY RealCID;

  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_login AS
  SELECT fca.RealCID, 1 AS LoggedIn,
      MAX(CASE WHEN dc.FTDPlatformID = 1 AND dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS TPDepositor,
      MAX(CASE WHEN dc.FTDPlatformID = 3 AND dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS IBANDepositor,
      MAX(CASE WHEN dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS GlobalDepositor
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON fca.RealCID = dc.RealCID
  WHERE fca.etr_ymd = p_etr_ymd AND fca.ActionTypeID = 14 GROUP BY fca.RealCID;

  -- ==========================================================================
  -- Final DELETE + INSERT — ALIGNED (gap 5): ROW_NUMBER dedup wrapper
  -- ==========================================================================
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  WHERE etr_ymd = p_etr_ymd;

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  SELECT * EXCEPT (rn) FROM (
    SELECT
      CAST(process_date AS TIMESTAMP) AS Date,
      p_date_id AS DateID,
      bs.RealCID,
      ft.TP_FTD_DateID,
      CAST(ft.TP_FTD_Date AS TIMESTAMP) AS TP_FTD_Date,
      CAST(ft.TP_FTDA AS DECIMAL(16,6)) AS TP_FTDA,
      ft.IBAN_FTD_DateID,
      CAST(ft.IBAN_FTD_Date AS TIMESTAMP) AS IBAN_FTD_Date,
      CAST(ft.IBAN_FTDA AS DECIMAL(16,6)) AS IBAN_FTDA,
      CAST(CASE WHEN IFNULL(mi.TPExternalFirstDeposited, 0) = 1 THEN ft.TP_FTDA ELSE 0 END AS DECIMAL(16,6)) AS TP_External_FTDA,
      LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) AS Global_FTD_DateID,
      CAST(CASE WHEN IFNULL(ft.TP_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.TP_FTD_Date
           WHEN IFNULL(ft.IBAN_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.IBAN_FTD_Date
           WHEN IFNULL(ft.Options_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.Options_FTD_Date
           ELSE ft.MoneyFarm_FTD_Date END AS TIMESTAMP) AS Global_FTD_Date,
      CAST(CASE WHEN IFNULL(ft.TP_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.TP_FTDA
           WHEN IFNULL(ft.IBAN_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.IBAN_FTDA
           WHEN IFNULL(ft.Options_FTD_DateID, 30000101) = LEAST(IFNULL(ft.TP_FTD_DateID, 30000101), IFNULL(ft.IBAN_FTD_DateID, 30000101), IFNULL(ft.Options_FTD_DateID, 30000101), IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) THEN ft.Options_FTDA
           ELSE ft.MoneyFarm_FTDA END AS DECIMAL(16,6)) AS Global_FTDA,
      CASE WHEN bs.IsDepositor = true
            OR ft.Options_FTD_DateID  IS NOT NULL
            OR ft.MoneyFarm_FTD_DateID IS NOT NULL
           THEN 1 ELSE 0 END AS IsDepositorGlobal,
      IFNULL(mi.GlobalDeposited, 0) AS GlobalDeposited,
      IFNULL(mi.GlobalFirstDeposited, 0) AS GlobalFirstDeposited,
      IFNULL(mi.GlobalRedeposited, 0) AS GlobalRedeposited,
      IFNULL(mi.GlobalCashedOut, 0) AS GlobalCashedOut,
      IFNULL(mi.Redeemed, 0) AS Redeemed,
      IFNULL(mi.DepositedTP, 0) AS DepositedTP,
      IFNULL(mi.DepositedIBAN, 0) AS DepositedIBAN,
      IFNULL(mi.ReDepositedTP, 0) AS ReDepositedTP,
      IFNULL(mi.ReDepositedIBAN, 0) AS ReDepositedIBAN,
      IFNULL(mi.TPFirstDeposited, 0) AS TPFirstDeposited,
      IFNULL(mi.IBANFirstDeposited, 0) AS IBANFirstDeposited,
      IFNULL(mi.TPExternalFirstDeposited, 0) AS TPExternalFirstDeposited,
      IFNULL(seg.ActiveTraded, 0) AS ActiveTraded,
      IFNULL(seg.BalanceOnlyAccount, 0) AS BalanceOnlyAccount,
      CAST(IFNULL(seg.Portfolio_Only, 0) AS DECIMAL(16,6)) AS Portfolio_Only,
      CASE WHEN seg.ActiveTraded = 1 OR seg.Portfolio_Only = 1 THEN 1 ELSE 0 END AS AccountActive,
      CASE WHEN seg.ActiveTraded = 0 AND seg.BalanceOnlyAccount = 0 AND seg.Portfolio_Only = 0 THEN 1 ELSE 0 END AS AccountInActive,
      bs.RegulationID,
      bs.DesignatedRegulationID,
      bs.PlayerStatusID,
      bs.IsCreditReportValidCB,
      bs.IsValidCustomer,
      bs.AccountTypeID,
      CAST(bs.CountryID AS DECIMAL(16,6)) AS CountryID,
      dcountry.MarketingRegionManualName AS MarketingRegion,
      CAST(bs.MifidCategorizationID AS DECIMAL(16,6)) AS MifidCategorizationID,
      bs.PlayerLevelID,
      CAST(IFNULL(bs.IsDepositor, false) AS INT) AS IsDepositor,
      IFNULL(bs.IsFunded, 0) AS IsFunded,
      IFNULL(bs.FirstTimeFunded, 0) AS FirstTimeFunded,
      IFNULL(bs.FirstFundedDateID, 30000101) AS FirstFundedDateID,
      IFNULL(bs.FirstActionType, 'NoAction') AS FirstActionType,
      IFNULL(bs.FirstActionDateID, 30000101) AS FirstActionDateID,
      IFNULL(li.LoggedIn, 0) AS LoggedIn,
      IFNULL(li.TPDepositor, 0) AS LoggedInTPDepositor,
      IFNULL(li.IBANDepositor, 0) AS LoggedInIBANDepositor,
      IFNULL(li.GlobalDepositor, 0) AS LoggedInGlobalDepositor,
      CURRENT_TIMESTAMP() AS UpdateDate,
      bs.FirstIOBDateID,
      CAST(bs.FirstIOBTime AS TIMESTAMP) AS FirstIOBTime,
      ft.Options_FTD_DateID,
      CAST(ft.Options_FTD_Date AS TIMESTAMP) AS Options_FTD_Date,
      CAST(ft.Options_FTDA AS DECIMAL(19,4)) AS Options_FTDA,
      CASE WHEN ft.Options_FTD_DateID = p_date_id THEN 1 ELSE IFNULL(mi.OptionsFirstDeposited, 0) END AS OptionsFirstDeposited,
      CASE WHEN ft.Options_FTD_DateID = p_date_id THEN 1 ELSE IFNULL(mi.DepositedOptions, 0) END AS DepositedOptions,
      IFNULL(mi.ReDepositedOptions, 0) AS ReDepositedOptions,
      ft.MoneyFarm_FTD_DateID,
      CAST(ft.MoneyFarm_FTD_Date AS TIMESTAMP) AS MoneyFarm_FTD_Date,
      CAST(ft.MoneyFarm_FTDA AS DECIMAL(19,4)) AS MoneyFarm_FTDA,
      CASE WHEN ft.MoneyFarm_FTD_DateID = p_date_id THEN 1 ELSE 0 END AS MoneyFarmFirstDeposited,
      p_etr_y AS etr_y,
      p_etr_ym AS etr_ym,
      p_etr_ymd AS etr_ymd,
      ROW_NUMBER() OVER (PARTITION BY bs.RealCID ORDER BY bs.RealCID) AS rn
    FROM main.de_output._tmp_ddr_basic bs
    LEFT JOIN main.de_output._tmp_ddr_segments seg ON bs.RealCID = seg.RealCID
    LEFT JOIN main.de_output._tmp_ddr_mimo mi ON bs.RealCID = mi.RealCID
    LEFT JOIN main.de_output._tmp_ddr_ftds ft ON bs.RealCID = ft.RealCID
    LEFT JOIN main.de_output._tmp_ddr_login li ON bs.RealCID = li.RealCID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcountry ON bs.CountryID = dcountry.CountryID
  ) WHERE rn = 1;

  -- ==========================================================================
  -- REQ-25250 : bad $1 FTD cohort depositor demotion (Bug #2)
  --
  -- These RealCIDs made real $1 deposits so snapshotcustomer.IsDepositor = true,
  -- but business semantics say they are not depositors. Zero IsDepositor,
  -- IsDepositorGlobal, all FTD anchor columns and FirstDeposited flags on
  -- today's row (p_date_id). Companion to the MIMO demotion already on the
  -- Synapse side under the same REQ-25250. Reuses the deployed view
  -- main.etoro_kpi_prep.v_bad_ftd_cohort.
  -- ==========================================================================
  UPDATE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  SET
      IsDepositor              = 0,
      IsDepositorGlobal        = 0,
      IsFunded                 = 0,
      FirstTimeFunded          = 0,
      FirstFundedDateID        = NULL,
      TP_FTD_DateID            = NULL,
      TP_FTD_Date              = NULL,
      TP_FTDA                  = CAST(0 AS DECIMAL(16,6)),
      TP_External_FTDA         = CAST(0 AS DECIMAL(16,6)),
      IBAN_FTD_DateID          = NULL,
      IBAN_FTD_Date            = NULL,
      IBAN_FTDA                = CAST(0 AS DECIMAL(16,6)),
      Options_FTD_DateID       = NULL,
      Options_FTD_Date         = NULL,
      Options_FTDA             = CAST(0 AS DECIMAL(19,4)),
      MoneyFarm_FTD_DateID     = NULL,
      MoneyFarm_FTD_Date       = NULL,
      MoneyFarm_FTDA           = CAST(0 AS DECIMAL(19,4)),
      Global_FTD_DateID        = 30000101,
      Global_FTD_Date          = NULL,
      Global_FTDA              = CAST(0 AS DECIMAL(16,6)),
      GlobalFirstDeposited     = 0,
      TPFirstDeposited         = 0,
      IBANFirstDeposited       = 0,
      OptionsFirstDeposited    = 0,
      MoneyFarmFirstDeposited  = 0,
      TPExternalFirstDeposited = 0,
      LoggedInTPDepositor      = 0,
      LoggedInIBANDepositor    = 0,
      LoggedInGlobalDepositor  = 0,
      UpdateDate               = CURRENT_TIMESTAMP()
  WHERE DateID = p_date_id
    AND RealCID IN (SELECT RealCID FROM main.etoro_kpi_prep.v_bad_ftd_cohort);

  -- ==========================================================================
  -- Cleanup
  -- ==========================================================================
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_pop;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_basic;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_at;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_bo;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_po;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_segments;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo_coerced;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo_coerced_withdraw;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo_non_coerced;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo_coerced_agg;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_ftds;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_login;
END;
