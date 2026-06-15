USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_GetSpreadedPriceCandle60MinSplitted(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted


;
INSERT INTO dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted
(`ProviderID`
,`InstrumentID`
,`DateFrom`
,`DateTo`
,`AskFirst`
,`AskLast`
,`AskMin`
,`AskMax`
,`BidFirst`
,`BidLast`
,`BidMin`
,`BidMax`
,`AskFirstOccurred`
,`AskLastOccurred`
,`AskMinOccurred`
,`AskMaxOccurred`
,`BidFirstOccurred`
,`BidLastOccurred`
,`BidMinOccurred`
,`BidMaxOccurred`
,`UpdateDate`
)
select 
`ProviderID`
,`InstrumentID`
,`DateFrom`
,`DateTo`
,`AskFirst`
,`AskLast`
,`AskMin`
,`AskMax`
,`BidFirst`
,`BidLast`
,`BidMin`
,`BidMax`
,`AskFirstOccurred`
,`AskLastOccurred`
,`AskMinOccurred`
,`AskMaxOccurred`
,`BidFirstOccurred`
,`BidLastOccurred`
,`BidMinOccurred`
,`BidMaxOccurred`
, current_timestamp() as UpdateDate
FROM  dwh_daily_process.daily_snapshot.PriceLog_Candles_GetSpreadedPriceCandle60MinSplitted
;
MERGE INTO dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_GetSpreadedPriceCandle60MinSplitted A
INNER JOIN dwh_daily_process.migration_tables.Dim_Instrument I ON I.InstrumentID = A.InstrumentID
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
BuyCurrencyID = I.BuyCurrencyID ,
SellCurrencyID = I.SellCurrencyID;
END;
