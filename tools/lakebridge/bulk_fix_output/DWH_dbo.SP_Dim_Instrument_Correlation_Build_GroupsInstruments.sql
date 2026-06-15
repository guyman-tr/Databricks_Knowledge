USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_Build_GroupsInstruments(
IN V_auxdate TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

DECLARE V_FromDate TIMESTAMP ;

DECLARE V_NumInstrumentID BIGINT
;
DECLARE V_NumRowsInGroup BIGINT;
SET V_FromDate = DATEADD(MONTH, -3, V_auxdate)
;

SET V_NumInstrumentID = (
SELECT
cast(count(DISTINCT InstrumentID) as bigint) FROM dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted  
		WHERE DateFrom>=V_FromDate AND DateFrom<V_auxdate
		 
		 LIMIT 1);
SELECT V_NumInstrumentID


		;
SET V_NumRowsInGroup= CAST((V_NumInstrumentID*V_NumInstrumentID/2.0)/89.0 AS BigINT)
		;
SELECT V_NumRowsInGroup
		
		;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments

		;
WITH Step1 AS 
		(
		SELECT InstrumentID,ROW_NUMBER() OVER (ORDER BY InstrumentID)  AS Rows_InstrumentID  
		FROM 
		(SELECT DISTINCT InstrumentID
		 from dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted 
		 where DateFrom>=V_FromDate  and DateFrom<V_auxdate
		 
		 )DistInstrument
		)
		,Step2
		AS
		(
		SELECT *,
		V_NumInstrumentID+1- Rows_InstrumentID AS CountRowPerInstrument  
		FROM Step1
		)
		,Step3 AS
		(
		SELECT *,SUM(CountRowPerInstrument) OVER (ORDER BY  Rows_InstrumentID)  AS Sum3
		FROM Step2
		)
		,Step4 AS
		(
		SELECT *,CAST (Sum3/V_NumRowsInGroup AS int) +1 AS GroupID
		FROM Step3
		);
		INSERT INTO dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments
		(GroupID,MinInstrumentID,MaxInstrumentID)
		SELECT GroupID,
			MIN(InstrumentID) AS MinInstrumentID,
			MAX(InstrumentID) AS MaxInstrumentID
			 
		FROM Step4
		GROUP BY GroupID
 
;
END;
