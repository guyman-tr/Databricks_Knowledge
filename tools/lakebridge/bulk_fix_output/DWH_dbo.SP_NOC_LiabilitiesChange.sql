USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_NOC_LiabilitiesChange(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
  
BEGIN

DECLARE V_LiabilitiesChange DOUBLE
;
Set V_LiabilitiesChange = (SELECT cast((Liabilities/LiabilitiesPrev-1)*100 as decimal(8,2)) as LiabilitiesChange
from
(
select DateID, sum(Liabilities) as Liabilities, LAG(sum(Liabilities),1) OVER (ORDER BY DateID) LiabilitiesPrev
from V_Liabilities
where DateID in( CAST(date_format(cast(current_timestamp() - INTERVAL 1 DAY as date), 'yyyyMMdd') AS int),CAST(date_format(cast(DATEADD(day, -1, current_timestamp() - INTERVAL 1 DAY) as date), 'yyyyMMdd') AS int))
group by DateID
) a
where a.DateID = CAST(date_format(cast(current_timestamp() - INTERVAL 1 DAY as date), 'yyyyMMdd') AS int)
);

---print @LiabilitiesChange
IF ABS(V_LiabilitiesChange) >= 20 -- The Change Liabilitie more then 20% 
THEN
Select 'Data Not is correct';
ELSE
Select 'Data is correct';
END IF;
END;
