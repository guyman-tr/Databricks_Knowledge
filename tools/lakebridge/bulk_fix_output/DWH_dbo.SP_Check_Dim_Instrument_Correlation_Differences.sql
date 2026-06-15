USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Check_Dim_Instrument_Correlation_Differences(
IN V_DateID int)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

    
DECLARE V_TotalInOld BIGINT ;

DECLARE V_TotalInNew BIGINT ;

DECLARE V_MissingInNew BIGINT ;

DECLARE V_MissingInOld BIGINT ;

DECLARE V_MismatchInValues BIGINT ;

DECLARE V_TotalInOldStr STRING ;

DECLARE V_TotalInNewStr STRING ;

DECLARE V_MissingInNewStr STRING ;

DECLARE V_MissingInOldStr STRING ;

DECLARE V_MismatchInValuesStr STRING ;
-- Count total rows using COUNT_BIG to prevent overflow

SET V_TotalInOld = (
SELECT cast(count(*) as bigint) 
FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active
WHERE DateID = V_DateID
);
SET V_TotalInNew = (
SELECT cast(count(*) as bigint) 
FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_UnionedPartitions
WHERE DateID = V_DateID
);
-- Count rows missing in the new table

SET V_MissingInNew = (
SELECT cast(count(*) as bigint)
FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active a
LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Correlation_UnionedPartitions b
ON a.DateID = b.DateID 
AND a.InstrumentID_a = b.InstrumentID_a 
AND a.InstrumentID_b = b.InstrumentID_b
WHERE b.DateID IS NULL
AND a.DateID = V_DateID
);
-- Count rows missing in the old table

SET V_MissingInOld = (
SELECT cast(count(*) as bigint)
FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_UnionedPartitions b
LEFT JOIN dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active a
ON a.DateID = b.DateID 
AND a.InstrumentID_a = b.InstrumentID_a 
AND a.InstrumentID_b = b.InstrumentID_b
WHERE a.DateID IS NULL
AND b.DateID = V_DateID
);
-- Count mismatches in values above a minimal threshold (1E-9)

SET V_MismatchInValues = (
SELECT cast(count(*) as bigint)
FROM dwh_daily_process.migration_tables.Dim_Instrument_Correlation_Active a
JOIN dwh_daily_process.migration_tables.Dim_Instrument_Correlation_UnionedPartitions b
ON a.DateID = b.DateID 
AND a.InstrumentID_a = b.InstrumentID_a 
AND a.InstrumentID_b = b.InstrumentID_b
WHERE a.DateID = V_DateID
AND b.DateID = V_DateID
AND (
ABS(COALESCE(a.StandardDeviation_a, 0) - COALESCE(b.StandardDeviation_a, 0)) >= 1E-9 OR
ABS(COALESCE(a.StandardDeviation_b, 0) - COALESCE(b.StandardDeviation_b, 0)) >= 1E-9 OR
ABS(COALESCE(a.Covariance, 0) - COALESCE(b.Covariance, 0)) >= 1E-9 OR
ABS(COALESCE(a.PearsonCorrelation, 0) - COALESCE(b.PearsonCorrelation, 0)) >= 1E-9
)
);
-- Convert all numeric values to VARCHAR to avoid overflow in string concatenation

SET V_TotalInOldStr = cast(V_TotalInOld AS STRING);
SET V_TotalInNewStr = cast(V_TotalInNew AS STRING);
SET V_MissingInNewStr = cast(V_MissingInNew AS STRING);
SET V_MissingInOldStr = cast(V_MissingInOld AS STRING);
SET V_MismatchInValuesStr = cast(V_MismatchInValues AS STRING);
-- Return formatted HTML message for Logic App email body

    SELECT
        CASE
            WHEN V_MissingInNew = 0 AND V_MissingInOld = 0 AND V_MismatchInValues = 0 THEN
                CONCAT(
                    '<p style="color:green; font-weight:bold;"> No differences found. Old and new tables are identical.</p>',
                    '<p>Total rows: ', V_TotalInOldStr, '</p>'
                )
            ELSE
                CONCAT(
                    '<p style="color:red; font-weight:bold;"> Differences found:</p>',
                    '<ul>',
                    '<li>Missing in new: ', V_MissingInNewStr, '</li>',
                    '<li>Missing in old: ', V_MissingInOldStr, '</li>',
                    '<li>Mismatched values: ', V_MismatchInValuesStr, '</li>',
                    '<li>Total in old: ', V_TotalInOldStr, '</li>',
                    '<li>Total in new: ', V_TotalInNewStr, '</li>',
                    '</ul>'
                )
        END AS QA_Result_HTML;
END;
