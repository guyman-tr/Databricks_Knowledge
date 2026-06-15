-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.v_hschangesummarylog_yesterday_email_csv
-- Captured: 2026-05-19T12:47:35Z
-- ==========================================================================

WITH run_date AS (
   -- SELECT DATE('2025-10-30') AS run_date
   select date_sub(current_date(), 0) AS run_date
),

filtered AS (
    SELECT
        ID,
        StartTime,
        EndTime,
        -- normalize comments: trim + lowercase + collapse multiple spaces
        regexp_replace(lower(trim(Comments)), '\\s+', ' ') AS Comments,
        etr_ymd,
        row_number() OVER (
            PARTITION BY 
                        etr_ymd,
                         regexp_replace(lower(trim(Comments)), '\\s+', ' ')
            ORDER BY
                        (StartTime IS NULL) ASC,   -- non-NULL first
                        (EndTime   IS NULL) ASC,   -- non-NULL first
                        StartTime           DESC,  -- latest time
                        EndTime             DESC   -- latest end
        ) AS rn
    FROM main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog t
    CROSS JOIN run_date r
    WHERE to_date(etr_ymd) = r.run_date
)

-- 1) Real rows for yesterday (deduplicated)
SELECT
    ID,
    StartTime,
    EndTime,
    Comments,
    etr_ymd,
    current_timestamp() AS UpdateDate
FROM filtered
WHERE rn = 1

UNION ALL

-- 2) Fallback row when there are NO results for yesterday
SELECT
    CAST(NULL AS BIGINT)    AS ID,
    CAST(NULL AS TIMESTAMP) AS StartTime,
    CAST(NULL AS TIMESTAMP) AS EndTime,
    'No actions for ' || CAST(r.run_date AS STRING) AS Comments,
    r.run_date              AS etr_ymd,
    current_timestamp()     AS UpdateDate
FROM run_date r
WHERE NOT EXISTS (SELECT 1 FROM filtered WHERE rn = 1)
