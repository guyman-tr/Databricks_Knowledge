USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Report_ASIC_GetCustomerData(
IN V_DateKey int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




	SELECT 
		 COALESCE(a.RealCID, 0) as RealCID
		--,isnull(a.LabelID,0) as LabelID
		--,isnull(a.RegulationID,0) as RegulationID
		--,isnull(a.PlayerLevelID,0) as PlayerLevelID
		--,a.CountryID
		--,a.DateID
	FROM V_Customers a   
	WHERE a.RegulationID = 4 -- ASIC
	AND a.PlayerLevelID <> 4 -- Internal ???
	AND a.LabelID = 11
	AND a.DateID = V_DateKey
;
END;
