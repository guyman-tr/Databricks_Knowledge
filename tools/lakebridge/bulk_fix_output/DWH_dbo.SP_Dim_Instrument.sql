USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

-- EXEC  [DWH_dbo].[SP_Dim_Instrument] '2024-12-02'
/********************************************************************************************
Author:      
Date:        
Description: 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
24.07.2022	   Inbal BML	Adding MetadataID 9315 in filter in EXTRACT TABLE [Ext_Dim_Instrument_StockInfo_InstrumentData]
30.10.2024     Inbal BML	Adding new cloumns to Dim_Instrument for Future project (IsFuture,Multiplier,ProviderID,ProviderMargin,eToroMargin,SettlementTime)
25.03.2026     Eyal Boas    a temporary fix to handle the type mismatch in the NumVal column   
*********************************************************************************************/
--declare @dt as date = '2024-12-10'

TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Instrument

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Instrument
           (`InstrumentID`
           ,`InstrumentTypeID`
           ,`InstrumentType`
           ,`Name`
           ,`DWHInstrumentID`
           ,`StatusID`
           ,`BuyCurrencyID`
           ,`SellCurrencyID`
           ,`BuyCurrency`
           ,`SellCurrency`
           ,`TradeRange`
           ,`DollarRatio`
           ,`PipDifferenceThreshold`
           ,`IsMajorID`
           ,`IsMajor`
           ,`UpdateDate`
           ,`InsertDate`
           ,`InstrumentDisplayName`
           ,`Industry`
           ,`CompanyInfo`
           ,`Exchange`
           ,`ISINCode`
           ,`ISINCountryCode`
           ,`Tradable`
           ,`Symbol`
           ,`BonusCreditUsePercent`
           ,`SymbolFull`
           ,`CUSIP`
           ,`Precision`
           ,`AllowBuy`
           ,`AllowSell`
           ,`VisibleInternallyOnly`
		   ,`IsFuture`
		   ,`Multiplier`
		   ,`ProviderID`
		   ,`ProviderMarginPerLot`
		   ,`eToroMarginPerLot`
		   ,`SettlementTime`
		   ,`OperationMode`
		   )


SELECT
b.InstrumentID,
b.InstrumentTypeID,
CASE WHEN b.InstrumentTypeID=1 THEN 'Currencies'
WHEN b.InstrumentTypeID=2 THEN 'Commodities'
WHEN b.InstrumentTypeID=4 THEN 'Indices'
WHEN b.InstrumentTypeID=5 THEN 'Stocks'
WHEN b.InstrumentTypeID = 6 THEN 'ETF'
WHEN b.InstrumentTypeID = 10 THEN 'Crypto Currencies'
Else 'Other'
END AS InstrumentType,
b.Name,
b.InstrumentID AS DWHInstrumentID,
1 AS `StatusID`,
b.BuyCurrencyID,
b.SellCurrencyID,
`BuyCurrency`.`Abbreviation` BuyCurrency,
`SellCurrency`.`Abbreviation` SellCurrency,
b.TradeRange,
b.DollarRatio,
b.PipDifferenceThreshold,
b.IsMajor AS `IsMajorID`,
CASE WHEN b.IsMajor = 1 THEN 'Yes' ELSE 'No'
END IsMajor,
current_timestamp() AS UpdateDate,
current_timestamp() AS InsertDate,
InstrumentMetaData.InstrumentDisplayName,
InstrumentMetaData.Industry,
InstrumentMetaData.CompanyInfo,
InstrumentMetaData.Exchange,
InstrumentMetaData.ISINCode,
InstrumentMetaData.ISINCountryCode,
case 
when Tradable in (1,0) then cast(Tradable as int)  
end as Tradable
, Symbol
,pt.BonusCreditUsePercent
,InstrumentMetaData.SymbolFull
,ic.CUSIP
,pt.Precision
,cast(AllowBuy as int) as AllowBuy
,cast(AllowSell as int) as AllowSell
,cast(VisibleInternallyOnly as int) as VisibleInternallyOnly
, case when b.InstrumentID in (select distinct InstrumentID from dwh_daily_process.daily_snapshot.etoro_Trade_InstrumentGroups where GroupID=25) then 1 else 0  end  as IsFuture   ---Inbal 29/10/2024
,fm.Multiplier
,pt.ProviderID
,fii.InitialMargin  as ProviderMarginPerLot
,pt.InitialMarginInAssetCurrency as eToroMarginPerLot
,cast(date_format(EXTRACT(HOUR from SettlementTime)*100 + EXTRACT(MINUTE from SettlementTime)*1, '00:00') as TIMESTAMP) as SettlementTime
,eti.`OperationMode`
FROM
dwh_daily_process.daily_snapshot.etoro_Trade_GetInstrument b
INNER JOIN
dwh_daily_process.daily_snapshot.etoro_Dictionary_Currency `BuyCurrency`
ON b.`BuyCurrencyID` = `BuyCurrency`.`CurrencyID`
INNER JOIN
dwh_daily_process.daily_snapshot.etoro_Dictionary_Currency `SellCurrency`
ON b.`SellCurrencyID` = `SellCurrency`.`CurrencyID`
LEFT JOIN
dwh_daily_process.daily_snapshot.etoro_Trade_InstrumentMetaData as InstrumentMetaData
on b.InstrumentID = InstrumentMetaData.InstrumentID
LEFT JOIN 
dwh_daily_process.daily_snapshot.etoro_Trade_ProviderToInstrument pt 
ON b.InstrumentID = pt.InstrumentID
LEFT JOIN 
dwh_daily_process.daily_snapshot.etoro_Trade_InstrumentCusip ic 
ON b.InstrumentID = ic.InstrumentID
LEFT JOIN  ---Inbal 29/10/2024
dwh_daily_process.daily_snapshot.etoro_Trade_FuturesMetaData fm 
ON b.InstrumentID = fm.InstrumentID
LEFT JOIN  ---Inbal 12/11/2024
dwh_daily_process.daily_snapshot.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping  fii 
ON b.InstrumentID =  fii.InstrumentID
Left join dwh_daily_process.daily_snapshot.etoro_Trade_Instrument eti 
ON eti.`InstrumentID` = b.InstrumentID

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData;
 
 ------ this is a temporary fix to handle the type mismatch in the NumVal column -----
 update dwh_daily_process.daily_snapshot.Rankings_StockInfo_InstrumentData set NumVal = NumVal/1000
where LENGTH(NumVal) > 35;
--------------------------------------------------------------------------------------
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData
           (`InstrumentID`
           ,`Description`
           ,`KeyName`
           ,`NumVal`)
select 
InstrumentID,
sm.Description,
sm.KeyName,
rs.NumVal
FROM dwh_daily_process.daily_snapshot.Rankings_StockInfo_InstrumentData rs 
join dwh_daily_process.daily_snapshot.Rankings_StockInfo_Metadata sm
on rs.MetadataID= sm.MetadataID
where rs.MetadataID in (8557, 8703, 8735, 8444, 9315)


;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData_Platform

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData_Platform
           (`InstrumentID`
           ,`PlatformSector`
           ,`PlatformIndustry`)
SELECT InstrumentID
,Sector AS PlatformSector
,Industry AS PlatformIndustry FROM 
(select InstrumentID, 
MAX(CASE WHEN MetadataID=8436 THEN StrVal END) Sector,
MAX(CASE WHEN MetadataID=8280 THEN StrVal END) Industry
FROM dwh_daily_process.daily_snapshot.Rankings_StockInfo_InstrumentData  
WHERE MetadataID IN (8436 ,8280) 
GROUP BY InstrumentID) a

;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerCurrent

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerCurrent
           (`InstrumentID`
           ,`ReceivedOnPriceServer`)
select InstrumentID,min(ReceivedOnPriceServer) as ReceivedOnPriceServer 
  from dwh_daily_process.daily_snapshot.PriceLog_History_CurrencyPrice_Active
 where 
Occurred>=DATEADD(DAY, -1, cast(current_timestamp() as date)) and Occurred <  cast(current_timestamp() as date)
group by InstrumentID


;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerStatic
           (`InstrumentID`
           ,`ReceivedOnPriceServer`)
select 
a.`InstrumentID`
,a.`ReceivedOnPriceServer`
from 
dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerCurrent a
left join dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerStatic b
on a.InstrumentID = b.InstrumentID
where b.InstrumentID is null

;
MERGE INTO dwh_daily_process.migration_tables.Dim_Instrument A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Instrument a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_ReceivedOnPriceServerStatic b on a.InstrumentID = b.InstrumentID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.InstrumentID ORDER BY 1) = 1
)
ON a.InstrumentID = A_TGT.InstrumentID
WHEN MATCHED THEN UPDATE SET
`ReceivedOnPriceServer` = b.`ReceivedOnPriceServer`;
MERGE INTO dwh_daily_process.migration_tables.Dim_Instrument A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Instrument a
INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_Classification_Static b on a.InstrumentID = b.InstrumentID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.InstrumentID ORDER BY 1) = 1
)
ON a.InstrumentID = A_TGT.InstrumentID
WHEN MATCHED THEN UPDATE SET
AssetClass = b.AssetClass ,
IndustryGroup = b.IndustryGroup;
MERGE INTO dwh_daily_process.migration_tables.Dim_Instrument A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Instrument di
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData ra ON ra.InstrumentID = di.InstrumentID AND ra.KeyName = 'AverageDailyVolumeLast3Months-TTM' --MetadataID=8557

LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData ra2 ON ra2.InstrumentID = di.InstrumentID AND ra2.KeyName = 'MarketCapitalization-TTM' --MetadataID=8735

LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData ra3 ON ra3.InstrumentID = di.InstrumentID AND ra3.KeyName = 'SharesOutstandingCurrent-Annual' --MetadataID=8444

LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData ra4 ON ra4.InstrumentID = di.InstrumentID AND ra4.KeyName = 'LastClose-TTM' --MetadataID=8703

LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData ra5 ON ra5.InstrumentID = di.InstrumentID AND ra5.KeyName = 'CryptoMarketCap' --MetadataID=9315

)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
ADV_Last3Months = ra.NumVal ,
MKTcap = COALESCE(ra2.NumVal, ra5.NumVal) ,
SharesOutStanding = ra3.NumVal;
MERGE INTO dwh_daily_process.migration_tables.Dim_Instrument A_TGT USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Instrument di
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Instrument_StockInfo_InstrumentData_Platform b ON b.InstrumentID = di.InstrumentID
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
PlatformSector = b.`PlatformSector` ,
PlatformIndustry = b.`PlatformIndustry`;
INSERT INTO dwh_daily_process.migration_tables.Dim_Instrument
           (`InstrumentID`
           ,`InstrumentTypeID`
           ,`InstrumentType`
           ,`Name`
           ,`DWHInstrumentID`
           ,`StatusID`
           ,`BuyCurrencyID`
           ,`SellCurrencyID`
           ,`BuyCurrency`
           ,`SellCurrency`
           ,`TradeRange`
           ,`DollarRatio`
           ,`PipDifferenceThreshold`
           ,`IsMajorID`
           ,`IsMajor`
           ,`UpdateDate`
           ,`InsertDate`
           ,`InstrumentDisplayName`
           ,`Industry`
           ,`CompanyInfo`
           ,`Exchange`
           ,`ISINCode`
           ,`ISINCountryCode`
           ,`Tradable`
           ,`Symbol`
           ,`ReceivedOnPriceServer`
           ,`BonusCreditUsePercent`
           ,`SymbolFull`
           ,`CUSIP`
           ,`Precision`
           ,`AllowBuy`
           ,`AllowSell`
           ,`AssetClass`
           ,`IndustryGroup`
           ,`ADV_Last3Months`
           ,`MKTcap`
           ,`SharesOutStanding`
           ,`VisibleInternallyOnly`
           ,`PlatformSector`
           ,`PlatformIndustry`
		   ,`IsFuture`
		   ,`Multiplier`
		   ,`ProviderID`
		   ,`ProviderMarginPerLot`
		   ,`eToroMarginPerLot`
		   ,`SettlementTime`)
     VALUES
		  (
		 0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,NULL	
		,0	
		,0	
		,'NA'	
		,'NA'	
		,0	
		,0	
		,0	
		,0	
		,'NA'	
		,NULL	
		,NULL	
		,'NA'	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL	
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		,NULL
		  )

;
call dwh_daily_process.migration_tables.SP_Dim_Instrument_Snapshot(V_dt);
END;
