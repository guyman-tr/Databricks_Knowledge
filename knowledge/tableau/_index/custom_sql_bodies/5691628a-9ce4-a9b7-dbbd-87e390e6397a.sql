--The data is from Adar's Notebook- "Crypto Click Size Methodology"

--*****the data is monthly, per instrumentname and exchnage
--*****create avg vwaps per segment as it is in gaps columns
--*****find when the vwap is above 1 % and then the relevant group will be the one before (the click size group)
--*****if the first vwap which is the 1K is already above 1% then the max click size will be 500
--*****if all the vwap below 1% then-> if HBC (HS 82)->  the max click size will be 3M
--*****if all the vwap below 1% then-> if CBH (HS 84)->  the max click size will be 1M
--*****all this will be on monthly basis with avg of avg- the avg will be on all the exchanges except 'Binance'
--*****Added MaxLeverage (Allowed) according to Median(TOBSpread%) --New 13.01.2026

WITH AVG_Data AS (
  SELECT
    date_trunc('month', ReportDate) AS MonthStart,
    InstrumentName,
    Symbol,
    AVG(AVG_BidTOB)           AS Average_of_AVG_Bid_TOB,
    AVG(AVG_VWAPBids1000)     AS Average_of_AVG_Bid_1K,
    AVG(AVG_VWAPBids5000)     AS Average_of_AVG_Bid_5K,
    AVG(AVG_VWAPBids10000)    AS Average_of_AVG_Bid_10K,
    AVG(AVG_VWAPBids25000)    AS Average_of_AVG_Bid_25K,
    AVG(AVG_VWAPBids50000)    AS Average_of_AVG_Bid_50K,
    AVG(AVG_VWAPBids100000)   AS Average_of_AVG_Bid_100K,
    AVG(AVG_VWAPBids250000)   AS Average_of_AVG_Bid_250K,
    AVG(AVG_VWAPBids500000)   AS Average_of_AVG_Bid_500K,
    AVG(AVG_VWAPBids1000000)  AS Average_of_AVG_Bid_1M, 
    percentile_cont(0.5) WITHIN GROUP (ORDER BY `TOB_Spreads%`) AS `median_TOB_Spreads%` --New 13.01.2026
  FROM bi_dealing_stg.bi_output_dealing_mm_topofbook
  WHERE `Exchange` NOT IN ('Binance')
  GROUP BY date_trunc('month', ReportDate), InstrumentName, Symbol
),

VWAP_Data AS (
  SELECT
    *,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_1K)   / Average_of_AVG_Bid_1K   AS VWAP_Slippage_1K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_5K)   / Average_of_AVG_Bid_5K   AS VWAP_Slippage_5K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_10K)  / Average_of_AVG_Bid_10K  AS VWAP_Slippage_10K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_25K)  / Average_of_AVG_Bid_25K  AS VWAP_Slippage_25K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_50K)  / Average_of_AVG_Bid_50K  AS VWAP_Slippage_50K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_100K) / Average_of_AVG_Bid_100K AS VWAP_Slippage_100K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_250K) / Average_of_AVG_Bid_250K AS VWAP_Slippage_250K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_500K) / Average_of_AVG_Bid_500K AS VWAP_Slippage_500K,
    (Average_of_AVG_Bid_TOB - Average_of_AVG_Bid_1M)   / Average_of_AVG_Bid_1M   AS VWAP_Slippage_1M
  FROM AVG_Data
) ,

HS_Date AS (
  SELECT
    MonthStart,
    InstrumentID,
    InstrumentName,
    name,
    HedgeServerID
  FROM (
    SELECT
      date_trunc('month', to_date(CAST(DateID AS STRING), 'yyyyMMdd')) AS MonthStart,
      cli.InstrumentID,
      cli.InstrumentName,
      mmdi.name,
      HedgeServerID,
      SUM(volume) AS sum_volume,
      ROW_NUMBER() OVER (
        PARTITION BY
          date_trunc('month', to_date(CAST(DateID AS STRING), 'yyyyMMdd')),
          cli.InstrumentID, cli.InstrumentName, mmdi.name
        ORDER BY SUM(volume) DESC
      ) AS rn
    FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown cli
    JOIN main.dealing.bronze_marketmaker_dbo_instruments mmdi
      ON mmdi.etoroinstrumentid = cli.instrumentid
    WHERE InstrumentTypeID = 10
      AND HedgeServerID IN (82, 84)
    GROUP BY
      date_trunc('month', to_date(CAST(DateID AS STRING), 'yyyyMMdd')),
      cli.InstrumentID, cli.InstrumentName, mmdi.name, HedgeServerID
  ) a
  WHERE rn = 1
),

Click_Size AS (
  SELECT 
    hs.InstrumentID,
    vd.*,
    hs.HedgeServerID,
    CASE
      -- if all below 1% → HS rule
      WHEN IFNULL(VWAP_Slippage_1K,   0) < 0.01
       AND IFNULL(VWAP_Slippage_5K,   0) < 0.01
       AND IFNULL(VWAP_Slippage_10K,  0) < 0.01
       AND IFNULL(VWAP_Slippage_25K,  0) < 0.01
       AND IFNULL(VWAP_Slippage_50K,  0) < 0.01
       AND IFNULL(VWAP_Slippage_100K, 0) < 0.01
       AND IFNULL(VWAP_Slippage_250K, 0) < 0.01
       AND IFNULL(VWAP_Slippage_500K, 0) < 0.01
       AND IFNULL(VWAP_Slippage_1M,   0) < 0.01
        THEN (CASE WHEN HedgeServerID = 82 THEN 3000000
                   WHEN HedgeServerID = 84 THEN 1000000
                   ELSE NULL END)
      -- first >= 1% defines click size (with the 1K rule)
      WHEN VWAP_Slippage_1K   >= 0.01 THEN 500
      WHEN VWAP_Slippage_5K   >= 0.01 THEN 1000
      WHEN VWAP_Slippage_10K  >= 0.01 THEN 5000
      WHEN VWAP_Slippage_25K  >= 0.01 THEN 10000
      WHEN VWAP_Slippage_50K  >= 0.01 THEN 25000
      WHEN VWAP_Slippage_100K >= 0.01 THEN 50000
      WHEN VWAP_Slippage_250K >= 0.01 THEN 100000
      WHEN VWAP_Slippage_500K >= 0.01 THEN 250000
      WHEN VWAP_Slippage_1M   >= 0.01 THEN 500000
      ELSE NULL
    END AS NewClickSize_Dollar
  FROM VWAP_Data vd
  JOIN HS_Date hs
    ON vd.InstrumentName= hs.name
   AND vd.MonthStart= hs.MonthStart
) 

SELECT 
cs.*,
case when cs.`median_TOB_Spreads%` > 0.05 then 1
     when (cs.`median_TOB_Spreads%` > 0.04 and cs.`median_TOB_Spreads%` <= 0.05) then 5
     when (cs.`median_TOB_Spreads%` > 0.03 and cs.`median_TOB_Spreads%` <= 0.04) then 10
     when (cs.`median_TOB_Spreads%` > 0.02 and cs.`median_TOB_Spreads%` <= 0.03) then 20 --New 26.03.2026
     when cs.`median_TOB_Spreads%` <= 0.02 then 50 
     else Null end as MaxLeverage,              --New 13.01.2026
pr.RateLastEx,
cs.NewClickSize_Dollar / pr.RateLastEx AS NewClickSize_Units,
cs.NewClickSize_Dollar*2 AS TreeSize_Dollar,
(cs.NewClickSize_Dollar / pr.RateLastEx)*2 AS TreeSize_Units
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit pr
JOIN Click_Size cs
ON pr.InstrumentID= cs.InstrumentID
WHERE pr.OccurredDateID = CAST(date_format(date_sub(current_date(), 1), 'yyyyMMdd') AS INT) -- Yesterday in yyyymmdd
order by 2 desc,1