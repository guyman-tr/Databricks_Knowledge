-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_population_first_time_funded
-- Captured: 2026-05-18T08:08:42Z
-- ==========================================================================

WITH First_IOB AS (
    SELECT
        RealCID,
        MIN(Occurred) AS FirstIOBTime,
        CAST(MIN(Occurred) AS DATE) AS FirstIOBDate,
        MIN(CAST(DATE_FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT)) AS FirstIOBDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
    WHERE ActionTypeID = 36
      AND CompensationReasonID = 57
    GROUP BY RealCID
),
REMOVE_BAD_FTDS AS (
    SELECT
        dc.RealCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
        TO_DATE('20250818', 'yyyyMMdd'),
        TO_DATE('20250819', 'yyyyMMdd'),
        TO_DATE('20250820', 'yyyyMMdd')
    )
    AND dc.FirstDepositAmount = 1
    AND dc.RealCID NOT IN (
        SELECT map.RealCID
        FROM main.etoro_kpi_prep.v_mimo_allplatforms map
        WHERE map.MIMOAction = 'Deposit'
        GROUP BY map.RealCID
        HAVING COUNT(map.RealCID) > 1
    )
),
DWH_FTD AS (
    SELECT
        ftd.FTDPlatformID,
        ftd.Name as FTDPlatform,
        dc.RealCID,
        dc.FirstDepositDate AS FTDTime,
        CAST(dc.FirstDepositDate AS DATE) AS FTDDate,
        CAST(DATE_FORMAT(dc.FirstDepositDate, 'yyyyMMdd') AS INT) AS FTDDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN main.etoro_kpi_prep.v_globalftdplatform ftd
        ON ftd.FTDPlatformID = dc.FTDPlatformID
    WHERE dc.IsDepositor = 1
      AND dc.RealCID NOT IN (SELECT RealCID FROM REMOVE_BAD_FTDS)
),
Verification AS (
    SELECT
        fsc.RealCID,
        TO_DATE(CAST(MIN(fsc.FromDateID) AS STRING), 'yyyyMMdd') AS FirstVerifiedDate,
        MIN(fsc.FromDateID) AS FirstVerifiedDateID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    WHERE fsc.VerificationLevelID = 3
    GROUP BY fsc.RealCID
),
Trade AS (
    SELECT
        CID AS RealCID,
        MIN(OpenOccurred) AS FirstTradeTime,
        TO_DATE(CAST(MIN(OpenDateID) AS STRING), 'yyyyMMdd') AS FirstTradeDate,
        MIN(OpenDateID) AS FirstTradeDateID
    FROM main.dwh.dim_position
    WHERE IFNULL(IsAirDrop, 0) = 0
    GROUP BY CID
),
OptionsTrade AS (
    SELECT
        op.RealCID,
        MIN(op.FirstTradeDate) AS FirstOptionsTradeDate,
        MIN(op.FirstTradeDateID) AS FirstOptionsTradeDateID
    FROM main.etoro_kpi_prep.v_revenue_optionsplatform op
    GROUP BY op.RealCID
)
SELECT
    f.RealCID,

    -- FTD
    f.FTDPlatformID,
    f.FTDPlatform,
    f.FTDDateID,
    f.FTDDate,
    f.FTDTime,

    -- Trades & Activities
    t.FirstTradeDateID,
    t.FirstTradeDate,
    t.FirstTradeTime,
    iob.FirstIOBDateID,
    iob.FirstIOBDate,
    iob.FirstIOBTime,
    ot.FirstOptionsTradeDateID,
    ot.FirstOptionsTradeDate,

    -- Verification
    v.FirstVerifiedDateID,
    v.FirstVerifiedDate,

    -- First Funded (Latest of FTD, Activity, Verification)
    GREATEST(
        f.FTDDateID,
        v.FirstVerifiedDateID,
        COALESCE(
            LEAST(
                t.FirstTradeDateID,
                iob.FirstIOBDateID,
                ot.FirstOptionsTradeDateID
            ),
            COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
        )
    ) AS FirstFundedDateID,

    TO_DATE(
        CAST(
            GREATEST(
                f.FTDDateID,
                v.FirstVerifiedDateID,
                COALESCE(
                    LEAST(
                        t.FirstTradeDateID,
                        iob.FirstIOBDateID,
                        ot.FirstOptionsTradeDateID
                    ),
                    COALESCE(t.FirstTradeDateID, iob.FirstIOBDateID, ot.FirstOptionsTradeDateID)
                )
            ) AS STRING
        ),
        'yyyyMMdd'
    ) AS FirstFundedDate

FROM DWH_FTD f
INNER JOIN Verification v
    ON f.RealCID = v.RealCID
LEFT JOIN Trade t
    ON f.RealCID = t.RealCID
LEFT JOIN First_IOB iob
    ON f.RealCID = iob.RealCID
LEFT JOIN OptionsTrade ot
    ON f.RealCID = ot.RealCID

WHERE 
    (t.FirstTradeDateID IS NOT NULL
     OR iob.FirstIOBDateID IS NOT NULL
     OR ot.FirstOptionsTradeDateID IS NOT NULL)
