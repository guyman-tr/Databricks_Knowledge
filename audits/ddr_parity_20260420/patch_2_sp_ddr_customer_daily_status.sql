/*
================================================================================
  PATCH 2: main.de_output.sp_ddr_customer_daily_status
  Author:   Guy M
  Date:     2026-05-31

  Change:
    IsDepositorGlobal was being computed as:
        CASE WHEN LEAST(IFNULL(TP_FTD_DateID, 30000101),
                        IFNULL(IBAN_FTD_DateID, 30000101),
                        IFNULL(Options_FTD_DateID, 30000101),
                        IFNULL(MoneyFarm_FTD_DateID, 30000101)) <= p_date_id
             THEN 1 ELSE 0 END
    This pattern relied on at least one platform-FTD row from
    v_mimo_first_deposit_all_platforms. But that view has coverage gaps for
    OLD-logic depositors (FTD before 2025-09-01) - leaving 5.6M cumulative
    depositors with all four FTD_DateID columns NULL, hence Global=0.

    Net effect: IsDepositorGlobal undercounted by ~5.6M (94%) vs. Synapse,
    which sources IsDepositorGlobal essentially off Fact_SnapshotCustomer.

    Fix: spine on bs.IsDepositor (already pulled from Fact_SnapshotCustomer)
    plus an OR for Options/MoneyFarm-only depositors (the small Synapse fringe
    of ~900 customers per day).

  IMPORTANT: This SP is also re-created from a notebook in the prod ETL job.
    A matching change must be made to the notebook source so this fix
    survives the next prod recreate. See companion file
    notebook_patch_instructions.md.
================================================================================
*/

CREATE OR REPLACE PROCEDURE main.de_output.sp_ddr_customer_daily_status(process_date DATE)
LANGUAGE SQL
SQL SECURITY INVOKER
AS
BEGIN
  DECLARE p_date_id INT;
  DECLARE p_etr_ymd STRING;
  DECLARE p_etr_ym STRING;
  DECLARE p_etr_y STRING;

  SET p_date_id = CAST(DATE_FORMAT(process_date, 'yyyyMMdd') AS INT);
  SET p_etr_ymd = DATE_FORMAT(process_date, 'yyyy-MM-dd');
  SET p_etr_ym = DATE_FORMAT(process_date, 'yyyy-MM');
  SET p_etr_y = DATE_FORMAT(process_date, 'yyyy');

  -- STEP 1: POPULATION (partition-aware on etr_ymd)
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_pop AS
  SELECT DISTINCT cb.CID AS RealCID, dc.FirstDepositDate, CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS FirstDepositDateID, dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new cb
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON cb.CID = dc.RealCID
  WHERE cb.etr_ymd = p_etr_ymd AND cb.DateID = p_date_id;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT sub.RealCID, sub.TxStatusModificationTime, CAST(DATE_FORMAT(CAST(sub.TxStatusModificationTime AS DATE), 'yyyyMMdd') AS INT), sub.USDAmountApprox, sub.FTDPlatformID
  FROM (SELECT mfts.CID AS RealCID, mfts.TxStatusModificationTime, mfts.USDAmountApprox, ROW_NUMBER() OVER (PARTITION BY mfts.CID ORDER BY mfts.TxStatusModificationTime) AS RN, dc.FTDPlatformID
        FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status mfts
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON mfts.CID = dc.RealCID
        WHERE mfts.TxStatusID = 2 AND mfts.TxTypeID IN (7,14) AND mfts.TxStatusModificationDateID <= p_date_id) sub
  LEFT JOIN main.de_output._tmp_ddr_pop p ON sub.RealCID = p.RealCID
  WHERE sub.RN = 1 AND p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT dc.RealCID, dc.FirstDepositDate, CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT), dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  LEFT JOIN main.de_output._tmp_ddr_pop p ON dc.RealCID = p.RealCID
  WHERE dc.FTDPlatformID = 2 AND p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT DISTINCT mop.RealCID, dc.FirstDepositDate, CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT), dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.etoro_kpi_prep.v_mimo_options_platform mop
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON mop.RealCID = dc.RealCID
  LEFT JOIN main.de_output._tmp_ddr_pop p ON mop.RealCID = p.RealCID
  WHERE p.RealCID IS NULL;

  INSERT INTO main.de_output._tmp_ddr_pop
  SELECT dc.RealCID, dc.FirstDepositDate, CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT), dc.FirstDepositAmount, dc.FTDPlatformID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  LEFT JOIN main.de_output._tmp_ddr_pop p ON dc.RealCID = p.RealCID
  WHERE dc.FTDPlatformID = 4 AND p.RealCID IS NULL;

  -- STEP 2: BASIC STATUSES
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

  -- STEP 3: SEGMENTS
  -- 3a. Active traders
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_at AS
  SELECT fca.RealCID, 1 AS ActiveTraded
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      ON fca.RealCID = fsc.RealCID AND p_date_id BETWEEN fsc.FromDateID AND fsc.ToDateID
  WHERE fca.etr_ymd = p_etr_ymd
    AND fca.ActionTypeID IN (1, 39, 15, 17)
    AND IFNULL(fca.IsAirDrop, 0) = 0
    AND fsc.IsValidCustomer = 1
  GROUP BY fca.RealCID;

  -- 3b. Portfolio only
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

  -- 3c. Balance only
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

  -- 3d. Combine segments
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_segments AS
  SELECT bs.RealCID, IFNULL(at.ActiveTraded, 0) AS ActiveTraded, CASE WHEN bo.RealCID IS NOT NULL THEN 1 ELSE 0 END AS BalanceOnlyAccount, IFNULL(po.Portfolio_Only, 0) AS Portfolio_Only
  FROM main.de_output._tmp_ddr_basic bs
  LEFT JOIN main.de_output._tmp_ddr_at at ON bs.RealCID = at.RealCID
  LEFT JOIN main.de_output._tmp_ddr_bo bo ON bs.RealCID = bo.RealCID
  LEFT JOIN main.de_output._tmp_ddr_po po ON bs.RealCID = po.RealCID;

  -- STEP 4: MIMO
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_mimo AS
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
  FROM main.de_output.de_output_ddr_fact_mimo_allplatforms WHERE DateID = p_date_id GROUP BY RealCID;

  -- STEP 5: GLOBAL FTDs
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

  -- STEP 6: LOGGED IN (partition-aware on etr_ymd)
  CREATE OR REPLACE TABLE main.de_output._tmp_ddr_login AS
  SELECT fca.RealCID, 1 AS LoggedIn,
      MAX(CASE WHEN dc.FTDPlatformID = 1 AND dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS TPDepositor,
      MAX(CASE WHEN dc.FTDPlatformID = 3 AND dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS IBANDepositor,
      MAX(CASE WHEN dc.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END) AS GlobalDepositor
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON fca.RealCID = dc.RealCID
  WHERE fca.etr_ymd = p_etr_ymd AND fca.ActionTypeID = 14 GROUP BY fca.RealCID;

  -- STEP 7: FINAL ASSEMBLY (DELETE + INSERT incremental)
  DELETE FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  WHERE etr_ymd = p_etr_ymd;

  INSERT INTO main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
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
      -- FIX 2026-05-31: IsDepositorGlobal sourced from Fact_SnapshotCustomer.IsDepositor
      -- (the cumulative depositor flag) plus an OR for Options/MoneyFarm-only depositors
      -- whose cumulative flag may not yet reflect (rare fringe). Previous LEAST-of-4-FTDs
      -- pattern missed 5.6M depositors with no platform-FTD row in v_mimo_first_deposit_all_platforms.
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
      p_etr_ymd AS etr_ymd
  FROM main.de_output._tmp_ddr_basic bs
  LEFT JOIN main.de_output._tmp_ddr_segments seg ON bs.RealCID = seg.RealCID
  LEFT JOIN main.de_output._tmp_ddr_mimo mi ON bs.RealCID = mi.RealCID
  LEFT JOIN main.de_output._tmp_ddr_ftds ft ON bs.RealCID = ft.RealCID
  LEFT JOIN main.de_output._tmp_ddr_login li ON bs.RealCID = li.RealCID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcountry ON bs.CountryID = dcountry.CountryID;

  -- CLEANUP
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_pop;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_basic;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_at;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_bo;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_po;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_segments;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_mimo;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_ftds;
  DROP TABLE IF EXISTS main.de_output._tmp_ddr_login;
END;
