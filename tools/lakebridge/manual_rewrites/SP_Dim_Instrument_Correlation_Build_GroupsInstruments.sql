-- Manual rewrite of DWH_dbo.SP_Dim_Instrument_Correlation_Build_GroupsInstruments
-- BladeBridge bugs:
--   1. Emitted `DECLARE VARIABLE` instead of plain `DECLARE`.
--   2. Inserted stray `;` between the multi-CTE block and the INSERT,
--      breaking the CTE binding.
--   3. Left dangling `SELECT V_NumInstrumentID` / `SELECT V_NumRowsInGroup`
--      lines (T-SQL debug PRINTs) which are no-ops in Databricks SQL.

CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Instrument_Correlation_Build_GroupsInstruments(
    IN V_auxdate TIMESTAMP
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
BEGIN
    DECLARE V_FromDate         TIMESTAMP;
    DECLARE V_NumInstrumentID  BIGINT;
    DECLARE V_NumRowsInGroup   BIGINT;

    SET V_FromDate = DATEADD(MONTH, -3, V_auxdate);

    SET V_NumInstrumentID = (
        SELECT cast(count(DISTINCT InstrumentID) AS bigint)
        FROM dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted
        WHERE DateFrom >= V_FromDate
          AND DateFrom <  V_auxdate
    );

    SET V_NumRowsInGroup = CAST(
        (V_NumInstrumentID * V_NumInstrumentID / 2.0) / 89.0
        AS BIGINT
    );

    TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments;

    INSERT INTO dwh_daily_process.migration_tables.Dim_Instrument_Correlation_GroupsInstruments
        (GroupID, MinInstrumentID, MaxInstrumentID)
    WITH Step1 AS (
        SELECT InstrumentID,
               ROW_NUMBER() OVER (ORDER BY InstrumentID) AS Rows_InstrumentID
        FROM (
            SELECT DISTINCT InstrumentID
            FROM dwh_daily_process.migration_tables.Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted
            WHERE DateFrom >= V_FromDate
              AND DateFrom <  V_auxdate
        ) DistInstrument
    ),
    Step2 AS (
        SELECT Step1.*,
               V_NumInstrumentID + 1 - Rows_InstrumentID AS CountRowPerInstrument
        FROM Step1
    ),
    Step3 AS (
        SELECT Step2.*,
               SUM(CountRowPerInstrument) OVER (ORDER BY Rows_InstrumentID) AS Sum3
        FROM Step2
    ),
    Step4 AS (
        SELECT Step3.*,
               CAST(Sum3 / V_NumRowsInGroup AS INT) + 1 AS GroupID
        FROM Step3
    )
    SELECT GroupID,
           MIN(InstrumentID) AS MinInstrumentID,
           MAX(InstrumentID) AS MaxInstrumentID
    FROM Step4
    GROUP BY GroupID;
END;
