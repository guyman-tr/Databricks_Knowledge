USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Check_PnLInDollars_in_DWH_staging_etoro_Trade_OpenPositionEndOfDay(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
   

/********************************************************************************************        
Author:      Daniel Kaplan         
Date:        2024-02-10        
Description: this proc to check a PnLInDollars in dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay table
        
**************************        
** Change History        
**************************        
Date        Author        Description         
     
10.03.2024  Daniel Kaplan  create SP , running from SP_Dim_Position_DL_To_Synapse  
----------    ----------   ------------------------------------  
*/  
-- exec [DWH_dbo].[SP_Check_PnLInDollars_in_DWH_staging_etoro_Trade_OpenPositionEndOfDay] 

BEGIN


	
DECLARE V_v_PnLInDollars DECIMAL(26,6) 
;
DECLARE V_v_error_message STRING 
;
--DECLARE @date DATE = DATEADD(DAY,-1,GETDATE()) 


SET V_v_PnLInDollars = (
SELECT
sum(COALESCE(PnLInDollars, 0)) from dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay
 LIMIT 1);

	select V_v_PnLInDollars 
		
	;
IF COALESCE(V_v_PnLInDollars, 0) = 0
	THEN
set V_v_error_message = 'We have a PnLInDollars = 0 in dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay';

		select V_v_error_message
		;
RESIGNAL
	;
END IF;
	ELSE


		select 'PnLInDollars in dwh_daily_process.daily_snapshot.etoro_Trade_OpenPositionEndOfDay is OK and it"s equal to ' || CAST(V_v_PnLInDollars as STRING)
;
END;
