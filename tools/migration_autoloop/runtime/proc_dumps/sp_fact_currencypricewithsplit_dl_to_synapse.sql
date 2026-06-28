BEGIN



DECLARE V_DateID int ;

DECLARE V_CountRowsSplit  int
;
-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse] '20211201'

--DATE          NAME                    CHANGE DETAILES 

--2022-04-27     Inbal BML & Adi F       replace  [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView] with [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInsHistory]
--2023-02-26	 MeravHu				 Add ConvertRateIsBuy_1 , ConvertRateIsBuy_0
--2023-03-09	 MeravHu				 Bugfix	
-- =============================================
--DECLARE @dt [Date] = '2021-12-10'

SET V_DateID = cast(date_format(cast(V_dt AS date), 'yyyyMMdd') as INT) 
;
DELETE from dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit
where
OccurredDateID = V_DateID



;
INSERT INTO dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit
           (ProviderID
           ,InstrumentID
           ,Occurred
           ,OccurredDate
           ,OccurredDateID
           ,isvalid
           ,AskSpreaded
           ,BidSpreaded
           ,RateLastEx
           ,Ask
           ,Bid
           ,UpdateDate
      )
SELECT
ProviderID
      ,InstrumentID
      ,Occurred
      ,OccurredDate
      ,OccurredDateID
      ,isvalid
      ,AskSpreaded
      ,BidSpreaded
      ,RateLastEx
      ,Ask
      ,Bid
,current_timestamp() as UpdateDate
FROM dwh_daily_process.daily_snapshot.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView


;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCPWS_History_SplitRatio

;
INSERT INTO dwh_daily_process.migration_tables.Ext_FCPWS_History_SplitRatio
           (InstrumentID
           ,MinDate
           ,MaxDate
           ,PriceRatio
           ,AmountRatio)
select InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio
from dwh_daily_process.daily_snapshot.etoro_History_SplitRatio  
where MinDate>= V_dt and MinDate <  DATEADD(day, 1, V_dt)

;
SET V_CountRowsSplit = (
SELECT
count(*) from dwh_daily_process.migration_tables.Ext_FCPWS_History_SplitRatio

 LIMIT 1);
IF  V_CountRowsSplit> 0
	THEN

DROP VIEW IF EXISTS TEMP_TABLE_SplitInstrument;

		CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_SplitInstrument AS
select Distinct InstrumentID 
		
		from dwh_daily_process.migration_tables.Ext_FCPWS_History_SplitRatio


		;
DROP VIEW IF EXISTS TEMP_TABLE_ConvertRateIsBuy;
DROP VIEW IF EXISTS TEMP_TABLE_ConvertRateIsBuy_all;

			CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ConvertRateIsBuy_all AS
select distinct a.InstrumentID, a.OccurredDateID, a.ConvertRateIsBuy_1 , a.ConvertRateIsBuy_0
			,ROW_NUMBER() OVER(PARTITION BY a.OccurredDateID ORDER BY a.ConvertRateIsBuy_1 desc ) RowNumber
			 
			from dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit  a 
			join TEMP_TABLE_SplitInstrument b on a.InstrumentID=b.InstrumentID 
		;

			CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_ConvertRateIsBuy AS
select  a.InstrumentID, a.OccurredDateID, a.ConvertRateIsBuy_1 , a.ConvertRateIsBuy_0
			
			from TEMP_TABLE_ConvertRateIsBuy_all a
			where RowNumber=1
		
		
;
		DELETE FROM dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit 
		where InstrumentID in 
		(select  InstrumentID from TEMP_TABLE_SplitInstrument)
		
;
		INSERT INTO dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit
		           (ProviderID
		           ,InstrumentID
		           ,Occurred
		           ,OccurredDate
		           ,OccurredDateID
		           ,isvalid
		           ,AskSpreaded
		           ,BidSpreaded
		           ,RateLastEx
		           ,Ask
		           ,Bid
		           ,ConvertRateIsBuy_1 
				   ,ConvertRateIsBuy_0
				   ,UpdateDate
				 
				   
		)
		SELECT distinct
		ProviderID
		      ,a.InstrumentID
		      ,Occurred
		      ,OccurredDate
		      ,a.OccurredDateID
		      ,isvalid
		      ,AskSpreaded
		      ,BidSpreaded
		      ,RateLastEx
		      ,Ask
		      ,Bid
			  ,ConvertRateIsBuy_1
			  ,ConvertRateIsBuy_0
		,current_timestamp() as UpdateDate
		FROM dwh_daily_process.daily_snapshot.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory a
		left join TEMP_TABLE_ConvertRateIsBuy b  on a.InstrumentID=b.InstrumentID and a.OccurredDateID=b.OccurredDateID
		--[DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView]
		where a.InstrumentID in 
		(
		select Distinct InstrumentID
		from dwh_daily_process.daily_snapshot.etoro_History_SplitRatio  
		where MinDate>=V_dt and MinDate <  DATEADD(day, 1, V_dt)
		
		--select InstrumentID from #SplitInstrument
		)
	
	;
END IF;

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FCPWS_Instrument


;
INSERT INTO dwh_daily_process.migration_tables.Ext_FCPWS_Instrument
           (InstrumentID
           ,BuyCurrencyID
           ,SellCurrencyID)
SELECT
b.InstrumentID,
b.BuyCurrencyID,
b.SellCurrencyID
FROM
dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
;
MERGE INTO dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit a_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit a
INNER JOIN dwh_daily_process.migration_tables.Ext_FCPWS_Instrument Pair ON a.InstrumentID = Pair.InstrumentID
LEFT JOIN dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit PairPrice ON Pair.InstrumentID = PairPrice.InstrumentID AND PairPrice.OccurredDateID = V_DateID
LEFT JOIN dwh_daily_process.migration_tables.Ext_FCPWS_Instrument I2 ON I2.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
 AND I2.SellCurrencyID = Pair.SellCurrencyID AND I2.BuyCurrencyID = 1 -- USD

LEFT JOIN dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit I2Price ON I2Price.InstrumentID = I2.InstrumentID AND I2Price.OccurredDateID = V_DateID
LEFT JOIN dwh_daily_process.migration_tables.Ext_FCPWS_Instrument I3 ON I3.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
 AND I3.BuyCurrencyID = Pair.SellCurrencyID AND I3.SellCurrencyID = 1 -- USD

LEFT JOIN dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit I3Price ON I3Price.InstrumentID = I3.InstrumentID AND I3Price.OccurredDateID = V_DateID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.InstrumentID ORDER BY 1) = 1
)
ON a.InstrumentID = a_TGT.InstrumentID
WHEN MATCHED THEN UPDATE SET
ConvertRateIsBuy_1 = cast ( CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN ( 1.00 / a.Bid ) -- IsBuy = 1
 WHEN ( Pair.BuyCurrencyID <> 1 AND Pair.SellCurrencyID <> 1 ) THEN coalesce ( 1.00 / I2Price.Bid , I3Price.Bid , 1.00 ) -- IsBuy = 1
 END AS DECIMAL ( 19 , 4 ) ) ,
ConvertRateIsBuy_0 = cast ( CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN ( 1.00 / a.Ask ) -- IsBuy = 0
 WHEN ( Pair.BuyCurrencyID <> 1 AND Pair.SellCurrencyID <> 1 ) THEN coalesce ( 1.00 / I2Price.Ask , I3Price.Ask , 1.00 ) -- IsBuy = 0
 END AS DECIMAL ( 19 , 4 ) );
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_ConvertRateIsBuy;
DROP VIEW IF EXISTS TEMP_TABLE_ConvertRateIsBuy_all;
DROP VIEW IF EXISTS TEMP_TABLE_SplitInstrument;
END