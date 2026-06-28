BEGIN


DECLARE V_Date TIMESTAMP
;
DECLARE V_Date_int int ;

DECLARE V_CurrentDate TIMESTAMP
;
--feature/Fact_RegulationTransfer -adf
-- =============================================
-- Author:     Daniel Kaplan
-- Create Date: 2021-09-24
-- Description: SP intended to transfer data from DataLake to synapse
-- =============================================
--EXEC [DWH_dbo].[SP_Fact_RegulationTransfer_DL_To_Synapse] '2022-01-20'

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    

	--DECLARE @dt as [Date] = '2021-10-01'

SET V_Date_int = cast(date_format(V_dt, 'yyyyMMdd') AS int);
--DECLARE @MinDate as DATETIME
--DECLARE @MaxDate as DATETIME
SET V_CurrentDate = cast(DATEADD(day, DATEDIFF(-1, V_dt), 0) as date);

--SELECT
--       [FromDate] AS @MinDate
--      ,[TillDate] AS @MaxDate
--      ,DATEADD(year, DATEDIFF(year, -1,  [FromDate]), 0) as FirstDayNextYear
--  FROM [DWH_dbo].[DataSolutionsTablesDate](nolock)


--Sequence Container - Fact_RegulationTransfer
Delete
from dwh_daily_process.migration_tables.Fact_RegulationTransfer 
WHERE DateID >= V_Date_int;
--DateID >= convert(int, replace(cast(@MinDate as date), '-', ''))
--AND DateID < convert(int, replace(cast(@MaxDate as date), '-', ''))



-- Truncate Ext_FRT_BackOffice_RegulationChangeLog --------------------------------------->
TRUNCATE table dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog;
----------------------
DROP VIEW IF EXISTS TEMP_TABLE_etoro_History_BackOfficeCustomer;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_etoro_History_BackOfficeCustomer AS
Select  *
  -- Move duplicates rows, because two parquet files with another dates
from
(
select
CID,
RegulationID,
ValidFrom,
ValidTo,
CustomerHistoryID,
ROW_NUMBER() over (partition by a.CID, CustomerHistoryID  order by a.ValidTo ) as rn
from dwh_daily_process.daily_snapshot.etoro_History_BackOfficeCustomer a 
) a
where  rn =1;

-------------
	
-- Extract Ext_FRT_BackOffice_RegulationChangeLog
INSERT INTO dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog
SELECT
RegulationChangeID,
CID,
Occurred,
FromRegulationID,
ToRegulationID,
DateID
from
(
select
100000 as RegulationChangeID,
a.CID,
MAX(b.Max_ValidFrom) as Occurred,
COALESCE(c.RegulationID, 0)  as FromRegulationID,
COALESCE(a.RegulationID, 0) as ToRegulationID,
CAST(date_format(DATEADD(day, 0, b.Max_ValidFrom), 'yyyyMMdd') AS int) as DateID,
ROW_NUMBER() over (partition by a.CID order by a.ValidTo desc) as rn,a.ValidTo
from TEMP_TABLE_etoro_History_BackOfficeCustomer a 
--[DWH_staging].[etoro_History_BackOfficeCustomer] a with (nolock)
--from [History].[BackOfficeCustomer] a with (nolock)
join
(
SELECT CID, MAX(ValidFrom) AS Max_ValidFrom, MAX(ValidTo) AS Max_ValidTo
from TEMP_TABLE_etoro_History_BackOfficeCustomer  
--[DWH_staging].[etoro_History_BackOfficeCustomer] with (nolock)
--FROM [History].[BackOfficeCustomer] with (nolock)
where 
ValidFrom  >= V_dt
and ValidFrom < V_CurrentDate
GROUP BY CID
) b
on a.CID=b.CID  and a.ValidFrom = b.Max_ValidFrom and a.ValidTo = b.Max_ValidTo
join
(
SELECT a.CID , b.Max_ValidFrom, b.Max_ValidTo, RegulationID
from TEMP_TABLE_etoro_History_BackOfficeCustomer a 
--[DWH_staging].[etoro_History_BackOfficeCustomer] a (nolock)
--FROM [History].[BackOfficeCustomer] a with (nolock)
join
(
SELECT CID, max(ValidFrom) AS Max_ValidFrom, max(ValidTo) AS Max_ValidTo
from TEMP_TABLE_etoro_History_BackOfficeCustomer  
--[DWH_staging].[etoro_History_BackOfficeCustomer] (nolock)
--FROM [History].[BackOfficeCustomer] with (nolock)
where ValidFrom  < V_dt
group by CID
) b
on a.CID= b.CID and  ValidFrom = b.Max_ValidFrom and ValidTo = b.Max_ValidTo																																												
) c
on a.CID = c.CID
WHERE
a.RegulationID <> c.RegulationID
AND a.ValidFrom >= V_dt
AND ValidFrom < V_CurrentDate
group by
a.CID,
COALESCE(c.RegulationID, 0),
COALESCE(a.RegulationID, 0),
CAST(date_format(DATEADD(day, 0, b.Max_ValidFrom), 'yyyyMMdd') AS int),
 a.ValidTo
 ) g
where rn = 1;


	----------------------------------------------------------------->
--Truncate Ext_FRT_BackOffice_RegulationChangeLog_All
TRUNCATE table dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog_All

;
insert into dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog_All
(`RegulationChangeID`
              ,`CID`
              ,`Occurred`
              ,`FromRegulationID`
              ,`ToRegulationID`
              ,`DateID`
              )
select   a.`RegulationChangeID`
   ,a.`CID`
   ,a.`Occurred`
   ,b.`FromRegulationID`
   ,a.`ToRegulationID`
   ,a.`DateID`
from 
(
SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,`ToRegulationID`
  ,DateID
from 
(SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,`ToRegulationID`
  ,DateID
  ,row_number() over(partition by CID,DateID order by Occurred desc ) as rn
  FROM (SELECT  `RegulationChangeID`
      ,`CID`
      ,`Occurred`
      ,COALESCE(`FromRegulationID`, 0) as FromRegulationID
      ,COALESCE(`ToRegulationID`, 0) as  ToRegulationID
     ,CAST(date_format(DATEADD(day, 0, `Occurred`), 'yyyyMMdd') AS int) as DateID
     FROM dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog
    ) a
 ) b
where rn=1
) a
join 
(
SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,`FromRegulationID`
  ,DateID
from 
(SELECT `RegulationChangeID`
  ,`CID`
  ,`Occurred`
  ,COALESCE(`FromRegulationID`, 0) as FromRegulationID
  ,COALESCE(`ToRegulationID`, 0) as  ToRegulationID
  ,DateID
  ,row_number() over(partition by CID,DateID order by Occurred ) as rn
  FROM (SELECT `RegulationChangeID`
     ,`CID`
     ,`Occurred`
     ,`FromRegulationID`
     ,`ToRegulationID`
     ,CAST(date_format(DATEADD(day, 0, `Occurred`), 'yyyyMMdd') AS int) as DateID
     FROM dwh_daily_process.migration_tables.Ext_FRT_BackOffice_RegulationChangeLog
     
    ) a
 ) b
where rn=1
) b
on(a.CID=b.CID and a.DateID=b.DateID)
where b.FromRegulationID<> a.ToRegulationID


;
call dwh_daily_process.migration_tables.SP_Fact_RegulationTransfer(V_dt);
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_etoro_History_BackOfficeCustomer;
END