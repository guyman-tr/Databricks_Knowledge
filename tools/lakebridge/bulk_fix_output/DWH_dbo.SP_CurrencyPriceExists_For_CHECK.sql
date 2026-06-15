USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_CurrencyPriceExists_For_CHECK(
IN V_profilename STRING,
IN V_fromaddress STRING,
IN V_toaddress STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_date date ;

DECLARE V_dateID int ;

DECLARE V_CountRows  bigint  ;

DECLARE V_Table STRING
;
DECLARE V_body STRING;
/*	SET @Table = CAST(( 
	SELECT InstrumentID AS "td",'',
		   Name AS "td",'',
		   Count_Rows AS "td",''
	FROM #Data 
	FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

	SET @body =
	'<html><body><H2>Traded Instrument without Prices - Information</H2>
	<table border = 1 > 
	<th> InstrumentID </th> 
	<th> Name </th> 
	<th> Count_Rows </th> 
	</tr>'    

	SET @body = @body + @Table +'</table></body></html>'

	EXEC msdb.[DWH_dbo].sp_send_dbmail

	@profile_name = @profilename,
	@body = @body,
	@body_format ="HTML",
	@from_address = @fromaddress,
	@recipients = @toaddress,
	@subject = 'Traded Instrument without Prices - Information'

*/
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-07-05
Description: Check if the table CurrencyPriceExists 
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/

SET V_date = cast(current_timestamp() - INTERVAL 1 DAY AS date)
;
SET V_dateID = cast(date_format(V_date, 'yyyyMMdd') AS INT);
--drop table if exists #Position

DROP VIEW IF EXISTS TEMP_TABLE_Position;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Position AS
select InstrumentID,Count(*) as Count_Rows

from 
dwh_daily_process.migration_tables.Dim_Position
where OpenDateID = V_dateID 
group by InstrumentID;

--drop table if exists #CurrencyPriceWithSplit
DROP VIEW IF EXISTS TEMP_TABLE_CurrencyPriceWithSplit;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_CurrencyPriceWithSplit AS
SELECT 
Distinct InstrumentID 

from 
dwh_daily_process.migration_tables.Fact_CurrencyPriceWithSplit
where Occurred>=V_date;

--drop table if exists #Data
DROP VIEW IF EXISTS TEMP_TABLE_Data;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Data AS
select a.InstrumentID,i.Name, Count_Rows  

from TEMP_TABLE_Position a
left join TEMP_TABLE_CurrencyPriceWithSplit b
on a.InstrumentID = b.InstrumentID
left join dwh_daily_process.migration_tables.Dim_Instrument i
on a.InstrumentID = i.InstrumentID
where b.InstrumentID is null


;
SET V_CountRows = (Select count(*) from TEMP_TABLE_Data)
;
IF V_CountRows > 0

THEN

END IF;
END;
