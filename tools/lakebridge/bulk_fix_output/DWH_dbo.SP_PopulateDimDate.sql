USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_PopulateDimDate(
IN V_starting_dt TIMESTAMP,
IN V_ending_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_FiscalYearMonthsOffset int
;
DECLARE V_offset int
;
DECLARE V_Yr int;

DECLARE V_EndYr int;

DECLARE V_Offset int;

DECLARE V_WeekNumberInMonth int;

DECLARE V_Jan1 DATE;

DECLARE V_Feb1 DATE;

DECLARE V_May1 DATE;

DECLARE V_Sep1 DATE;

DECLARE V_Oct1 DATE;

DECLARE V_Nov1 DATE;

DECLARE V_MemorialDay DATE;

DECLARE V_ThanksgivingDay DATE
;
DECLARE V_Control_Date DATE     --Current date in loop
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2018-02-08
Description: Update table DimDate
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
2020-11-16     Boris Slutski  Add  a new column [IsFirstDayOfMonth] 
*********************************************************************************************/
-- EXEC  [DWH_dbo].[SP_PopulateDimDate] '20070101','20221231'
--Declare @starting_dt date = DATEADD(yy, DATEDIFF(yy, -1, getdate()), 0)
--Declare @ending_dt date =  DATEADD (dd, -1, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) +2, 0))

SET V_FiscalYearMonthsOffset = 0

;
SET V_offset = 0


;
SET DATEFIRST 7/*databricks does not support changing first day the first day of the week is fixed to Monday; -- use post script to update date functions*/     -- Standard for U.S. Week starts on Sunday

-- Standard Holidays
     -- New Years Day - Jan 1
     -- MLK Day - 3rd Monday in Jan
     -- Presidents Day - 3rd Monday in Feb
     -- Memorial Day - Last Mon in May
     -- Independence Day - Jul 4
     -- Labor Day - 1st Mon in Sep
     -- Columbus Day - 2nd Mon in Oct
     -- Veterans Day - Nov 11
     -- Thanksgiving Day - 4th Thurs in Nov
     -- Day after Thanksgiving - Day after 4th Thurs in Nov
     -- Christmas Eve - Dec 24
     -- Christmas Day - Dec 25
DROP VIEW IF EXISTS TEMP_TABLE_HolidayTable;
CREATE OR REPLACE TABLE TEMP_TABLE_HolidayTable (HolidayKey int 
     , HolidayDate DATE NOT NULL
     , HolidayName STRING NOT NULL
     , IsFedHoliday BOOLEAN NOT NULL DEFAULT0
     , IsBankHoliday BOOLEAN NOT NULL DEFAULT0
     , IsUSACorpHoliday BOOLEAN NOT NULL DEFAULT0
     ) USING DELTA  

	 

;
SET V_Yr = EXTRACT(yyyy from V_starting_dt)
;
SET V_EndYr = EXTRACT(yyyy from V_ending_dt)

;
WHILE V_Yr <= V_EndYr
DO
IF V_Yr > 1985
THEN
	DELETE FROM dwh_daily_process.migration_tables.Dim_Date
	where 
	`CalendarYear` = V_Yr
	
     ;
SET V_Jan1 = CAST(CAST(V_Yr AS char(4)) || '0101' AS DATE)
     ;
SET V_Feb1 = CAST(CAST(V_Yr AS char(4)) || '0201' AS DATE)
     ;
SET V_May1 = CAST(CAST(V_Yr AS char(4)) || '0501' AS DATE)
     ;
SET V_Sep1 = CAST(CAST(V_Yr AS char(4)) || '0901' AS DATE)
     ;
SET V_Oct1 = CAST(CAST(V_Yr AS char(4)) || '1001' AS DATE)
     ;
SET V_Nov1 = CAST(CAST(V_Yr AS char(4)) || '1101' AS DATE);

     -- New Years Day logic
     -- Could be celebrated on New Years Day, the Friday before, or the Monday after
     -- depending on whether the day falls on a weekend or not and the value of @FiscalYearMonthsOffset
IF (EXTRACT(dw from V_Jan1) > 1) AND (EXTRACT(dw from V_Jan1) < 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '0101' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '0101' AS DATE)
                    , 'New Year"s Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END WHILE;
IF (EXTRACT(dw from V_Jan1) = 1)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '0102' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '0102' AS DATE)
                    , 'New Year"s Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from V_Jan1) = 7)
     THEN
-- For most banks, the fiscal year ends 12-31 and New Year's Day is celebrated in the New Year.

IF V_FiscalYearMonthsOffset = 0
          THEN
-- When an organization's fiscal year ends on 12-31, and New Years falls on Saturday, New Years is observed on the following Monday.

               INSERT INTO TEMP_TABLE_HolidayTable
                    SELECT CAST(CAST(V_Yr - 1 AS char(4)) || '1231' as int)
                         , CAST(CAST(V_Yr - 1 AS char(4)) || '1231' AS DATE)
                         , 'New Year"s Day'
                         , 1          -- IsFedHoliday
                         , 0          -- IsBankHoliday
                         , 0          -- IsUSACorpHoliday
;
               INSERT INTO TEMP_TABLE_HolidayTable
                    SELECT CAST(CAST(V_Yr AS char(4)) || '0103' as int)
                         , CAST(CAST(V_Yr AS char(4)) || '0103' AS DATE)
                         , 'New Year"s Day'
                         , 0          -- IsFedHoliday
                         , 1          -- IsBankHoliday
                         , 1          -- IsUSACorpHoliday
;
ELSE

-- When an organization's fiscal year ends on a day other than 12-31, and New Years falls on Saturday, New Years is observed on the previous Friday.
               INSERT INTO TEMP_TABLE_HolidayTable
                    SELECT CAST(CAST(V_Yr - 1 AS char(4)) || '1231' as int)
                         , CAST(CAST(V_Yr - 1 AS char(4)) || '1231' AS DATE)
                         , 'New Year"s Day'
                         , 1          -- IsFedHoliday
                         , 0          -- IsBankHoliday
                         , 1          -- IsUSACorpHoliday
;
               INSERT INTO TEMP_TABLE_HolidayTable
                    SELECT CAST(CAST(V_Yr AS char(4)) || '0103' as int)
                         , CAST(CAST(V_Yr AS char(4)) || '0103' AS DATE)
                         , 'New Year"s Day'
                         , 0          -- IsFedHoliday
                         , 1          -- IsBankHoliday
                         , 0          -- IsUSACorpHoliday
;
END IF;
END IF;

     -- MLK Day logic
     -- 3rd Monday in Jan
SET V_offset = 2 - EXTRACT(dw from V_Jan1)
     ;
SET V_WeekNumberInMonth = 3;
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Jan1), 'yyyyMMdd') as int)
               , DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Jan1)
               , 'MLK Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- President's Day logic
     -- 3rd Monday in Feb
SET V_offset = 2 - EXTRACT(dw from V_Feb1);
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Feb1), 'yyyyMMdd') as int)
               , DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Feb1)
               , 'President"s Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- Memorial Day logic
     -- Last Monday in May
SET V_MemorialDay = CASE EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) + '0531' AS DATE))
                         WHEN 1
                         THEN CAST(CAST(V_Yr AS char(4)) + '0525' AS DATE)
                         WHEN 2
                         THEN CAST(CAST(V_Yr AS char(4)) + '0531' AS DATE)
                         WHEN 3
                         THEN CAST(CAST(V_Yr AS char(4)) + '0530' AS DATE)
                         WHEN 4
                         THEN CAST(CAST(V_Yr AS char(4)) + '0529' AS DATE)
                         WHEN 5
                         THEN CAST(CAST(V_Yr AS char(4)) + '0528' AS DATE)
                         WHEN 6
                         THEN CAST(CAST(V_Yr AS char(4)) + '0527' AS DATE)
                         ELSE CAST(CAST(V_Yr AS char(4)) + '0526' AS DATE)
                    END;
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(V_MemorialDay, 'yyyyMMdd') as int)
               , V_MemorialDay
               , 'Memorial Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- Independence Day logic
     -- Jul 4th of each year
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '0704' AS DATE)) > 1) AND (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '0704' AS DATE)) < 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '0704' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '0704' AS DATE)
                    , 'Independence Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '0704' AS DATE)) = 1)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '0705' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '0705' AS DATE)
                    , 'Independence Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '0704' AS DATE)) = 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '0703' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '0703' AS DATE)
                    , 'Independence Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;

     -- Labor Day logic
     -- 1st Monday in September
SET V_offset = 2 - EXTRACT(dw from V_Sep1)
     ;
SET V_WeekNumberInMonth = 1;
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Sep1), 'yyyyMMdd') as int)
               , DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Sep1)
               , 'Labor Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- Columbus Day logic
     -- 2nd Monday in October
     -- Usually only observed by Fed Govt and Banks
SET V_offset = 2 - EXTRACT(dw from V_Oct1)
     ;
SET V_WeekNumberInMonth = 2;
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Oct1), 'yyyyMMdd') as int)
               , DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Oct1)
               , 'Columbus Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 0;          -- IsUSACorpHoliday

     -- Veterans Day logic
     -- October 11th of each year
     -- Usually only observed by Fed Govt and Banks
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1111' AS DATE)) > 1) AND (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1111' AS DATE)) < 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1111' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1111' AS DATE)
                    , 'Veterans Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 0          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1111' AS DATE)) = 1)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1112' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1112' AS DATE)
                    , 'Veterans Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 0          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1111' AS DATE)) = 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1110' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1110' AS DATE)
                    , 'Veterans Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 0          -- IsUSACorpHoliday
;
END IF;

     -- Thanksgiving Day logic
     -- 4th Thursday of November
SET V_offset = 5 - EXTRACT(dw from V_Nov1)
     ;
SET V_WeekNumberInMonth = 4
     ;
SET V_ThanksgivingDay = DATEADD(DAY, V_offset + (V_WeekNumberInMonth - CASE WHEN V_offset >= 0 THEN 1 ELSE 0 END) * 7, V_Nov1);
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(V_ThanksgivingDay, 'yyyyMMdd') as int)
               , V_ThanksgivingDay
               , 'Thanksgiving Day'
               , 1          -- IsFedHoliday
               , 1          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- Day after Thanksgiving Day logic
     -- Not observed by Fed Govt and Banks
     INSERT INTO TEMP_TABLE_HolidayTable
          SELECT CAST(date_format(DATEADD(DAY, 1, V_ThanksgivingDay), 'yyyyMMdd') as int)
               , DATEADD(DAY, 1, V_ThanksgivingDay)
               , 'Day after Thanksgiving'
               , 0          -- IsFedHoliday
               , 0          -- IsBankHoliday
               , 1;          -- IsUSACorpHoliday

     -- Christmas Eve logic
     -- Federal Govt and Banks do not celebrate Christmas Eve
     -- Logic can get complex when Christmas Day falls on a weekend.
     -- Using this logic, if Christmas Eve falls on Sunday, it will be observed on the following Tuesday.
     -- If Christmas Eve falls on Friday or Saturday, it will be observed on 12-23.
     -- Many companies do not use the following logic.
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)) > 1) AND (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)) < 6)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1224' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)
                    , 'Christmas Eve'
                    , 0          -- IsFedHoliday
                    , 0          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)) = 1)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1226' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1226' AS DATE)
                    , 'Christmas Eve'
                    , 0          -- IsFedHoliday
                    , 0          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)) > 5)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1223' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1223' AS DATE)
                    , 'Christmas Eve'
                    , 0          -- IsFedHoliday
                    , 0          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;

     -- Christmas Day logic
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1225' AS DATE)) > 1) AND (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1225' AS DATE)) < 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1225' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1225' AS DATE)
                    , 'Christmas Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1225' AS DATE)) = 1)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1226' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1226' AS DATE)
                    , 'Christmas Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;
IF (EXTRACT(dw from CAST(CAST(V_Yr AS char(4)) || '1225' AS DATE)) = 7)
     THEN
          INSERT INTO TEMP_TABLE_HolidayTable
               SELECT CAST(CAST(V_Yr AS char(4)) || '1224' as int)
                    , CAST(CAST(V_Yr AS char(4)) || '1224' AS DATE)
                    , 'Christmas Day'
                    , 1          -- IsFedHoliday
                    , 1          -- IsBankHoliday
                    , 1          -- IsUSACorpHoliday
;
END IF;

END IF;
SET V_Yr = V_Yr + 1
;


SET V_Control_Date = V_starting_dt

;
WHILE V_Control_Date <= V_ending_dt
THEN
SET V_Yr = EXTRACT(yyyy from V_Control_Date);
     INSERT INTO dwh_daily_process.migration_tables.Dim_Date 
(`DateKey`
                         , `FullDate`
                         , `MonthNumberOfYear`
                         , `MonthNumberOfQuarter`
                         , `ISOYearAndWeekNumber`
                         , `ISOWeekNumberOfYear`
                         , `SSWeekNumberOfYear`
                         , `ISOWeekNumberOfQuarter_454_Pattern`
                         , `SSWeekNumberOfQuarter_454_Pattern`
                         , `SSWeekNumberOfMonth`
                         , `DayNumberOfYear`
                         , `DaysSince1900`
                         , `DayNumberOfFiscalYear`
                         , `DayNumberOfQuarter`
                         , `DayNumberOfMonth`
                         , `DayNumberOfWeek_Sun_Start`
                         , `MonthName`
                         , `MonthNameAbbreviation`
                         , `DayName`
                         , `DayNameAbbreviation`
                         , `CalendarYear`
                         , `CalendarYearMonth`
                         , `CalendarYearQtr`
                         , `CalendarSemester`
                         , `CalendarQuarter`
                         , `FiscalYear`
                         , `FiscalMonth`
                         , `FiscalQuarter`
                         , `FiscalYearMonth`
                         , `FiscalYearQtr`
                         , `QuarterNumber`
                         , `YYYYMMDD`
                         , `MM/DD/YYYY`
                         , `YYYY/MM/DD`
                         , `YYYY-MM-DD`
                         , `MonDDYYYY`
                         , `IsLastDayOfMonth`
						 , `IsFirstDayOfMonth`
                         , `IsWeekday`
                         , `IsWeekend`
						 , `PartitionID`
                         --, [IsWorkday]
                         --, [IsFederalHoliday]
                         --, [IsBankHoliday]
                         --, [IsCompanyHoliday]
						 , `UpdateDate`
               )

     SELECT CAST(date_format(V_Control_Date, 'yyyyMMdd') as int) AS `DateKey`
          , V_Control_Date AS `FullDate`
          , EXTRACT(mm from V_Control_Date) AS `MonthNumberOfYear`
          , CASE EXTRACT(mm from V_Control_Date)
                    WHEN 1 THEN 1
                    WHEN 2 THEN 2
                    WHEN 3 THEN 3
                    WHEN 4 THEN 1
                    WHEN 5 THEN 2
                    WHEN 6 THEN 3
                    WHEN 7 THEN 1
                    WHEN 8 THEN 2
                    WHEN 9 THEN 3
                    WHEN 10 THEN 1
                    WHEN 11 THEN 2
                    ELSE 3
               END AS `MonthNumberOfQuarter`
          , CASE
               WHEN EXTRACT(mm from V_Control_Date) = 1 AND EXTRACT(week from V_Control_Date) > 50
               THEN CAST(V_Yr - 1 AS char(4)) + 'W' + RIGHT('0' + CAST(EXTRACT(week from V_Control_Date) AS STRING), 2)
               WHEN EXTRACT(mm from V_Control_Date) = 12 AND EXTRACT(week from V_Control_Date) < 40
               THEN CAST(V_Yr + 1 AS char(4)) + 'W' + RIGHT('0' + CAST(EXTRACT(week from V_Control_Date) AS STRING), 2)
               ELSE CAST(V_Yr AS char(4)) + 'W' + RIGHT('0' + CAST(EXTRACT(week from V_Control_Date) AS STRING), 2)
               END AS `ISOYearAndWeekNumber`
          , EXTRACT(week from V_Control_Date) AS `ISOWeekNumberOfYear`
          , EXTRACT(wk from V_Control_Date) AS `SSWeekNumberOfYear`
          , CASE
               WHEN EXTRACT(week from V_Control_Date) < 14
               THEN EXTRACT(week from V_Control_Date)
               WHEN EXTRACT(week from V_Control_Date) > 13 AND EXTRACT(week from V_Control_Date) < 27
               THEN EXTRACT(week from V_Control_Date) - 13
               WHEN EXTRACT(week from V_Control_Date) > 26 AND EXTRACT(week from V_Control_Date) < 40
               THEN EXTRACT(week from V_Control_Date) - 26
               ELSE EXTRACT(week from V_Control_Date) - 39
               END AS `ISOWeekNumberOfQuarter_454_Pattern`
          , CASE
               WHEN EXTRACT(wk from V_Control_Date) < 14
               THEN EXTRACT(wk from V_Control_Date)
               WHEN EXTRACT(wk from V_Control_Date) > 13 AND EXTRACT(wk from V_Control_Date) < 27
               THEN EXTRACT(wk from V_Control_Date) - 13
               WHEN EXTRACT(wk from V_Control_Date) > 26 AND EXTRACT(wk from V_Control_Date) < 40
               THEN EXTRACT(wk from V_Control_Date) - 26
               ELSE EXTRACT(wk from V_Control_Date) - 39
               END AS `SSWeekNumberOfQuarter_454_Pattern`
          , DATEDIFF(WEEK, V_Control_Date, DATEADD(MONTH, CAST(MONTHS_BETWEEN(0, V_Control_Date) AS INT), 0)) + 1 AS `SSWeekNumberOfMonth`
          , EXTRACT(dy from V_Control_Date) AS `DayNumberOfYear`
          , DATEDIFF('18991231', V_Control_Date) AS `DaysSince1900`
          , CASE
               -- 0ffset < 0 and start of fy < current year
               WHEN YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) < V_Yr
                    AND V_FiscalYearMonthsOffset < 0
               THEN EXTRACT(dy from V_Control_Date)
                         + EXTRACT(dy from /*-- Last day of previous year*/
CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS CHAR(4)) + '1231' AS TIMESTAMP))
                         - EXTRACT(dy from /*-- Start date of Fiscal year*/
DATEADD(MONTH, 1, CAST(CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS char(4))
+ RIGHT('00' + CAST(V_FiscalYearMonthsOffset * -1 AS STRING), 2) + '01' AS char(8)) AS TIMESTAMP))
- 1)
               -- 0ffset > 0 and start of fy < current year
               WHEN YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) - 1 < V_Yr
                    AND V_FiscalYearMonthsOffset > 0
               THEN EXTRACT(dy from V_Control_Date)
                         + EXTRACT(dy from /*-- Last day of previous year*/
CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) - 1 AS CHAR(4)) + '1231' AS TIMESTAMP))
                         - EXTRACT(dy from /*-- Start date of Fiscal year*/
CAST(CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) - 1 AS char(4))
+ RIGHT('00' + CAST(13 - V_FiscalYearMonthsOffset AS STRING), 2) + '01' AS char(8)) AS TIMESTAMP)
- 1)
               -- 0ffset < 0 and start of fy = current year
               WHEN YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) = V_Yr
                    AND V_FiscalYearMonthsOffset < 0
               THEN EXTRACT(dy from V_Control_Date)
                         - EXTRACT(dy from /*-- Start date of Fiscal year*/
DATEADD(MONTH, 1, CAST(CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS char(4))
+ RIGHT('00' + CAST(V_FiscalYearMonthsOffset * -1 AS STRING), 2) + '01' AS char(8)) AS TIMESTAMP))
- 1)
               -- 0ffset > 0 and start of fy = current year
               WHEN YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) - 1 = V_Yr
                    AND V_FiscalYearMonthsOffset > 0
               THEN EXTRACT(dy from V_Control_Date)
                         - EXTRACT(dy from /*-- Start date of Fiscal year*/
CAST(CAST(CAST(YEAR(DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) - 1 AS char(4))
+ RIGHT('00' + CAST(13 - V_FiscalYearMonthsOffset AS STRING), 2) + '01' AS char(8)) AS TIMESTAMP)
- 1)
               ELSE EXTRACT(dy from V_Control_Date)
               END AS `DayNumberOfFiscalYear`
          , CASE
               WHEN EXTRACT(mm from V_Control_Date) = 1
                    OR EXTRACT(mm from V_Control_Date) = 4
                    OR EXTRACT(mm from V_Control_Date) = 7
                    OR EXTRACT(mm from V_Control_Date) = 10
               THEN EXTRACT(day from V_Control_Date)
               WHEN EXTRACT(mm from V_Control_Date) = 2
                    OR EXTRACT(mm from V_Control_Date) = 5
                    OR EXTRACT(mm from V_Control_Date) = 8
                    OR EXTRACT(mm from V_Control_Date) = 11
               THEN EXTRACT(day from V_Control_Date)
                         + DAY(DATEADD(MONTH, 1, DATEADD(DAY, 1 - DAY(CAST(CAST(V_Yr AS char(4))
+ RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 1 AS STRING), 2) + '01' AS DATE)), CAST(CAST(V_Yr AS char(4)) + RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 1 AS STRING), 2) + '01' AS TIMESTAMP)))
                         - 1)
               WHEN EXTRACT(mm from V_Control_Date) = 3
                    OR EXTRACT(mm from V_Control_Date) = 6
                    OR EXTRACT(mm from V_Control_Date) = 9
                    OR EXTRACT(mm from V_Control_Date) = 12
               THEN EXTRACT(day from V_Control_Date)
                         + DAY(DATEADD(MONTH, 1, DATEADD(DAY, 1 - DAY(CAST(CAST(V_Yr AS char(4))
+ RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 1 AS STRING), 2) + '01' AS DATE)), CAST(CAST(V_Yr AS char(4)) + RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 1 AS STRING), 2) + '01' AS TIMESTAMP)))
                         - 1)
                         + DAY(DATEADD(MONTH, 1, DATEADD(DAY, 1 - DAY(CAST(CAST(V_Yr AS char(4))
+ RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 2 AS STRING), 2) + '01' AS DATE)), CAST(CAST(V_Yr AS char(4)) + RIGHT('0' + CAST(EXTRACT(mm from V_Control_Date) - 2 AS STRING), 2) + '01' AS TIMESTAMP)))
                         - 1)
               END AS `DayNumberOfQuarter`
          , EXTRACT(day from V_Control_Date) AS `DayNumberOfMonth`
          , EXTRACT(dw from V_Control_Date) AS `DayNumberOfWeek_Sun_Start`
          , cast(EXTRACT(month from V_Control_Date) as string) AS `MonthName`
          , LEFT(cast(EXTRACT(month from V_Control_Date) as string), 3) AS `MonthNameAbbreviation`
          , cast(EXTRACT(DOW from V_Control_Date) as string) AS `DayName`
          , LEFT(cast(EXTRACT(DOW from V_Control_Date) as string), 3) AS `DayNameAbbreviation`
          , V_Yr AS `CalendarYear`
          , CAST(V_Control_Date AS STRING) AS `CalendarYearMonth`
          , CAST(V_Yr AS char(4)) || '-' || RIGHT('0' || CAST(EXTRACT(qq from V_Control_Date) AS char(1)), 2) AS `CalendarYearQuarter`
          , CASE (EXTRACT(mm from V_Control_Date))
                    WHEN 1 THEN 1
                    WHEN 2 THEN 1
                    WHEN 3 THEN 1
                    WHEN 4 THEN 1
                    WHEN 5 THEN 1
                    WHEN 6 THEN 1
                    ELSE 2
               END AS `CalendarSemester`
          , EXTRACT(qq from V_Control_Date) AS `CalendarQuarter`
          , EXTRACT(yyyy from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS `FiscalYear`
          , EXTRACT(mm from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS `FiscalMonth`
          , EXTRACT(qq from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS `FiscalQuarter`
          , CAST(EXTRACT(yyyy from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS char(4)) || '-'
                    || RIGHT('0' || CAST(EXTRACT(mm from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS STRING), 2) AS `FiscalYearMonth`
          , CAST(EXTRACT(yyyy from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS char(4)) || 'Q'
                    || RIGHT('0' || CAST(EXTRACT(qq from DATEADD(MONTH, V_FiscalYearMonthsOffset, V_Control_Date)) AS STRING), 2) AS `FiscalYearQtr`
          , CASE
               WHEN V_Control_Date >= '19000101'
               THEN ((V_Yr - 1900) * 4) + EXTRACT(qq from V_Control_Date)
               ELSE ((V_Yr - 1900) * 4) - (5 - EXTRACT(qq from V_Control_Date))
               END AS `QuarterNumber`
          , date_format(V_Control_Date, 'yyyyMMdd') AS `YYYYMMDD`
          , date_format(V_Control_Date, 'MM/dd/yyyy') AS `MM/DD/YYYY`
          , date_format(V_Control_Date, 'yyyy/MM/dd') AS `YYYY/MM/DD`
          , REPLACE(date_format(V_Control_Date, 'yyyy/MM/dd'), '/', '-') AS `YYYY-MM-DD`
          , LEFT(cast(EXTRACT(month from V_Control_Date) as string), 3) || ' ' ||
               RIGHT('0' || CAST(EXTRACT(dd from V_Control_Date) AS STRING), 2) || ' ' ||
               CAST(V_Yr AS CHAR(4)) AS `MonDDYYYY`
          , CASE
               WHEN V_Control_Date = DATEADD(DAY, -day(DATEADD(MONTH, 1, V_Control_Date)), DATEADD(MONTH, 1, V_Control_Date))
               THEN 'Y'
               ELSE 'N'
               END AS `IsLastDayOfMonth`
		 , CASE
               WHEN V_Control_Date = DATEADD(MONTH, CAST(MONTHS_BETWEEN(0, V_Control_Date) AS INT), 0)
               THEN 'Y'
               ELSE 'N'
               END AS `IsFirstDayOfMonth`
          , CASE EXTRACT(dw from V_Control_Date)
                    WHEN 1
                    THEN 'N'
                    WHEN 7
                    THEN 'N'
                    ELSE 'Y'
               END AS `IsWeekday`
          , CASE EXTRACT(dw from V_Control_Date)
                    WHEN 1
                    THEN 'Y'
                    WHEN 7
                    THEN 'Y'
                    ELSE 'N'
               END AS `IsWeekend`
		, CAST(date_format(V_Control_Date, 'yyyyMMdd') as int)/(100) as `PartitionID` 
		 , current_timestamp()
     ;
SET V_Control_Date = DATEADD(DAY, 1, V_Control_Date)
;
END IF;
MERGE INTO dwh_daily_process.migration_tables.Dim_Date dateTbl_TGT
USING (
SELECT * 
FROM dwh_daily_process.migration_tables.Dim_Date dateTbl
LEFT JOIN TEMP_TABLE_HolidayTable holTbl ON dateTbl.`DateKey` = holTbl.HolidayKey
)
ON DateKey BETWEEN CAST ( date_format(V_starting_dt, 'yyyyMMdd') AS int ) AND CAST ( date_format(V_ending_dt, 'yyyyMMdd') AS int ) AND 
COALESCE(dateTbl.`IsWorkday`::string,'__NULL__') = COALESCE(dateTbl_TGT.`IsWorkday`::string,'__NULL__') AND 
COALESCE(dateTbl.IsWeekday::string,'__NULL__') = COALESCE(dateTbl_TGT.IsWeekday::string,'__NULL__') AND 
COALESCE(dateTbl.`IsFederalHoliday`::string,'__NULL__') = COALESCE(dateTbl_TGT.`IsFederalHoliday`::string,'__NULL__') AND 
COALESCE(dateTbl.`IsBankHoliday`::string,'__NULL__') = COALESCE(dateTbl_TGT.`IsBankHoliday`::string,'__NULL__') AND 
COALESCE(dateTbl.`IsCompanyHoliday`::string,'__NULL__') = COALESCE(dateTbl_TGT.`IsCompanyHoliday`::string,'__NULL__') AND 
COALESCE(dateTbl.`DateKey`::string,'__NULL__') = COALESCE(dateTbl_TGT.`DateKey`::string,'__NULL__')
WHEN MATCHED THEN UPDATE SET
`IsWorkday` = CASE WHEN dateTbl.IsWeekday = 'Y' AND COALESCE(holTbl.IsUSACorpHoliday, 0) = 0 THEN 'Y' ELSE 'N' END ,
`IsFederalHoliday` = CASE WHEN COALESCE(holTbl.IsFedHoliday, 0) = 1 THEN 'Y' ELSE 'N' END ,
`IsBankHoliday` = CASE WHEN COALESCE(CAST(holTbl.IsBankHoliday AS STRING), '') = 1 THEN 'Y' ELSE 'N' END ,
`IsCompanyHoliday` = CASE WHEN COALESCE(holTbl.IsUSACorpHoliday, 0) = 1 THEN 'Y' ELSE 'N' END;
