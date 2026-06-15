-- Manual rewrite of DWH_dbo.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse
-- Source: Adi Ferber, 2021-09-19 (Synapse DataLake -> Synapse staging)
--
-- BladeBridge produced unsalvageable garbage:
--   * COALESCE() with no args + CAST(from <table>...AS STRING) <- mangled
--   * MERGE USING (...) with `--TRUNCATE TABLE` inside the ON clause
--   * DATEDIFF(-1, V_Yesterday) -- wrong arg count
-- Re-authored from the procedure's comments and intent:
--
-- Steps:
--   1. Compute the run window [V_Yesterday, V_Yesterday + 1 day).
--   2. If we already loaded data for V_Yesterday or later, delete it
--      so this run is idempotent (re-run safe).
--   3. Close the open intervals: any row whose FromDate matches the
--      MAX(FromDate) per PositionID gets ToDate flipped to 20991231
--      (open-ended sentinel).
--   4. Truncate the Ext staging table and reload it from the DL view
--      for the run window.
--   5. Call SP_Dim_Position_PositionHedgeServerChangeLog(V_Yesterday)
--      which folds the staged rows into Dim_PositionHedgeServerChangeLog_Snapshot.

CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse(
    IN V_dt TIMESTAMP
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS
BEGIN
    DECLARE V_Yesterday      TIMESTAMP;
    DECLARE V_CurrentDate    TIMESTAMP;
    DECLARE V_YesterdayID    INT;
    DECLARE V_CurrentDateID  INT;
    DECLARE V_MaxFromDate    INT;

    SET V_Yesterday     = CAST(V_dt AS TIMESTAMP);
    SET V_CurrentDate   = DATEADD(DAY, 1, V_Yesterday);
    SET V_YesterdayID   = CAST(date_format(V_Yesterday,   'yyyyMMdd') AS INT);
    SET V_CurrentDateID = CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);

    -- Snapshot's FromDate is an INT YYYYMMDD; pick its max so we can
    -- tell whether the V_Yesterday day has already been loaded.
    SET V_MaxFromDate = (
        SELECT COALESCE(MAX(FromDate), 0)
        FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
    );

    -- Idempotency: drop any same-day-or-newer history before reload.
    IF V_YesterdayID <= V_MaxFromDate THEN
        DELETE FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
        WHERE FromDate >= V_YesterdayID;
    END IF;

    -- Close out the currently-open interval (latest row per PositionID)
    -- by setting ToDate to the open-ended sentinel 20991231.
    MERGE INTO dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot AS tgt
    USING (
        SELECT PositionID, FromDate
        FROM (
            SELECT PositionID,
                   FromDate,
                   ROW_NUMBER() OVER (
                       PARTITION BY PositionID
                       ORDER BY FromDate DESC
                   ) AS rn
            FROM dwh_daily_process.migration_tables.Dim_PositionHedgeServerChangeLog_Snapshot
        ) ranked
        WHERE rn = 1
    ) AS src
    ON  tgt.PositionID = src.PositionID
    AND tgt.FromDate   = src.FromDate
    WHEN MATCHED THEN UPDATE SET ToDate = 20991231;

    -- Stage the DL delta for V_Yesterday into the Ext table that the
    -- downstream SP_Dim_Position_PositionHedgeServerChangeLog reads.
    TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog;

    INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Position_PositionHedgeServerChangeLog
        (PositionID,
         OccurredDate,
         OccurredDateID,
         FromHedgeServerID,
         ToHedgeServerID,
         UpdateDate)
    SELECT PositionID,
           ADM_DATE                                              AS OccurredDate,
           CAST(date_format(ADM_DATE, 'yyyyMMdd') AS INT)        AS OccurredDateID,
           FromHedgeServerID,
           ToHedgeServerID,
           current_timestamp()                                   AS UpdateDate
    FROM dwh_daily_process.daily_snapshot.etoro_Trade_PositionsHedgeServerChangeLog
    WHERE ADM_DATE >= DATEADD(HOUR, -1, V_Yesterday)
      AND ADM_DATE <  V_CurrentDate;

    -- Hand off to the downstream SP which merges Ext into the snapshot.
    CALL dwh_daily_process.migration_tables.SP_Dim_Position_PositionHedgeServerChangeLog(V_Yesterday);
END;
