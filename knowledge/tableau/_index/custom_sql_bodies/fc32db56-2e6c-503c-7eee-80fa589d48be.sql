with ops_accts as (
  SELECT distinct GCID, OptionsApexID
  FROM main.general.bronze_usabroker_apex_options op 
    join main.bi_db.bronze_usabroker_dictionary_optionsstatus os  
      on op.OptionsStatusID = os.OptionsStatusID
    join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am 
      on op.OptionsApexID=am.AccountNumber
        and OfficeCode in ('4GS','5GU')
          AND RegisteredRepCode IN ('GAT','FO1') -- US accounts only 
  where os.OptionsStatusID=3 --approved options account   
    and OptionsApexID NOT IN ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100') /* exclusion of house accounts */
),

ops_trade_base as (
  SELECT distinct op.GCID, tr.AccountNumber, RegisteredRepCode, TradeDate, MarketCode, OrderId, abs(NetAmount) as AmountUSD
  FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr 
  join ops_accts op 
    on op.OptionsApexID=tr.AccountNumber
  where BuySellCode='B'
    and MarketCode='5'
    and tr.etr_ymd BETWEEN DATEADD(WEEK, -10, CURRENT_DATE()) AND CURRENT_DATE()
),

msb_traders as (
  SELECT GCID, RealCID
  FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
  where RegulationID in (7,8,12,14)
    and IsValidCustomer=1
    and VerificationLevelID=3
),

msb_manual_trades as (
  SELECT distinct 
    t.GCID, 
	dp.PositionID, 
    cast(dp.OpenOccurred as date) OpenDate,
    dp.InitialAmountCents/100 as AmountUSD,
    di.InstrumentTypeID,
	dm.MirrorTypeID
  FROM dwh.dim_position dp
  LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm  
	ON dp.MirrorID=dm.MirrorID
  join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di 
    on dp.InstrumentID=di.InstrumentID
  join msb_traders t 
    on dp.CID=t.RealCID
  where 
	dm.MirrorID IS NULL 
	AND dp.RegulationIDOnOpen in  (7,8,12,14)
    and dp.etr_ymd BETWEEN DATEADD(WEEK, -10, CURRENT_DATE()) AND CURRENT_DATE()
    and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
    and coalesce(dp.IsPartialCloseChild, 0) != 1    -- filter out partial positions
),

msb_mirror_trades as (
  SELECT distinct 
    t.GCID, 
	  dm.MirrorID, 
	  dm.MirrorTypeID, 
    cast(dm.OpenOccurred as date) mirror_OpenDate,
	  dm.InitialInvestment
  FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm  
  join msb_traders t 
    on dm.CID=t.RealCID
  join dwh.dim_position dp 
    on dm.MirrorID=dp.MirrorID 
  where dp.RegulationIDOnOpen in  (7,8,12,14)
    and dp.etr_ymd BETWEEN DATEADD(WEEK, -10, CURRENT_DATE()) AND CURRENT_DATE()
    and coalesce(dp.IsAirDrop, 0) != 1              -- filter out air drops
    and coalesce(dp.IsPartialCloseChild, 0) != 1    -- filter out partial positions
),

all_trades AS (
	SELECT 
		OpenDate, GCID, InstrumentTypeID, MirrorTypeID, count(distinct PositionID) daily_new_trades, sum(AmountUSD) daily_new_volume
	FROM msb_manual_trades
  group by OpenDate, GCID, InstrumentTypeID, MirrorTypeID

	UNION ALL 

	SELECT 
		mirror_OpenDate, GCID, 0 as InstrumentTypeID, MirrorTypeID, count(distinct MirrorID) daily_new_trades, sum(InitialInvestment) daily_new_volume
	FROM msb_mirror_trades
  group by mirror_OpenDate, GCID, InstrumentTypeID, MirrorTypeID

	UNION all 

	SELECT 
		TradeDate, GCID, -1 AS InstrumentTypeID, 0 AS MirrorTypeID, count(distinct OrderId) daily_new_trades, sum(AmountUSD) daily_new_volume
	FROM ops_trade_base
  group by TradeDate, GCID, InstrumentTypeID, MirrorTypeID
)


-- Monthly aggregation directly from base tables
-- 1. NON-COPY trades


SELECT 
  cast(OpenDate as date) as OpenDate,

  CASE WHEN dc.PlayerLevelID IN (0,1) THEN 'Non-Club' ELSE 'Club' END as Club_filter,
  
  -- Total unique active traders
  COUNT(DISTINCT at.GCID) as ByClub_CID_ct_ao_traders,
  
  -- OPTIONS
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=-1 AND MirrorTypeID=0 THEN at.GCID end) AS ByClub_CID_ct_options,
  
  -- CRYPTO - Manual
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=10 AND COALESCE(MirrorTypeID,0)=0 THEN at.GCID end) AS ByClub_CID_ct_cryptoM,
  -- STOCKS - Manual
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=5 AND COALESCE(MirrorTypeID,0)=0 THEN at.GCID end) AS ByClub_CID_ct_stocksM,
  -- ETF - Manual
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=6 AND COALESCE(MirrorTypeID,0)=0 THEN at.GCID end) AS ByClub_CID_ct_ETFM,
  /*-------------------------------------------copy--------------------------------------------------------- */
    -- COPY PI (Popular Investor)
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=0 and MirrorTypeID=1 THEN at.GCID end) AS ByClub_CID_ct_copyPI,
  
  -- COPY PF (Portfolio)
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=0 and MirrorTypeID=4 THEN at.GCID end) AS ByClub_CID_ct_copyPF
 
 /* 
  -- COPY - Total
  COUNT(DISTINCT CASE WHEN InstrumentTypeID=0 THEN at.GCID end) AS ByClub_CID_ct_copy,
  sum(CASE WHEN InstrumentTypeID=0 THEN daily_new_trades END) AS daily_copy_new_trades,
  SUM(CASE WHEN InstrumentTypeID=0 THEN daily_new_volume END) AS daily_copy_new_volume
*/

FROM all_trades at 
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
  ON dc.GCID = at.GCID
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl 
  ON dc.PlayerLevelID = pl.PlayerLevelID
  AND pl.PlayerLevelID <> 4
GROUP BY cast(OpenDate as date), CASE WHEN dc.PlayerLevelID IN (0,1) THEN 'Non-Club' ELSE 'Club' END