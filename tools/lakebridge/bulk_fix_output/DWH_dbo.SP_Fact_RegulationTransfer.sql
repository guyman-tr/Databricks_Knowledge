USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_RegulationTransfer(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

	BEGIN



DECLARE V_auxdate  TIMESTAMP
;
DECLARE V_datebefore  TIMESTAMP
;
DECLARE V_dateid  int
;
DECLARE V_beforedateid  int
;
DECLARE V_regcount  int
;
DECLARE V_maxloopdate  TIMESTAMP;
--set @date='2014-04-06'
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table [DWH_dbo].Fact_RegulationTransfer
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2020-05-20      Boris Slutski  Add column InvestedRealStocks
2024-11-24		Daniel Kaplan  Add futures fields : InvestedRealFutures , PositionPnLFuturesReal
2025-10-08      Daniel Kaplan  Add Stock Margin : InvestedStocksMargin,PositionPnLStocksMargin,TotalStockMarginLoanValue

EXEC [DWH_dbo].[SP_Fact_RegulationTransfer]  '20250908'
*********************************************************************************************/

	--declare @date datetime = '20211217'

set V_auxdate=(select DATEADD(day, 1, V_date))
	;
set V_datebefore=(select DATEADD(day, -1, V_date))
	;
set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int)
	;
set V_beforedateid =CAST(date_format(V_datebefore, 'yyyyMMdd') AS int)
	;
set V_maxloopdate=DATEADD(day, DATEDIFF(0, current_timestamp()), 0);

	--drop table if EXISTS #Reg
DROP VIEW IF EXISTS TEMP_TABLE_Reg;

	CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Reg AS
select *,CAST(date_format(cast(Occurred as Date), 'yyyyMMdd') AS int) as EquityDateID
	
	from dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog_All
	where Occurred>=V_date and Occurred<V_auxdate;

	/*if there wasn't any transfer between regualation , skip this day*/
SET V_regcount = (
SELECT
count(*) from TEMP_TABLE_Reg

	 -- CREATE CLUSTERED index IX_tmp on #Reg(EquityDateID,CID)
 LIMIT 1);
IF V_regcount<>0
	THEN
--print 'We have transfers writing into table '++convert(varchar,@date,120)
		/*delete historical data befire inserting new data*/

		delete from dwh_daily_process.migration_tables.Fact_RegulationTransfer
		where DateID=V_dateid;

	
	--	drop table #Equity
DROP VIEW IF EXISTS TEMP_TABLE_Equity;

		CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Equity AS
select *
		
		from dwh_daily_process.migration_tables.V_Liabilities
		where DateID= V_beforedateid;
		 -- CREATE CLUSTERED index IX_Equity on #Equity(DateID,CID)
	insert into dwh_daily_process.migration_tables.Fact_RegulationTransfer
(FromRegulationID
		  ,ToRegulationID
		  ,Occurred
		  ,DateID
		  ,ActualNWA
		  ,RealizedEquity
		  ,CID
		  ,TotalPositionsAmount
		  ,TotalCash
		  ,InProcessCashouts
		  ,TotalMirrorPositionsAmount
		  ,TotalMirrorCash
		  ,TotalStockOrders
		  ,TotalMirrorStockOrders
		  ,Credit
		  ,AUM
		  ,BonusCredit
		  ,TotalLiability
		  ,WithdrawableLiability
		  ,LiabilityInUsedMargin
		  ,UnrealizedPnL
		  ,UpdateDate
		  ,InvestedRealStocks
		  ,InvestedRealCrypto
		  ,PositionPnLStocksReal
		  ,PositionPnLCryptoReal
		  ,InvestedRealFutures
		  ,PositionPnLFuturesReal
		  --2025-10-08 Stock Margin
		  ,InvestedStocksMargin
		  ,PositionPnLStocksMargin
		  ,TotalStockMarginLoanValue
		  )

	SELECT FromRegulationID
		  ,ToRegulationID
		  ,Occurred
		  ,a.DateID
		  ,COALESCE(ActualNWA, 0) as ActualNWA
		  ,COALESCE(RealizedEquity, 0) as RealizedEquity
		  ,a.CID
		  ,COALESCE(TotalPositionsAmount, 0)
		  ,COALESCE(TotalCash, 0)
		  ,COALESCE(InProcessCashouts, 0)
		  ,COALESCE(TotalMirrorPositionsAmount, 0)
		  ,COALESCE(TotalMirrorCash, 0)
		  ,COALESCE(TotalStockOrders, 0)
		  ,COALESCE(TotalMirrorStockOrders, 0)
		  ,COALESCE(Credit, 0)
		  ,COALESCE(AUM, 0)
		  ,COALESCE(BonusCredit, 0)
		  ,COALESCE(Liabilities, 0) as  TotalLiability
		  ,COALESCE(WA_Liabilities, 0)as WithdrawableLiability
		  ,COALESCE(Liabilities_InUsedMargin, 0) as LiabilityInUsedMargin
		  ,COALESCE(PositionPnL, 0)
		 ,current_timestamp()
		 ,COALESCE(`PositionPnLStocksReal`, 0) + COALESCE(`TotalRealStocks`, 0) as InvestedRealStocks
		 ,COALESCE(`PositionPnLCryptoReal`, 0) + COALESCE(`TotalRealCrypto`, 0) as InvestedRealCrypto
		 ,COALESCE(`PositionPnLStocksReal`, 0) as PositionPnLStocksReal
		 ,COALESCE(`PositionPnLCryptoReal`, 0) as PositionPnLCryptoReal
		 ,COALESCE(`PositionPnLFuturesReal`, 0) + COALESCE(`TotalRealFutures`, 0) as InvestedRealFutures
 		 ,COALESCE(`PositionPnLFuturesReal`, 0) as PositionPnLFuturesReal
		 
		  --2025-10-08 Stock Margin
		 ,COALESCE(`PositionPnLStocksMargin`, 0) + COALESCE(`TotalStocksMargin`, 0) as InvestedStocksMargin
		 ,COALESCE(`PositionPnLStocksMargin`, 0) as PositionPnLStocksMargin
		 ,COALESCE(`TotalStockMarginLoanValue`, 0) as TotalStockMarginLoanValue
	  FROM 
	  TEMP_TABLE_Reg a
	  left join 
	  TEMP_TABLE_Equity b
	  on(a.CID=b.CID);
	END IF;

-- END WHILE;

-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_Equity;
DROP VIEW IF EXISTS TEMP_TABLE_Reg;
END;
