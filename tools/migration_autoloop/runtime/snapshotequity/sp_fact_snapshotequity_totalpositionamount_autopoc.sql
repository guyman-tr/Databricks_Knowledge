BEGIN



DECLARE V_dateID INT ;

DECLARE V_row_count INT 
;
DECLARE V_rowcount INT  
;/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table Fact_CustomerAction
 
**************************
** Change History
**************************
Date            Description Author                             Author   
----------     ---------------------------------------------   -----------
--20140417    |   add "with (nolock)" to HistoryActive Credit| Lior Baber | 27 
--20140915    |   change to work on DWH                      | Max
--20170814    | Add Crypto & update Stokcs                   | Katy F
20200325       use column  InitialAmount for TotalRealCryptoLoan  Boris
############20200707      chanhe calculation on Amount 
27/01/2022    |   add SettlementTypeID and TRS fileds							 | Inbal BML 
30/10/2024    |   change TotalStockPositionAmount and TotalMirrorStockPositionAmount fileds| Daniel Kaplan
			  Add futures fields :TotalMirrorRealFuturesPositionAmount,TotalRealFutures,TotalFuturesProviderMargin,TotalFuturesLockedCash  | Daniel Kaplan
2025-07-29	  | Add logic remove the cross over between Real Future Crypto and Stocks and crypto and stocks metrics. they need to be correctly mutually exclusive | Guy M
29/09/2025     Daniel K      add Stock Margin :TotalStocksMargin,TotalStockMarginLoanValue
10/12/2025     Daniel K      change a TotalStockMarginLoanValue calculating - using a InitConversionRate 

*********************************************************************************************/
-- EXEC [DWH_dbo].[SP_Fact_SnapshotEquity_TotalPositionAmount] '2025-07-16'

  --Declare @TargetDate datetime = '2024-12-05'
  
SET V_dateID = CAST(date_format(V_TargetDate, 'yyyyMMdd') AS int)
;
MERGE INTO dwh_daily_process.migration_tables.Ext_FSE_Trade_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FSE_Trade_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog b on a.PositionID = b.PositionID

QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
	MERGE INTO dwh_daily_process.migration_tables.Ext_FSE_History_Position a_TGT
USING (
SELECT * 
from dwh_daily_process.migration_tables.Ext_FSE_History_Position a
INNER JOIN dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog b on a.PositionID = b.PositionID -----*********************
 ------------	    update  Ext_FSE_Trade_Position
 ------------	set TotalPositions = b.PreviousAmount
 ------------	from Ext_FSE_Trade_Position a 
 ------------	join Ext_FSE_PositionChangeLog_Amount b
 ------------	on a.PositionID = b.PositionID
 ------------	update  Ext_FSE_History_Position
 ------------	set TotalPositions = b.PreviousAmount
 ------------	from Ext_FSE_History_Position a 
 ------------	join Ext_FSE_PositionChangeLog_Amount b
 ------------	on a.PositionID = b.PositionID
 ------------  drop table if EXISTS #PositionAmount
 --------------if @trialnum=1 begin
 ------------select a.*
 ------------      ,isnull(convert(decimal(16,2),a.TotalPositions),0)
 ------------	  as NewAmount
 ------------      ,getdate() as updatedate
 ------------	  into #PositionAmount
 ------------from 
 ------------(
 ------------select * from Ext_FSE_Trade_Position
 ------------union all
 ------------select * from Ext_FSE_History_Position
 ------------) a
 -- drop table if EXISTS #PositionAmount


QUALIFY ROW_NUMBER() OVER (PARTITION BY a.PositionID ORDER BY 1) = 1
)
ON a.PositionID = a_TGT.PositionID
WHEN MATCHED THEN UPDATE SET
IsSettled = CAST(b.PreviousIsSettled AS INT);
DROP VIEW IF EXISTS TEMP_TABLE_PositionAmount;
--if @trialnum=1 begin

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PositionAmount AS
select a.*
      ,COALESCE(CAST(a.TotalPositions AS decimal(16,2)), 0)-COALESCE(b.Amount, 0) as NewAmount
      ,current_timestamp() as updatedate
	  
from 
(
select * from dwh_daily_process.migration_tables.Ext_FSE_Trade_Position
union all
select * from dwh_daily_process.migration_tables.Ext_FSE_History_Position
) a
left join dwh_daily_process.migration_tables.Ext_FSE_History_Credit b
on(a.PositionID=b.PositionID);
--end



--------------------------#futures--------------------------
DROP VIEW IF EXISTS TEMP_TABLE_futures;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_futures  
 AS
SELECT InstrumentID,IsFuture,ProviderMarginPerLot
from dwh_daily_process.migration_tables.Dim_Instrument_Snapshot
where IsFuture = 1
AND DateID = V_dateID
;
call `dbo`.`LastRowCount`( 'futures' , V_row_count

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
DROP VIEW IF EXISTS TEMP_TABLE_a;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_a AS
select PositionID,NewAmount,InstrumentID,MirrorID,CID,CAST(IsSettled AS INT), InstrumentTypeID,Leverage,ParentPositionID, InitialAmount, SettlementTypeID,LotCountDecimal,
	   InitForexRate,AmountInUnitsDecimal,InitConversionRate,count(*) as ntimes

from TEMP_TABLE_PositionAmount
group by PositionID,NewAmount,InstrumentID,MirrorID,CID,CAST(IsSettled AS INT), InstrumentTypeID,Leverage,ParentPositionID,InitialAmount, SettlementTypeID,LotCountDecimal,InitForexRate,AmountInUnitsDecimal,InitConversionRate


;
TRUNCATE table dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount


;
INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount
           (`CID`
           ,`TotalPositionAmount`
           ,`TotalMirrorPositionAmount`
           ,`TotalStockPositionAmount`
           ,`TotalMirrorStockPositionAmount`
           ,`TotalCryptoPositionAmount`
           ,`TotalMirrorCryptoPositionAmount`
           ,`TotalRealStocks`
           ,`TotalRealCrypto`
		   ,`TotalRealCryptoLoan`
		   ,`UpdateDate`
		   ,`TotalCryptoPositionAmount_TRS`
		   ,`TotalMirrorCryptoPositionAmount_TRS`
		   ,`Total_TRSCrypto`
------------------Futures------------------
		   ,`TotalMirrorRealFuturesPositionAmount`
		   ,`TotalRealFutures`
		   ,`TotalFuturesProviderMargin`
		   ,`TotalFuturesLockedCash`
			--2025-09-29 Stock Margin
		   ,`TotalStocksMargin`
		   ,`TotalStockMarginLoanValue`
)
select CID
     ,cast(sum(NewAmount) as decimal(16,2)) as TotalPositionAmount
	 ,cast(sum(case when MirrorID>0 AND COALESCE(ParentPositionID, 0) <> 0  then NewAmount else 0 end) as decimal(16,2)) as TotalMirrorPositionAmount
	 ,cast(sum(case when InstrumentTypeID in (5,6) AND f.InstrumentID IS null then NewAmount else 0 end) as decimal(16,2)) as TotalStockPositionAmount -- guy 2025-07-16
	 ,cast(sum(case when InstrumentTypeID in (5,6) AND f.InstrumentID IS NULL and MirrorID>0 AND COALESCE(ParentPositionID, 0) <> 0 then NewAmount else 0 end) as decimal(16,2)) as TotalMirrorStockPositionAmount -- guy 2025-07-16
	 ,cast(sum(case when InstrumentTypeID in(10) AND f.InstrumentID IS null  then NewAmount else 0 end) as decimal(16,2)) as TotalCryptoPositionAmount -- guy 2025-07-16
	 ,cast(sum(case when InstrumentTypeID in(10) AND f.InstrumentID IS null and MirrorID>0 AND COALESCE(ParentPositionID, 0) <> 0 then NewAmount else 0 end)  as decimal(16,2)) as TotalMirrorCryptoPositionAmount -- guy 2025-07-16
	-- ,@TargetDate as DateModified
	,cast(sum(case when IsSettled = 1 and InstrumentTypeID in(5,6) AND f.InstrumentID IS null then NewAmount else 0 end) as decimal(16,2)) as TotalRealStocks -- guy 2025-07-16
	,cast(sum(case when IsSettled = 1 and InstrumentTypeID in(10) AND f.InstrumentID IS null then NewAmount else 0 end) as decimal(16,2)) as TotalRealCrypto -- guy 2025-07-16
	,cast(sum(case when IsSettled = 1 and InstrumentTypeID in(10) AND f.InstrumentID IS null And Leverage =2 then InitialAmount else 0 end) as decimal(16,2)) as TotalRealCryptoLoan -- guy 2025-07-16
	,current_timestamp() as UpdateDate
	,cast(sum(case when InstrumentTypeID in(10) and SettlementTypeID=2  AND f.InstrumentID IS null  then NewAmount else 0 end) as decimal(16,2)) as TotalCryptoPositionAmount_TRS -- guy 2025-07-16
	,cast(sum(case when InstrumentTypeID in(10) and MirrorID>0 AND f.InstrumentID IS null AND COALESCE(ParentPositionID, 0) <> 0 and  SettlementTypeID=2 then NewAmount else 0 end)  as decimal(16,2)) as TotalMirrorCryptoPositionAmount_TRS -- guy 2025-07-16
	,cast(sum(case when IsSettled = 0 and InstrumentTypeID in(10)  and  SettlementTypeID=2 then NewAmount else 0 end) as decimal(16,2)) as Total_TRSCrypto
------------------Futures------------------
	,sum(case when f.IsFuture = 1 and MirrorID > 0 then NewAmount else 0 end) as TotalMirrorRealFuturesPositionAmount
	,sum(case when f.IsFuture = 1 then NewAmount else 0 end) as TotalRealFutures
	,sum(case when f.IsFuture = 1 then LotCountDecimal * f.ProviderMarginPerLot else 0 end) as TotalFuturesProviderMargin
	,sum(case when f.IsFuture = 1 then NewAmount - (LotCountDecimal * f.ProviderMarginPerLot) else 0 end) as TotalFuturesLockedCash
------------------Futures------------------
------------------2025-09-29 Stock Margin------------------
	,sum(case when SettlementTypeID = 5 then NewAmount else 0 end) as TotalStocksMargin
	,sum(case when SettlementTypeID = 5 and Leverage <> 1 then InitForexRate*AmountInUnitsDecimal*InitConversionRate-NewAmount else 0 END) as TotalStockMarginLoanValue
	--,sum(case when SettlementTypeID = 5 and Leverage <> 1 then Leverage * InitForexRate * AmountInUnitsDecimal / (Leverage-1) else 0 END) as TotalStockMarginLoanValue
from (
select *,row_number() over(Partition By PositionID order by ntimes desc) as rn--, getdate() as UpdateDate
 from TEMP_TABLE_a
) a 
left join TEMP_TABLE_futures f
	ON a.InstrumentID = f.InstrumentID
where rn =1
group by CID--,UpdateDate
;

-- [stub] SELECT V_row_count = row_count FROM sys.dm_pdw_* elided -- Synapse monitoring no-op in Databricks
SET V_row_count = 0;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_PositionAmount;
DROP VIEW IF EXISTS TEMP_TABLE_a;
DROP VIEW IF EXISTS TEMP_TABLE_futures;
END