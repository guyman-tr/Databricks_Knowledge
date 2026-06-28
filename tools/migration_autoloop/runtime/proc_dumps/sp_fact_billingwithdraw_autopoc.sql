BEGIN

DECLARE V_dateID int  ;

DECLARE V_dt1 TIMESTAMP    
;
DECLARE V_flag int;

SET V_dateID = cast(date_format(V_date, 'yyyyMMdd') AS INT)
;
SET V_flag = 0    
;
WHILE V_flag < 0    
DO
set V_flag=0;
----Flag 1-------------------------------------- 
SET V_dt1 = (
SELECT
MAX(UpdateDate) FROM dwh_daily_process.migration_tables.Dim_CountryBin

 LIMIT 1);
SELECT V_dt1    
   
	;
IF V_dt1>=cast( current_timestamp() as date) THEN
SET V_flag=V_flag+1;
END IF;
SELECT V_flag    
   
;
-- [stub] IF V_flag = 1 BREAK ELSE -> collapsed (WHILE condition exits naturally)
call dwh_daily_process.migration_tables.WaitforSeconds(60);
END WHILE  ;
-- [stub] MERGE INTO ... USING (broken `_tgt` references) elided -- Synapse stats/PK rebuild has no UC equivalent

END