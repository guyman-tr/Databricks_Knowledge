USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK(
IN V_date TIMESTAMP,
IN V_profilename STRING,
IN V_fromaddress STRING,
IN V_toaddress STRING,
IN V_message STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_Table STRING
;
DECLARE V_body STRING;
/*		SET @Table = CAST(( 
		SELECT Msg AS "td",'',
			   ProviderID AS "td",'',
			   InstrumentID AS "td",'',
			   DateFrom AS "td",'',
			   AskLast AS "td",'',
			   BidLast AS "td",''
		FROM #FinalTable FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @body =
		'<html><body><H2>Candle Price has been changed - Information</H2>
		<table border = 1 > 
		<th> Msg </th> 
		<th> ProviderID </th> 
		<th> InstrumentID </th> 
		<th> DateFrom </th> 
		<th> AskLast </th> 
		<th> BidLast </th> 
		</tr>'


		SET @body = @body + @Table +'</table></body></html>'

 		EXEC msdb.[DWH_dbo].sp_send_dbmail

		@profile_name = @profilename,
		@body = @body,
		@body_format ="HTML",
		@from_address = @fromaddress,
		@recipients = @toaddress,
		@subject = @message
	*/
/********************************************************************************************
Author:      Boris Slutski
Date:        2019-11-05
Description: Found change in Candle Price Table
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/


--DECLARE @date AS DATETIME='20191104'

--drop table If EXISTS #Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK

DROP VIEW IF EXISTS TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK AS
select *
 
FROM(
select *, row_number() OVER (PARTITION BY InstrumentID, cast(DateFrom as date) ORDER BY DateFrom DESC) rn
from dwh_daily_process.migration_tables.Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK
where DateFrom >=DATEADD(day, DATEDIFF(7, V_date), 0)  
) a
where rn =1;

--drop table If EXISTS #Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore
DROP VIEW IF EXISTS TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore AS
select *

FROM(
select *, row_number() OVER (PARTITION BY InstrumentID, cast(DateFrom as date) ORDER BY DateFrom DESC) rn
from dwh_daily_process.migration_tables.Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore
) a
where rn =1;

--drop table If EXISTS #FinalTable
DROP VIEW IF EXISTS TEMP_TABLE_FinalTable;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_FinalTable AS
Select * 

From 
((
select 'InTableDestination_NoMatchInTableSource' as Msg, `ProviderID`
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
,`BidMaxOccurred` from TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK
except
select 'InTableDestination_NoMatchInTableSource' , `ProviderID`
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
,`BidMaxOccurred` from TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore
)
union all
(
select 'InTableSource_NoMatchInTableDestination' as Msg, `ProviderID`
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
,`BidMaxOccurred` from TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK_DaysBefore
except
select 'InTableSource_NoMatchInTableDestination' ,`ProviderID`
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
,`BidMaxOccurred` from TEMP_TABLE_Fact_GetSpreadedPriceCandle60MinSplitted_For_CHECK
)) a;

--select Msg, ProviderID,InstrumentID,DateFrom,AskLast,BidLast from #FinalTable
IF (select count(*) from TEMP_TABLE_FinalTable) > 0

THEN

END IF;
END;
