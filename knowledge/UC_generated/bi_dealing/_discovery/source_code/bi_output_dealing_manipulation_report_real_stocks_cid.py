# ==========================================================================
# Source: system.access.table_lineage → Workspace API export
# Object:  main.bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid
# Writer:  /Workspace/Users/sarahbe@etoro.com/SP_ManipulationReport_RealStocks/SP_ManipulationReport_RealStocks 2026 01 21
# Language: PYTHON
# Captured: 2026-05-19T12:30:58Z
# Source URL: databricks://workspace/Workspace/Users/sarahbe@etoro.com/SP_ManipulationReport_RealStocks/SP_ManipulationReport_RealStocks 2026 01 21
# ==========================================================================

# >>>>> writer #1 role=primary job=890035936646942 task=SP_ManipulationReport_RealStock
-- Databricks notebook source
-- MAGIC %python
-- MAGIC        
-- MAGIC
-- MAGIC from datetime import datetime, timedelta 
-- MAGIC from pyspark.sql import DataFrame
-- MAGIC from pyspark.sql.functions import lit
-- MAGIC import ast
-- MAGIC import re
-- MAGIC import os 
-- MAGIC
-- MAGIC def get_previous_business_day(date):
-- MAGIC     previous_day = date - timedelta(days=1)
-- MAGIC     while previous_day.weekday() > 4:  # 0 = Monday, 1 = Tuesday, ..., 4 = Friday
-- MAGIC         previous_day -= timedelta(days=1)
-- MAGIC     return previous_day
-- MAGIC
-- MAGIC try:
-- MAGIC     dbutils.widgets.text("config", "");
-- MAGIC     config_value = dbutils.widgets.get("config")
-- MAGIC except Exception as e:
-- MAGIC     config_value = ""
-- MAGIC
-- MAGIC if config_value != "":
-- MAGIC     configObject = ast.literal_eval(config_value)
-- MAGIC     run_date = configObject[0]['Date']
-- MAGIC     run_date = datetime.strptime(run_date, '%Y-%m-%d')
-- MAGIC else:
-- MAGIC     # For manual rerun, setting run_date to yesterday
-- MAGIC     run_date =datetime.now() - timedelta(days=1)
-- MAGIC
-- MAGIC etr_ymd = str(run_date)[0:10]  # run_date.strftime("%Y-%m-%d")
-- MAGIC #etr_ymd = '2025-12-30'   
-- MAGIC etr_ym = str(etr_ymd)[0:7]
-- MAGIC etr_y = str(etr_ymd)[0:4]
-- MAGIC       
-- MAGIC etr_ymdID=int(etr_ymd.replace('-',''))
-- MAGIC
-- MAGIC etr_ymd_Last30Days=(datetime.strptime(etr_ymd, '%Y-%m-%d') - timedelta(days=30)).strftime("%Y-%m-%d")
-- MAGIC etr_ymd_Last30DaysID=int(etr_ymd_Last30Days.replace('-',''))
-- MAGIC
-- MAGIC etr_ymd_Last90Days=(datetime.strptime(etr_ymd, '%Y-%m-%d') - timedelta(days=90)).strftime("%Y-%m-%d")
-- MAGIC
-- MAGIC
-- MAGIC
-- MAGIC print("RunDate: " + str(run_date) + "\n" + "Yesterday: " + etr_ymd + "\n" + "etr_ymd_Last30Days: " + str(etr_ymd_Last30Days) + "\n" + "etr_ymd_Last90Days: " + etr_ymd_Last90Days)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC        
-- MAGIC
-- MAGIC query_create_view_StocksInfo = f"""
-- MAGIC create or replace temp view StocksInfo as
-- MAGIC SELECT cast(etr_ymd as date) AS Date
-- MAGIC       ,cast(instrument_id as int) AS InstrumentID
-- MAGIC       ,cast(MAX(CASE WHEN MetadataID = 8735 THEN FundamentalsSets_Fundamentals_Value ELSE NULL END) as decimal(38,2)) AS MarketCapital
-- MAGIC       ,cast(MAX(CASE WHEN MetadataID = 8708 THEN FundamentalsSets_Fundamentals_Value ELSE NULL END) as decimal(38,2)) AS DailyVolume 
-- MAGIC FROM experience.vw_silver_xignite_fundamentalsdailyrange_ttm a
-- MAGIC WHERE etr_ymd BETWEEN '{etr_ymd_Last90Days}' AND '{etr_ymd}'
-- MAGIC GROUP BY instrument_id
-- MAGIC 		,etr_ymd
-- MAGIC
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_StocksInfo) 

-- COMMAND ----------

--describe table experience.vw_silver_xignite_fundamentalsdailyrange_ttm

-- COMMAND ----------

--select * from StocksInfo

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_StocksInfo_KPIs_Calc = f"""
-- MAGIC create or replace temp view StocksInfo_KPIs_Calc as
-- MAGIC SELECT SI.Date
-- MAGIC       ,SI.InstrumentID
-- MAGIC       ,SI.MarketCapital
-- MAGIC       ,SI.DailyVolume
-- MAGIC 	  ,RN.RN_MktCap
-- MAGIC       ,AVG(DailyVolume) OVER (PARTITION BY SI.InstrumentID ORDER BY SI.Date ASC ROWS 9 PRECEDING) MA_10Days
-- MAGIC 	  ,ROW_NUMBER() OVER (PARTITION BY SI.InstrumentID ORDER BY SI.Date DESC) RN_Date
-- MAGIC FROM StocksInfo SI
-- MAGIC LEFT JOIN (SELECT Date
-- MAGIC 	             ,InstrumentID
-- MAGIC 	             ,MarketCapital
-- MAGIC 	             ,ROW_NUMBER() OVER (PARTITION BY Date ORDER BY MarketCapital ASC) RN_MktCap				 
-- MAGIC 	       FROM StocksInfo
-- MAGIC 	       WHERE MarketCapital IS NOT NULL
-- MAGIC 		   ) RN
-- MAGIC  ON RN.InstrumentID = SI.InstrumentID
-- MAGIC AND SI.DailyVolume > 0 
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_StocksInfo_KPIs_Calc) 
-- MAGIC

-- COMMAND ----------

--select * from StocksInfo_KPIs_Calc

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_StocksInfo_KPIs = f"""
-- MAGIC create or replace temp view StocksInfo_KPIs as
-- MAGIC SELECT Date
-- MAGIC       ,InstrumentID
-- MAGIC       ,MarketCapital
-- MAGIC       ,DailyVolume
-- MAGIC       ,MA_10Days
-- MAGIC       ,RN_MktCap
-- MAGIC       ,CASE WHEN RN_MktCap <= 20 THEN 1 ELSE 0 END AS IsLowMktCap
-- MAGIC FROM StocksInfo_KPIs_Calc 
-- MAGIC WHERE RN_Date = 1
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_StocksInfo_KPIs) 
-- MAGIC

-- COMMAND ----------

--select * from StocksInfo_KPIs

-- COMMAND ----------

-- DBTITLE 1,Snapshot InstrumentMetaData parquet to avoid InconsistentReadException
-- MAGIC %python
-- MAGIC # Create a Delta snapshot of the parquet-backed table
-- MAGIC # This provides ACID reads and avoids InconsistentReadException if upstream pipeline overwrites the file mid-query
-- MAGIC spark.sql("REFRESH TABLE main.trading.bronze_etoro_trade_instrumentmetadata")
-- MAGIC
-- MAGIC spark.sql("""
-- MAGIC     CREATE OR REPLACE TABLE bi_dealing_stg.tmp_instrumentmetadata_snapshot
-- MAGIC     USING DELTA
-- MAGIC     AS SELECT * FROM main.trading.bronze_etoro_trade_instrumentmetadata
-- MAGIC """)
-- MAGIC print("InstrumentMetaData Delta snapshot created successfully")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC        
-- MAGIC query_create_view_MarketHours = f"""
-- MAGIC CREATE OR REPLACE TEMP VIEW MarketHours AS
-- MAGIC SELECT
-- MAGIC   InstrumentID,
-- MAGIC   Exchange,
-- MAGIC   CASE
-- MAGIC     WHEN ExchangeID IN (6, 7, 9, 10, 11, 12, 14, 15, 16, 17, 22, 23, 30)
-- MAGIC       THEN date_add(HOUR, 7, date_trunc('DAY', current_timestamp()))
-- MAGIC     WHEN ExchangeID IN (4, 5, 18, 19, 20)
-- MAGIC       THEN date_add(MINUTE, 30, date_add(HOUR, 13, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (21)
-- MAGIC       THEN date_add(MINUTE, 30, date_add(HOUR, 1, date_trunc('DAY', current_timestamp())))
-- MAGIC     ELSE NULL
-- MAGIC   END AS MarketOpeningHour,
-- MAGIC   CASE
-- MAGIC     WHEN ExchangeID IN (6, 7, 9, 10, 22, 23, 30)
-- MAGIC       THEN date_add(MINUTE, 30, date_add(HOUR, 15, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (11, 15, 17)
-- MAGIC       THEN date_add(MINUTE, 25, date_add(HOUR, 15, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (16)
-- MAGIC       THEN date_add(MINUTE, 55, date_add(HOUR, 14, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (14)
-- MAGIC       THEN date_add(MINUTE, 20, date_add(HOUR, 14, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (12)
-- MAGIC       THEN date_add(MINUTE, 20, date_add(HOUR, 15, date_trunc('DAY', current_timestamp())))
-- MAGIC     WHEN ExchangeID IN (21)
-- MAGIC       THEN date_add(HOUR, 8, date_trunc('DAY', current_timestamp()))
-- MAGIC     WHEN ExchangeID IN (4, 5, 18, 19, 20)
-- MAGIC       THEN date_add(HOUR, 20, date_trunc('DAY', current_timestamp()))
-- MAGIC     ELSE NULL
-- MAGIC   END AS MarketClosingHour
-- MAGIC FROM bi_dealing_stg.tmp_instrumentmetadata_snapshot
-- MAGIC WHERE Tradable = true
-- MAGIC   AND DAYOFWEEK('{etr_ymd}') BETWEEN 2 AND 6
-- MAGIC """
-- MAGIC spark.sql(query_create_view_MarketHours)

-- COMMAND ----------

--select  * from main.trading.bronze_etoro_trade_instrumentmetadata limit 30

-- COMMAND ----------

--select * from MarketHours

-- COMMAND ----------

-- MAGIC %python
-- MAGIC query_create_view_MarketHoursTime = """
-- MAGIC CREATE OR REPLACE TEMP VIEW MarketHoursTime AS
-- MAGIC SELECT
-- MAGIC   mh.InstrumentID,
-- MAGIC   format_string(
-- MAGIC     '%02d:%02d:00',
-- MAGIC     hour(MIN(coalesce(mh.MarketOpeningHour,'00:00:00'))),
-- MAGIC     minute(MIN(coalesce(mh.MarketOpeningHour,'00:00:00')))
-- MAGIC   ) AS MarketOpen,
-- MAGIC   format_string(
-- MAGIC     '%02d:%02d:00',
-- MAGIC     hour(MAX(coalesce(mh.MarketClosingHour,'00:00:00'))),
-- MAGIC     minute(MAX(coalesce(mh.MarketClosingHour,'00:00:00')))
-- MAGIC   ) AS MarketClose
-- MAGIC FROM MarketHours mh
-- MAGIC GROUP BY mh.InstrumentID
-- MAGIC """
-- MAGIC spark.sql(query_create_view_MarketHoursTime)

-- COMMAND ----------

--select * from MarketHoursTime
-- replace null:null:00?

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_MaxToMinChange = f"""
-- MAGIC create or replace temp view MaxToMinChange as
-- MAGIC SELECT
-- MAGIC 	CAST(DateFrom AS DATE) AS Date
-- MAGIC    ,InstrumentID
-- MAGIC    ,(MAX(BidMax) / MIN(BidMin)) - 1 AS MaxToMinChange 
-- MAGIC FROM main.dealing.candles_get_spreaded_price_candle60min_splitted
-- MAGIC WHERE CAST(DateFrom AS DATE) = '{etr_ymd}'
-- MAGIC GROUP BY CAST(DateFrom AS DATE)
-- MAGIC 		,InstrumentID
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_MaxToMinChange) 
-- MAGIC

-- COMMAND ----------

--select * from MaxToMinChange

-- COMMAND ----------

-- MAGIC %python
-- MAGIC query_create_view_positions = f"""
-- MAGIC CREATE OR REPLACE TEMP VIEW positions AS
-- MAGIC SELECT 
-- MAGIC   b.CID,
-- MAGIC   b.PositionID,
-- MAGIC   b.InstrumentID,
-- MAGIC   i.InstrumentType,
-- MAGIC   i.InstrumentDisplayName,
-- MAGIC   OpenDateID,
-- MAGIC   OpenOccurred,
-- MAGIC   CloseDateID,
-- MAGIC   CloseOccurred,
-- MAGIC   b.TreeID,
-- MAGIC   COALESCE(IsPartialCloseChild,0) AS IsPartialCloseChild,
-- MAGIC   CASE WHEN CloseDateID = 0 THEN 1 ELSE 0 END AS IsOpenPosition,
-- MAGIC   CASE WHEN b.MirrorID = 0 THEN 1 ELSE 0 END AS IsManualPosition,
-- MAGIC   CASE WHEN b.CloseDateID > 0 THEN 
-- MAGIC     CASE WHEN DATEDIFF(MINUTE, b.OpenOccurred, b.CloseOccurred) <= 20 THEN 1 ELSE 0 END
-- MAGIC     ELSE 0 END AS Is20MinDuration,
-- MAGIC   CASE WHEN b.OpenDateID = '{etr_ymdID}' THEN b.Volume ELSE 0 END AS VolumeOnOpen,
-- MAGIC   CASE WHEN b.CloseDateID = '{etr_ymdID}' THEN b.VolumeOnClose ELSE 0 END AS VolumeOnClose,
-- MAGIC   CASE WHEN b.OpenDateID = '{etr_ymdID}' THEN b.AmountInUnitsDecimal ELSE 0 END AS UnitsOnOpen,
-- MAGIC   CASE WHEN b.CloseDateID = '{etr_ymdID}' THEN b.AmountInUnitsDecimal ELSE 0 END AS UnitsOnClose,
-- MAGIC   ch.MaxToMinChange,
-- MAGIC   CASE WHEN 
-- MAGIC     concat(
-- MAGIC       lpad(hour(b.OpenOccurred),2,'0'), ':', lpad(minute(b.OpenOccurred),2,'0'), ':00'
-- MAGIC     ) BETWEEN mh.MarketOpen AND
-- MAGIC     concat(
-- MAGIC       lpad(hour(date_add(MINUTE, 10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketOpen)))),2,'0'), ':',
-- MAGIC       lpad(minute(date_add(MINUTE, 10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketOpen)))),2,'0'), ':00'
-- MAGIC     )
-- MAGIC     THEN 1 ELSE 0 END AS First10Min_Open,
-- MAGIC   CASE WHEN 
-- MAGIC     concat(
-- MAGIC       lpad(hour(b.CloseOccurred),2,'0'), ':', lpad(minute(b.CloseOccurred),2,'0'), ':00'
-- MAGIC     ) BETWEEN mh.MarketOpen AND
-- MAGIC     concat(
-- MAGIC       lpad(hour(date_add(MINUTE, 10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketOpen)))),2,'0'), ':',
-- MAGIC       lpad(minute(date_add(MINUTE, 10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketOpen)))),2,'0'), ':00'
-- MAGIC     )
-- MAGIC     THEN 1 ELSE 0 END AS First10Min_Close,
-- MAGIC   CASE WHEN 
-- MAGIC     concat(
-- MAGIC       lpad(hour(b.OpenOccurred),2,'0'), ':', lpad(minute(b.OpenOccurred),2,'0'), ':00'
-- MAGIC     ) BETWEEN
-- MAGIC     concat(
-- MAGIC       lpad(hour(date_add(MINUTE, -10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketClose)))),2,'0'), ':',
-- MAGIC       lpad(minute(date_add(MINUTE, -10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketClose)))),2,'0'), ':00'
-- MAGIC     )
-- MAGIC     AND mh.MarketClose
-- MAGIC     THEN 1 ELSE 0 END AS Last10Min_Open,
-- MAGIC   CASE WHEN 
-- MAGIC     concat(
-- MAGIC       lpad(hour(b.CloseOccurred),2,'0'), ':', lpad(minute(b.CloseOccurred),2,'0'), ':00'
-- MAGIC     ) BETWEEN
-- MAGIC     concat(
-- MAGIC       lpad(hour(date_add(MINUTE, -10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketClose)))),2,'0'), ':',
-- MAGIC       lpad(minute(date_add(MINUTE, -10, to_timestamp(concat('{etr_ymd}', ' ', mh.MarketClose)))),2,'0'), ':00'
-- MAGIC     )
-- MAGIC     AND mh.MarketClose
-- MAGIC     THEN 1 ELSE 0 END AS Last10Min_Close
-- MAGIC FROM main.dwh.dim_position b
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument i 
-- MAGIC   ON i.InstrumentID = b.InstrumentID
-- MAGIC LEFT JOIN MarketHoursTime mh
-- MAGIC   ON mh.InstrumentID = b.InstrumentID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
-- MAGIC   ON dc.RealCID = b.CID
-- MAGIC LEFT JOIN MaxToMinChange ch
-- MAGIC   ON ch.InstrumentID = b.InstrumentID AND ch.Date = '{etr_ymd}'
-- MAGIC WHERE (OpenDateID = '{etr_ymdID}' OR b.CloseDateID = '{etr_ymdID}')                         
-- MAGIC   AND i.InstrumentTypeID IN (5,6)
-- MAGIC   AND b.IsSettled = 1
-- MAGIC   AND dc.IsValidCustomer = 1
-- MAGIC """
-- MAGIC spark.sql(query_create_view_positions)

-- COMMAND ----------

--select * from positions

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TreePositions = f"""
-- MAGIC create or replace temp view TreePositions as
-- MAGIC SELECT cast('{etr_ymd}' as date) AS Date
-- MAGIC        ,p1.CID
-- MAGIC        ,p1.PositionID
-- MAGIC        ,p1.InstrumentID
-- MAGIC        ,p1.InstrumentType
-- MAGIC        ,p1.InstrumentDisplayName
-- MAGIC        ,p1.OpenDateID
-- MAGIC        ,p1.CloseDateID
-- MAGIC 	   ,p1.OpenOccurred
-- MAGIC 	   ,p1.CloseOccurred
-- MAGIC 	   ,p1.IsOpenPosition
-- MAGIC 	   ,p1.Is20MinDuration
-- MAGIC 	   ,p1.MaxToMinChange
-- MAGIC 	   ,p1.IsPartialCloseChild
-- MAGIC 	   ,p1.Last10Min_Open
-- MAGIC 	   ,p1.First10Min_Open
-- MAGIC 	   ,p1.First10Min_Close
-- MAGIC 	   ,p1.Last10Min_Close
-- MAGIC 	   ,IFNULL(SUM(p2.VolumeOnOpen),0) AS Volume
-- MAGIC 	   ,IFNULL(SUM(p2.VolumeOnClose),0)  AS VolumeOnClose
-- MAGIC 	   ,IFNULL(SUM(p2.UnitsOnOpen),0) AS Units
-- MAGIC 	   ,IFNULL(SUM(p2.UnitsOnClose),0) AS UnitsOnClose
-- MAGIC FROM positions p1
-- MAGIC LEFT JOIN positions p2
-- MAGIC  ON p1.PositionID = p2.TreeID --AND p2.IsManualPosition = 0
-- MAGIC WHERE p1.IsManualPosition = 1
-- MAGIC   AND p1.IsPartialCloseChild = 0
-- MAGIC GROUP BY p1.CID
-- MAGIC         ,p1.PositionID
-- MAGIC         ,p1.InstrumentID
-- MAGIC         ,p1.InstrumentType
-- MAGIC         ,p1.InstrumentDisplayName
-- MAGIC         ,p1.OpenDateID
-- MAGIC         ,p1.CloseDateID
-- MAGIC 	    ,p1.IsOpenPosition
-- MAGIC 	    ,p1.Is20MinDuration
-- MAGIC 		,p1.MaxToMinChange
-- MAGIC 		,p1.IsPartialCloseChild
-- MAGIC         ,p1.First10Min_Open
-- MAGIC 	   ,p1.Last10Min_Open
-- MAGIC 	   ,p1.First10Min_Close
-- MAGIC 	   ,p1.Last10Min_Close
-- MAGIC 	   ,p1.OpenOccurred
-- MAGIC 	   ,p1.CloseOccurred 
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TreePositions) 
-- MAGIC

-- COMMAND ----------

--select * from TreePositions

-- COMMAND ----------

-- MAGIC %python
-- MAGIC query_create_view_All_Positions_Data = f"""
-- MAGIC create or replace temp view All_Positions_Data as
-- MAGIC SELECT a.*
-- MAGIC       ,c.Name AS Country
-- MAGIC       ,concat(dm.FirstName, ' ', dm.LastName) AS Manager
-- MAGIC       ,dr.Name AS Regulation
-- MAGIC       ,pl.Name AS Club
-- MAGIC       ,dc.UserName
-- MAGIC       ,fca.IsLowMktCap
-- MAGIC FROM TreePositions a
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked sc
-- MAGIC   ON sc.RealCID = a.CID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr1
-- MAGIC  ON dr1.DateRangeID = sc.DateRangeID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c 
-- MAGIC  ON c.CountryID = sc.CountryID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
-- MAGIC  ON dm.ManagerID = sc.AccountManagerID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation  dr 
-- MAGIC  ON dr.DWHRegulationID = sc.RegulationID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl 
-- MAGIC  ON pl.PlayerLevelID = sc.PlayerLevelID
-- MAGIC INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
-- MAGIC  ON dc.RealCID = sc.RealCID 
-- MAGIC LEFT JOIN StocksInfo_KPIs fca 
-- MAGIC  ON fca.InstrumentID = a.InstrumentID 
-- MAGIC  AND fca.Date = a.Date
-- MAGIC WHERE sc.IsValidCustomer = 1
-- MAGIC   AND dr1.FromDateID <= '{etr_ymdID}'
-- MAGIC   AND dr1.ToDateID > '{etr_ymdID}'
-- MAGIC   AND c.RegulationID IN (1,2,4) 
-- MAGIC """
-- MAGIC spark.sql(query_create_view_All_Positions_Data)

-- COMMAND ----------

--select * from All_Positions_Data

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TopVolume = f"""
-- MAGIC create or replace temp view TopVolume as
-- MAGIC SELECT        tp.InstrumentID
-- MAGIC              ,tp.InstrumentDisplayName
-- MAGIC 	         ,tp.InstrumentType
-- MAGIC 	         ,SUM(tp.Volume) + SUM(tp.VolumeOnClose) AS Volume
-- MAGIC 			 ,SUM(tp.Units) + SUM(tp.UnitsOnClose) AS  Units
-- MAGIC 			 ,tp.Regulation
-- MAGIC 			 ,tp.IsLowMktCap
-- MAGIC 			 ,tp.MaxToMinChange
-- MAGIC 			
-- MAGIC FROM All_Positions_Data tp
-- MAGIC GROUP BY tp.InstrumentID
-- MAGIC         ,tp.InstrumentDisplayName
-- MAGIC 	    ,tp.InstrumentType
-- MAGIC 		,tp.Regulation
-- MAGIC         ,tp.IsLowMktCap 
-- MAGIC         ,tp.MaxToMinChange     
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TopVolume) 
-- MAGIC

-- COMMAND ----------

--select * from TopVolume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Top20Volume = f"""
-- MAGIC create or replace temp view Top20Volume as
-- MAGIC SELECT * ,ROW_NUMBER() OVER(PARTITION BY Regulation,IsLowMktCap ORDER BY Volume DESC) RN
-- MAGIC FROM TopVolume   
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Top20Volume) 
-- MAGIC

-- COMMAND ----------

--select * from Top20Volume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Yday_Top20_Volume = f"""
-- MAGIC create or replace temp view Yday_Top20_Volume as
-- MAGIC SELECT * 
-- MAGIC FROM Top20Volume 
-- MAGIC WHERE RN <= 20 
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Yday_Top20_Volume) 
-- MAGIC

-- COMMAND ----------

--select * from Yday_Top20_Volume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TopVolume = f"""
-- MAGIC create or replace temp view TopVolume as
-- MAGIC SELECT  tp.InstrumentID
-- MAGIC 	   ,tp.InstrumentDisplayName
-- MAGIC 	   ,tp.InstrumentType
-- MAGIC 	   ,SUM(tp.Volume) + SUM(tp.VolumeOnClose) AS Volume
-- MAGIC 	   ,SUM(tp.Units) + SUM(tp.UnitsOnClose) AS Units
-- MAGIC 	   ,tp.Regulation
-- MAGIC 	   ,tp.IsLowMktCap
-- MAGIC 	   ,tp.MaxToMinChange
-- MAGIC FROM All_Positions_Data tp
-- MAGIC WHERE Is20MinDuration = 1
-- MAGIC AND tp.IsOpenPosition = 0
-- MAGIC GROUP BY tp.InstrumentID
-- MAGIC 			,tp.InstrumentDisplayName
-- MAGIC 			,tp.InstrumentType
-- MAGIC 			,tp.Regulation
-- MAGIC             ,tp.IsLowMktCap
-- MAGIC             ,tp.MaxToMinChange
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TopVolume) 
-- MAGIC

-- COMMAND ----------

--select * from TopVolume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Top20Volume = f"""
-- MAGIC create or replace temp view Top20Volume as
-- MAGIC SELECT *
-- MAGIC 	   ,ROW_NUMBER() OVER (PARTITION BY Regulation,IsLowMktCap ORDER BY Volume DESC) RN
-- MAGIC FROM TopVolume
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Top20Volume) 
-- MAGIC

-- COMMAND ----------

--select * from Top20Volume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Yday_Top20_Volume_20Min = f"""
-- MAGIC create or replace temp view Yday_Top20_Volume_20Min as
-- MAGIC SELECT *
-- MAGIC FROM Top20Volume
-- MAGIC WHERE RN <= 20
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Yday_Top20_Volume_20Min) 
-- MAGIC

-- COMMAND ----------

--select * from Yday_Top20_Volume_20Min

-- COMMAND ----------

-- MAGIC %python
-- MAGIC        
-- MAGIC
-- MAGIC query_create_view_WorkDays = f"""
-- MAGIC create or replace temp view WorkDays as
-- MAGIC SELECT
-- MAGIC 	dd.DateKey 
-- MAGIC FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd
-- MAGIC WHERE dd.FiscalYear >= 2019
-- MAGIC AND dd.IsWorkday = 'Y'
-- MAGIC AND dd.DateKey <= '{etr_ymdID}' 
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_WorkDays) 
-- MAGIC

-- COMMAND ----------

--select * from WorkDays

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_CountWorkDays = f"""
-- MAGIC create or replace temp view CountWorkDays as
-- MAGIC SELECT *
-- MAGIC       ,LAG(DateKey, 29) OVER (ORDER BY DateKey) AS 30DaysBefore
-- MAGIC FROM WorkDays wd
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_CountWorkDays) 
-- MAGIC

-- COMMAND ----------

--select * from CountWorkDays

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df = spark.sql(
-- MAGIC     f"SELECT 30DaysBefore FROM CountWorkDays WHERE DateKey = '{etr_ymdID}'"
-- MAGIC )
-- MAGIC rows = df.collect()
-- MAGIC if rows:
-- MAGIC     ThirtyDaysBefore = rows[0]['30DaysBefore']
-- MAGIC else:
-- MAGIC     ThirtyDaysBefore = None
-- MAGIC
-- MAGIC df.display()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC query_create_view_Times = f"""
-- MAGIC CREATE OR REPLACE TEMP VIEW Times AS
-- MAGIC SELECT
-- MAGIC   InstrumentID,
-- MAGIC   LPAD(HOUR(MarketOpen), 2, '0') || ':' ||
-- MAGIC   LPAD(MINUTE(MarketOpen), 2, '0') || ':00' AS OpenTime,
-- MAGIC   LPAD(HOUR(MarketOpen), 2, '0') || ':' ||
-- MAGIC   LPAD(MINUTE(MarketOpen), 2, '0') || ':00' AS CloseTime
-- MAGIC FROM MarketHoursTime mht
-- MAGIC """
-- MAGIC spark.sql(query_create_view_Times)

-- COMMAND ----------

--select * from Times

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_AvgVolume = f"""
-- MAGIC create or replace temp view AvgVolume as
-- MAGIC SELECT dp.InstrumentID
-- MAGIC       ,SUM(CASE WHEN dp.OpenDateID BETWEEN '{ThirtyDaysBefore}' AND '{etr_ymdID}' THEN  CAST(dp.Volume AS BIGINT) ELSE 0 END) AS OpenVolume30Days
-- MAGIC       ,SUM(CASE WHEN dp.CloseDateID BETWEEN '{ThirtyDaysBefore}' AND '{etr_ymdID}' THEN  CAST(dp.VolumeOnClose AS BIGINT) ELSE 0 END) AS CloseVolume30Days
-- MAGIC       ,COUNT(dp.PositionID) AS OP_30Days
-- MAGIC FROM WorkDays wd
-- MAGIC LEFT JOIN main.dwh.dim_position dp
-- MAGIC 	ON wd.DateKey = dp.OpenDateID
-- MAGIC 		AND(dp.OpenDateID BETWEEN '{ThirtyDaysBefore}' AND '{etr_ymdID}' OR dp.CloseDateID BETWEEN '{ThirtyDaysBefore}' AND '{etr_ymdID}')
-- MAGIC 		AND dp.MirrorID = 0
-- MAGIC 		AND dp.IsSettled = 1
-- MAGIC 		AND dp.IsComputeForHedge = 1
-- MAGIC WHERE wd.DateKey BETWEEN '{ThirtyDaysBefore}' AND '{etr_ymdID}'
-- MAGIC GROUP BY dp.InstrumentID
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_AvgVolume) 
-- MAGIC

-- COMMAND ----------

--select * from AvgVolume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_AvgDailyKPIs = f"""
-- MAGIC create or replace temp view AvgDailyKPIs as
-- MAGIC SELECT cast('{etr_ymd}' as date) AS Date
-- MAGIC       ,InstrumentID
-- MAGIC       ,OpenVolume30Days * 1.0 / 30 AS AvgDailyVolume
-- MAGIC 	  ,(OpenVolume30Days + CloseVolume30Days) * 1.0 / 30 AS AvgDailyVolumeAll
-- MAGIC       ,OP_30Days * 1.0 / 30 AS AvgDailyOpen 
-- MAGIC    --   ,IsFirst10Min_Volume * 1.00 / 30 AS AvgDailyVolume_First10
-- MAGIC 	  --,IsLast10Min_Volume * 1.00 / 30 AS AvgDailyVolume_Last10
-- MAGIC FROM AvgVolume
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_AvgDailyKPIs) 
-- MAGIC

-- COMMAND ----------

--select * from AvgDailyKPIs

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_DailyAvgVolume = f"""
-- MAGIC create or replace temp view DailyAvgVolume as
-- MAGIC SELECT a.Date
-- MAGIC       ,a.InstrumentID
-- MAGIC       ,a.InstrumentDisplayName
-- MAGIC 	  ,a.InstrumentType
-- MAGIC 	  ,a.Regulation
-- MAGIC 	  ,a.IsLowMktCap
-- MAGIC 	  ,a.MaxToMinChange
-- MAGIC 	  ,SUM(a.Volume) + SUM(a.VolumeOnClose) AS Volume
-- MAGIC 	  ,SUM(a.Units) + SUM(a.UnitsOnClose) AS Units
-- MAGIC FROM All_Positions_Data a
-- MAGIC
-- MAGIC GROUP BY a.Date
-- MAGIC       ,a.InstrumentID
-- MAGIC       ,a.InstrumentDisplayName
-- MAGIC 	  ,a.InstrumentType
-- MAGIC 	  ,a.Regulation
-- MAGIC 	  ,a.IsLowMktCap
-- MAGIC 	  ,a.MaxToMinChange
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_DailyAvgVolume) 
-- MAGIC

-- COMMAND ----------

--select * from DailyAvgVolume

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_VolDiff = f"""
-- MAGIC create or replace temp view VolDiff as
-- MAGIC SELECT a.* 
-- MAGIC       ,b.AvgDailyVolume
-- MAGIC 	  ,CASE WHEN b.AvgDailyVolume=0 THEN 0 ELSE (a.Volume * 1.0 / b.AvgDailyVolume) - 1 END AS PercentageFromAvgVolume
-- MAGIC FROM DailyAvgVolume a
-- MAGIC LEFT JOIN AvgDailyKPIs b
-- MAGIC ON b.InstrumentID = a.InstrumentID
-- MAGIC AND a.Date = b.Date
-- MAGIC AND a.Volume > IFNULL(b.AvgDailyVolume,0)
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_VolDiff) 
-- MAGIC

-- COMMAND ----------

--select * from VolDiff

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_RN_Avg = f"""
-- MAGIC create or replace temp view RN_Avg as
-- MAGIC SELECT *
-- MAGIC       ,ROW_NUMBER() OVER(PARTITION BY Regulation,IsLowMktCap ORDER BY PercentageFromAvgVolume DESC ) RN
-- MAGIC FROM VolDiff
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_RN_Avg) 
-- MAGIC

-- COMMAND ----------

--select * from RN_Avg

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Table2 = f"""
-- MAGIC create or replace temp view Table2 as
-- MAGIC SELECT a.*
-- MAGIC FROM RN_Avg  a
-- MAGIC WHERE RN <= 20
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Table2) 
-- MAGIC

-- COMMAND ----------

--select * from Table2

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TopVol = f"""
-- MAGIC create or replace temp view TopVol as
-- MAGIC SELECT        tp.InstrumentID
-- MAGIC              ,tp.InstrumentDisplayName
-- MAGIC 	         ,tp.InstrumentType
-- MAGIC 			 ,tp.Regulation
-- MAGIC 			 ,tp.IsLowMktCap
-- MAGIC 			 ,tp.MaxToMinChange
-- MAGIC 	         ,SUM(tp.Volume) + SUM(tp.VolumeOnClose) AS Volume
-- MAGIC 			 ,SUM(tp.Units) + SUM(tp.UnitsOnClose) AS Units
-- MAGIC
-- MAGIC FROM All_Positions_Data tp
-- MAGIC GROUP BY tp.InstrumentID
-- MAGIC         ,tp.InstrumentDisplayName
-- MAGIC 	    ,tp.InstrumentType
-- MAGIC 		,tp.Regulation
-- MAGIC         ,tp.IsLowMktCap 
-- MAGIC         ,tp.MaxToMinChange   
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TopVol) 
-- MAGIC

-- COMMAND ----------

--select * from TopVol

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Flag2 = f"""
-- MAGIC create or replace temp view Flag2 as
-- MAGIC SELECT a.*
-- MAGIC 	,fca.DailyVolume AS ExchangeUnitsVolume
-- MAGIC 	,fca.MA_10Days AS MA_10Days
-- MAGIC 	,a.Units / NULLIF(fca.DailyVolume,0) AS PercentOfDailyVolume 
-- MAGIC 	,adk.AvgDailyVolumeAll
-- MAGIC 	FROM TopVol a
-- MAGIC     JOIN StocksInfo_KPIs fca
-- MAGIC 	 ON fca.InstrumentID = a.InstrumentID 
-- MAGIC 	LEFT JOIN MaxToMinChange mmc
-- MAGIC 	 ON mmc.InstrumentID = a.InstrumentID
-- MAGIC      AND ABS(mmc.MaxToMinChange) >= 0.2
-- MAGIC 	 LEFT JOIN AvgDailyKPIs adk
-- MAGIC 	 ON adk.InstrumentID = a.InstrumentID
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Flag2) 
-- MAGIC

-- COMMAND ----------

--select * from Flag2

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_pre_Volume_First10Min = f"""
-- MAGIC create or replace temp view pre_Volume_First10Min as
-- MAGIC SELECT  tp.InstrumentID
-- MAGIC 	   ,tp.InstrumentDisplayName
-- MAGIC 	   ,tp.InstrumentType
-- MAGIC 	   ,tp.Regulation
-- MAGIC 	   ,tp.IsLowMktCap
-- MAGIC 	   ,tp.MaxToMinChange
-- MAGIC 	   ,SUM(CASE WHEN tp.First10Min_Open = 1 THEN tp.Volume ELSE 0 END)  + SUM(CASE WHEN tp.First10Min_Close = 1 THEN tp.VolumeOnClose ELSE 0 END) AS Volume
-- MAGIC 	   ,SUM(CASE WHEN tp.First10Min_Open = 1 THEN tp.Units ELSE 0 END)  + SUM(CASE WHEN tp.First10Min_Close = 1 THEN tp.UnitsOnClose ELSE 0 END) AS Units
-- MAGIC FROM All_Positions_Data tp
-- MAGIC WHERE tp.First10Min_Open = 1 OR tp.First10Min_Close = 1
-- MAGIC GROUP BY tp.InstrumentID
-- MAGIC 	    ,tp.InstrumentDisplayName
-- MAGIC 	    ,tp.InstrumentType
-- MAGIC 	    ,tp.Regulation
-- MAGIC 	    ,tp.IsLowMktCap
-- MAGIC 	    ,tp.MaxToMinChange
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_pre_Volume_First10Min) 
-- MAGIC

-- COMMAND ----------

--select * from pre_Volume_First10Min

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Volume_First10Min = f"""
-- MAGIC create or replace temp view Volume_First10Min as
-- MAGIC SELECT vfm.*
-- MAGIC      ,fca.DailyVolume AS ExchangeUnitsVolume
-- MAGIC 	 ,fca.MA_10Days AS MA_10Days
-- MAGIC 	 ,adk.AvgDailyVolumeAll
-- MAGIC FROM pre_Volume_First10Min vfm
-- MAGIC INNER JOIN StocksInfo_KPIs fca
-- MAGIC  ON fca.InstrumentID = vfm.InstrumentID
-- MAGIC INNER JOIN AvgDailyKPIs adk
-- MAGIC  ON vfm.InstrumentID = adk.InstrumentID
-- MAGIC
-- MAGIC WHERE IFNULL(vfm.Volume,0) / NULLIF(adk.AvgDailyVolumeAll,0) > 2
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Volume_First10Min) 
-- MAGIC

-- COMMAND ----------

--select * from Volume_First10Min

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_pre_Volume_Last10Min = f"""
-- MAGIC create or replace temp view pre_Volume_Last10Min as
-- MAGIC SELECT tp.InstrumentID
-- MAGIC       ,tp.InstrumentDisplayName
-- MAGIC       ,tp.InstrumentType
-- MAGIC       ,tp.Regulation
-- MAGIC       ,tp.IsLowMktCap
-- MAGIC       ,tp.MaxToMinChange 
-- MAGIC 	  ,SUM(CASE WHEN tp.Last10Min_Open = 1 THEN tp.Volume ELSE 0 END)  + SUM(CASE WHEN tp.Last10Min_Close = 1 THEN tp.VolumeOnClose ELSE 0 END) AS Volume
-- MAGIC 	  ,SUM(CASE WHEN tp.Last10Min_Open = 1 THEN tp.Units ELSE 0 END)  + SUM(CASE WHEN tp.Last10Min_Close  = 1 THEN tp.UnitsOnClose ELSE 0 END) AS Units
-- MAGIC FROM All_Positions_Data tp
-- MAGIC WHERE tp.Last10Min_Open = 1 OR tp.Last10Min_Close = 1
-- MAGIC GROUP BY tp.InstrumentID
-- MAGIC 		,tp.InstrumentDisplayName
-- MAGIC 		,tp.InstrumentType
-- MAGIC 		,tp.Regulation
-- MAGIC 		,tp.IsLowMktCap
-- MAGIC 		,tp.MaxToMinChange
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_pre_Volume_Last10Min) 
-- MAGIC

-- COMMAND ----------

--select * from pre_Volume_Last10Min

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Volume_Last10Min = f"""
-- MAGIC create or replace temp view Volume_Last10Min as
-- MAGIC SELECT vfm.*
-- MAGIC       ,fca.DailyVolume AS ExchangeUnitsVolume
-- MAGIC 	  ,fca.MA_10Days AS MA_10Days
-- MAGIC 	  ,adk.AvgDailyVolumeAll
-- MAGIC FROM pre_Volume_Last10Min vfm
-- MAGIC INNER JOIN StocksInfo_KPIs fca
-- MAGIC  ON fca.InstrumentID = vfm.InstrumentID
-- MAGIC INNER JOIN AvgDailyKPIs adk
-- MAGIC  ON vfm.InstrumentID = adk.InstrumentID
-- MAGIC
-- MAGIC WHERE IFNULL(vfm.Volume,0) / NULLIF(adk.AvgDailyVolumeAll,0) > 2
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Volume_Last10Min) 
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_ManipulationReport_RealStocks = f"""
-- MAGIC create or replace temp view ManipulationReport_RealStocks as
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'First10Minutes' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,NULL AS RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,a.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC    ,a.ExchangeUnitsVolume
-- MAGIC    ,a.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC    ,current_timestamp() AS UpdateDate
-- MAGIC              ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC
-- MAGIC FROM Volume_First10Min a
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Last10Minutes' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,NULL AS RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,a.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC    ,a.ExchangeUnitsVolume
-- MAGIC    ,a.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC    ,current_timestamp() AS UpdateDate
-- MAGIC              ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Volume_Last10Min a 
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Flag2' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,NULL AS RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,a.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC    ,a.ExchangeUnitsVolume
-- MAGIC    ,a.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC    ,current_timestamp() AS UpdateDate
-- MAGIC              ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Flag2  a
-- MAGIC
-- MAGIC UNION 
-- MAGIC
-- MAGIC SELECT cast('{etr_ymd}' as date) AS  Date
-- MAGIC        ,'Top20_Volume' AS KPI
-- MAGIC        ,a.InstrumentID
-- MAGIC        ,a.InstrumentDisplayName
-- MAGIC 	   ,a.InstrumentType
-- MAGIC 	   ,a.Regulation
-- MAGIC 	   ,a.RN 
-- MAGIC 	   ,a.Volume
-- MAGIC 	   ,a.Units
-- MAGIC 	   ,adk.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC 	   ,b.DailyVolume AS ExchangeUnitsVolume	   
-- MAGIC 	   ,b.MA_10Days
-- MAGIC 	   ,a.MaxToMinChange
-- MAGIC 	   ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM  Yday_Top20_Volume a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC ON  b.InstrumentID = a.InstrumentID
-- MAGIC LEFT JOIN AvgDailyKPIs adk
-- MAGIC ON adk.InstrumentID = a.InstrumentID
-- MAGIC WHERE a.IsLowMktCap = 0
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT  cast('{etr_ymd}' as date) AS  Date
-- MAGIC        ,'Top20_Volume_LowMktCap' AS KPI
-- MAGIC        ,a.InstrumentID
-- MAGIC        ,a.InstrumentDisplayName
-- MAGIC 	   ,a.InstrumentType
-- MAGIC 	   ,a.Regulation
-- MAGIC 	   ,a.RN 
-- MAGIC 	   ,a.Volume
-- MAGIC 	   ,a.Units
-- MAGIC 	   ,adk.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC 	   ,b.DailyVolume AS ExchangeUnitsVolume
-- MAGIC 	   ,b.MA_10Days
-- MAGIC        ,a.MaxToMinChange
-- MAGIC 	    ,current_timestamp() AS UpdateDate
-- MAGIC                ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM  Yday_Top20_Volume a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC  ON b.InstrumentID = a.InstrumentID 
-- MAGIC LEFT JOIN AvgDailyKPIs adk
-- MAGIC ON adk.InstrumentID = a.InstrumentID
-- MAGIC WHERE  a.IsLowMktCap = 1
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Top20_Volume_20Min' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,a.RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,adk.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC    ,b.DailyVolume AS ExchangeUnitsVolume
-- MAGIC    ,b.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC     ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Yday_Top20_Volume_20Min a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC  ON b.InstrumentID = a.InstrumentID 
-- MAGIC LEFT JOIN AvgDailyKPIs adk
-- MAGIC ON adk.InstrumentID = a.InstrumentID
-- MAGIC WHERE   a.IsLowMktCap = 0
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Top20_Volume_20Min_LowMktCap' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,a.RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,adk.AvgDailyVolumeAll AS Last30DaysAvgVolume
-- MAGIC    ,b.DailyVolume AS ExchangeUnitsVolume
-- MAGIC    ,b.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC     ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Yday_Top20_Volume_20Min a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC  ON b.InstrumentID = a.InstrumentID 
-- MAGIC LEFT JOIN AvgDailyKPIs adk
-- MAGIC  ON adk.InstrumentID = a.InstrumentID
-- MAGIC WHERE   a.IsLowMktCap = 1
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Top20_OverAvgVolume' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,a.RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,a.AvgDailyVolume AS Last30DaysAvgVolume
-- MAGIC    ,b.DailyVolume AS ExchangeUnitsVolume
-- MAGIC    ,b.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC     ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Table2 a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC  ON b.InstrumentID = a.InstrumentID 
-- MAGIC WHERE  a.IsLowMktCap = 0
-- MAGIC
-- MAGIC UNION
-- MAGIC
-- MAGIC SELECT
-- MAGIC 	cast('{etr_ymd}' as date) AS Date
-- MAGIC    ,'Top20_OverAvgVolume_LowMktCap' AS KPI
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.Regulation
-- MAGIC    ,a.RN
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,AvgDailyVolume AS Last30DaysAvgVolume
-- MAGIC    ,b.DailyVolume AS ExchangeUnitsVolume
-- MAGIC    ,b.MA_10Days
-- MAGIC    ,a.MaxToMinChange
-- MAGIC     ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC FROM Table2 a
-- MAGIC LEFT JOIN StocksInfo_KPIs b
-- MAGIC  ON b.InstrumentID = a.InstrumentID 
-- MAGIC WHERE  a.IsLowMktCap = 1
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_ManipulationReport_RealStocks) 
-- MAGIC

-- COMMAND ----------

--SELECT * FROM ManipulationReport_RealStocks limit 10

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TradesPerInstrument = f"""
-- MAGIC create or replace temp view TradesPerInstrument as
-- MAGIC SELECT
-- MAGIC 	InstrumentID
-- MAGIC    ,InstrumentDisplayName
-- MAGIC    ,InstrumentType
-- MAGIC    ,COUNT(CASE WHEN tp.OpenDateID = '{etr_ymdID}' AND IFNULL(IsPartialCloseChild,0) = 0 THEN PositionID ELSE NULL END) AS NumberOfTrades
-- MAGIC    ,SUM(tp.Volume) AS Volume
-- MAGIC    ,SUM(tp.Units) AS Units 
-- MAGIC FROM All_Positions_Data tp
-- MAGIC GROUP BY InstrumentID
-- MAGIC 		,InstrumentDisplayName
-- MAGIC 		,InstrumentType
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TradesPerInstrument) 
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_TradesPerCIDAndInstrument = f"""
-- MAGIC create or replace temp view TradesPerCIDAndInstrument as
-- MAGIC SELECT
-- MAGIC 	CID
-- MAGIC    ,tp.UserName
-- MAGIC    ,tp.Country
-- MAGIC    ,tp.Club
-- MAGIC    ,tp.Manager
-- MAGIC    ,tp.Regulation
-- MAGIC    ,InstrumentID
-- MAGIC    ,InstrumentDisplayName
-- MAGIC    ,InstrumentType
-- MAGIC    ,COUNT(CASE WHEN tp.OpenDateID = '{etr_ymdID}' AND IsPartialCloseChild = 0 THEN PositionID ELSE NULL END) AS NumberOfTrades
-- MAGIC    ,SUM(tp.Volume) AS Volume
-- MAGIC    ,SUM(tp.Units) Units 
-- MAGIC FROM All_Positions_Data tp
-- MAGIC GROUP BY CID
-- MAGIC 		,InstrumentID
-- MAGIC 		,InstrumentDisplayName
-- MAGIC 		,InstrumentType
-- MAGIC 		,tp.UserName
-- MAGIC 		,tp.Country
-- MAGIC 		,tp.Club
-- MAGIC 		,tp.Manager
-- MAGIC 		,tp.Regulation
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_TradesPerCIDAndInstrument) 
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_Flags = f"""
-- MAGIC create or replace temp view Flags as
-- MAGIC SELECT DISTINCT
-- MAGIC 	'{etr_ymd}' AS Date
-- MAGIC    ,a.CID
-- MAGIC    ,a.UserName
-- MAGIC    ,a.Country
-- MAGIC    ,a.Manager
-- MAGIC    ,a.Regulation
-- MAGIC    ,a.Club
-- MAGIC    ,a.InstrumentID
-- MAGIC    ,a.InstrumentDisplayName
-- MAGIC    ,a.InstrumentType
-- MAGIC    ,a.NumberOfTrades
-- MAGIC    ,b.NumberOfTrades AS AllTrades
-- MAGIC    ,c.AvgDailyOpen
-- MAGIC    ,a.Volume
-- MAGIC    ,a.Units
-- MAGIC    ,a.NumberOfTrades * 1.00 / NULLIF(c.AvgDailyOpen, 0) AS PercentOfAvg30Days
-- MAGIC    ,a.NumberOfTrades * 1.00 / NULLIF(b.NumberOfTrades, 0) AS PercentOfTotalTrades 
-- MAGIC FROM TradesPerCIDAndInstrument a
-- MAGIC JOIN TradesPerInstrument b
-- MAGIC 	ON a.InstrumentID = b.InstrumentID
-- MAGIC LEFT JOIN AvgDailyKPIs c
-- MAGIC 	ON c.InstrumentID = a.InstrumentID
-- MAGIC 		AND c.Date = '{etr_ymd}'
-- MAGIC WHERE a.NumberOfTrades * 1.00 / NULLIF(b.NumberOfTrades, 0) > 0.5
-- MAGIC OR a.NumberOfTrades * 1.00 / NULLIF(c.AvgDailyOpen, 0) > 2 
-- MAGIC
-- MAGIC       """
-- MAGIC spark.sql(query_create_view_Flags) 
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC
-- MAGIC query_create_view_ManipulationReport_RealStocks_CID = f"""
-- MAGIC create or replace temp view ManipulationReport_RealStocks_CID as
-- MAGIC SELECT Date
-- MAGIC 	   ,CID
-- MAGIC 	   ,UserName
-- MAGIC 	   ,Country
-- MAGIC 	   ,Manager
-- MAGIC 	   ,Regulation
-- MAGIC 	   ,Club
-- MAGIC 	   ,InstrumentID
-- MAGIC 	   ,InstrumentDisplayName
-- MAGIC 	   ,InstrumentType
-- MAGIC 	   ,NumberOfTrades
-- MAGIC 	   ,AllTrades
-- MAGIC 	   ,AvgDailyOpen
-- MAGIC 	   ,Volume
-- MAGIC 	   ,Units
-- MAGIC 	   ,PercentOfAvg30Days
-- MAGIC 	   ,PercentOfTotalTrades
-- MAGIC 	   ,current_timestamp() AS UpdateDate
-- MAGIC               ,'{etr_y}' AS etr_y
-- MAGIC        ,'{etr_ym}' AS etr_ym
-- MAGIC        ,'{etr_ymd}' AS etr_ymd
-- MAGIC 	FROM Flags f 
-- MAGIC
-- MAGIC       """
-- MAGIC df2 = spark.sql(query_create_view_ManipulationReport_RealStocks_CID) 
-- MAGIC

-- COMMAND ----------

--select * from ManipulationReport_RealStocks_CID

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Write to tables**

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df_manipulation_report_real_stocks = spark.table("ManipulationReport_RealStocks")
-- MAGIC
-- MAGIC (df_manipulation_report_real_stocks.write
-- MAGIC     .format("delta")
-- MAGIC     .mode("overwrite")
-- MAGIC     .option("replaceWhere", f"etr_ymd = '{etr_ymd}'")
-- MAGIC     .partitionBy("etr_y", "etr_ym", "etr_ymd")
-- MAGIC     .option("path", "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/BI_OUTPUT/Dealing/Manipulation_Report_Real_Stocks/")
-- MAGIC   #  .option("path", "abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/Dealing/Manipulation_Report_Real_Stocks/")
-- MAGIC     .saveAsTable("bi_dealing.bi_output_dealing_manipulation_report_real_stocks"))
-- MAGIC    # .saveAsTable("bi_dealing_stg.bi_output_dealing_manipulation_report_real_stocks"))

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df_manipulation_report_real_stocks_cid = spark.table("ManipulationReport_RealStocks_CID")
-- MAGIC
-- MAGIC (df_manipulation_report_real_stocks_cid.write
-- MAGIC     .format("delta")
-- MAGIC     .mode("overwrite")
-- MAGIC     .option("replaceWhere", f"etr_ymd = '{etr_ymd}'")
-- MAGIC     .partitionBy("etr_y", "etr_ym", "etr_ymd")
-- MAGIC     .option("path", "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/BI_OUTPUT/Dealing/Manipulation_Report_Real_Stocks_CID/")
-- MAGIC   #  .option("path", "abfss://analysis@stgdpdlwe.dfs.core.windows.net/BI_OUTPUT/Dealing/Manipulation_Report_Real_Stocks_CID/")
-- MAGIC     .saveAsTable("bi_dealing.bi_output_dealing_manipulation_report_real_stocks_cid"))
-- MAGIC   #  .saveAsTable("bi_dealing_stg.bi_output_dealing_manipulation_report_real_stocks_cid"))

