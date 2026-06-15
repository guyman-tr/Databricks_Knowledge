USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Test_ExternalToInternal(
IN V_date TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_todayid int
;
DECLARE V_yesterdayid int;
--set @date='20140403'
----set @todayid=convert(int,convert(varchar, @date,112))
----set @yesterdayid=convert(int,convert(varchar, dateadd(day,-1,@date),112))
--declare @date as datetime

set V_todayid=CAST(date_format(DATEADD(day, 1, V_date), 'yyyyMMdd') AS int)
;
set V_yesterdayid= CAST(date_format(V_date, 'yyyyMMdd') AS int);


--drop table #today
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_today AS
select RealCID

from dwh_daily_process.migration_tables.Fact_SnapshotCustomer a
join dwh_daily_process.migration_tables.Dim_Range b
on(a.DateRangeID=b.DateRangeID)
where (PlayerLevelID <> 4 and LabelID<>26) and b.FromDateID<=V_todayid and  b.FromDateID>=V_todayid
group by RealCID,PlayerStatusID;

--drop table #yesterday
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_yesterday AS
select RealCID

from dwh_daily_process.migration_tables.Fact_SnapshotCustomer a
join dwh_daily_process.migration_tables.Dim_Range b
on(a.DateRangeID=b.DateRangeID)
where (PlayerLevelID=4 or LabelID=26) and b.ToDateID<=V_yesterdayid and  b.ToDateID>=V_yesterdayid
group by RealCID,PlayerStatusID
;

select a.RealCID
from TEMP_TABLE_today  a join TEMP_TABLE_yesterday b
on(a.RealCID=b.RealCID)



;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_today;
DROP VIEW IF EXISTS TEMP_TABLE_yesterday;
END;
