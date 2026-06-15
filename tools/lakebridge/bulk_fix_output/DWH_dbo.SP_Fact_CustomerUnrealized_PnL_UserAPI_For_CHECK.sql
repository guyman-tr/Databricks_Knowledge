USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_CustomerUnrealized_PnL_UserAPI_For_CHECK(
IN V_date int,
IN V_profilename STRING,
IN V_fromaddress STRING,
IN V_toaddress STRING,
IN V_message STRING)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_CountRows  bigint  ;
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-07-05
Description: Check if the table Fact_CustomerUnrealized_PnL_UserAPI is empty
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------

*********************************************************************************************/

--DECLARE @date as int = 20190520
----DECLARE @dateID as INT  = CAST(DATEPART(YYYY,@date) AS [CHAR](4))
----       + RIGHT('0' || CAST(DATEPART(M,@date) AS [VARCHAR](2)),2)  
----       + RIGHT('0' || CAST(DATEPART(D,@date) AS [VARCHAR](2)),2);

--select @dateID

SET V_CountRows = (Select count(*) from dwh_daily_process.migration_tables.Fact_CustomerUnrealized_PnL_UserAPI where `DateModified` = V_date);
--if (Select count(*) from Fact_CustomerUnrealized_PnL_UserAPI where [DateModified] = @dateID ) > 0
IF V_CountRows = 0

THEN
SELECT 'No data'

	/*EXEC msdb.[DWH_dbo].sp_send_dbmail

	@profile_name = @profilename,
	@body =@date,
	@from_address = @fromaddress,
	@recipients = @toaddress,
	@subject = @message
	*/
END IF;
END;
