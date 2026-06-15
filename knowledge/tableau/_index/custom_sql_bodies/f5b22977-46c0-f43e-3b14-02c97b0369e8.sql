WITH pop AS (
    -- 1. Identify the core user cohort and their first journey / amount / journey date
    WITH FirstJourney AS (
        SELECT
            sfmc.GCID,
            dc.RealCID,
            ROUND(dp.Amount, 0) AS Amount,
            sfmc.Journey_Name AS FirstJourney,
            CAST(
                regexp_replace(SUBSTRING(CAST(sfmc.etr_ymd AS STRING), 1, 10), '-', '')
                AS INT
            ) AS FirstJourneyDateID,
            CAST(
                regexp_replace(SUBSTRING(CAST(sfmc.etr_ym AS STRING), 1, 7), '-', '')
                AS INT
            ) AS FirstJourneyMonthID
        FROM main.sfmc.silver_sfmc_accountjourneylogtracking sfmc
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
            ON sfmc.GCID = dc.GCID
        JOIN main.dwh.dim_position dp
            ON dc.RealCID = dp.CID
           AND dp.OpenDateID >= 20250820
           AND dp.IsAirDrop = 1
        WHERE sfmc.Journey_Name IN (
            '202507039328_InjectAirdrop_200825',
            '202507039328_InjectAirdrop_210825',
            '202507039328_InjectAirdrop_250825',
            '202507039328_InjectAirdrop_260825',
            '202507039328_InjectAirdrop_270825',
            '202507039328_InjectAirdropLANG_110925_Email',
            '202507039328_InjectAirdrop_180925',
            '202507039328_InjectAirdrop_300925',
            '202507039328_InjectAirdrop_231025',
            '202507039328_InjectAirdrop_301025',
            '202507039328_InjectAirdrop_261125',
            --'202507039328_InjectAirdrop_191225',
            -- '202507039328_InjectAirdropHolidays_241225',
            '202507039328_InjectAirdropHolidays_301225',
            '202507039328_InjectAirdrop_280126',
            '202507039328_InjectAirdrop_260226',
            '202507039328_InjectAirdrop_240326',
'202507039328_InjectAirdrop_310326',
'202507039328_InjectAirdrop_270426',
'202507039328_InjectAirdrop_140526'
        )
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY dc.RealCID, ROUND(dp.Amount, 0)
            ORDER BY sfmc.etr_ymd
        ) = 1
    )
    SELECT DISTINCT
        fj.RealCID,
        fj.FirstJourney AS Journey_Name,
        fj.Amount,
        fj.FirstJourneyDateID,
        fj.FirstJourneyMonthID,
        CAST(
            DATE_FORMAT(
                DATE_ADD(TO_DATE(CAST(fj.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 7),
                'yyyyMMdd'
            ) AS INT
        ) AS FirstJourneyDateID_7D,
        CAST(
            DATE_FORMAT(
                DATE_ADD(TO_DATE(CAST(fj.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 14),
                'yyyyMMdd'
            ) AS INT
        ) AS FirstJourneyDateID_14D,
        CAST(
            DATE_FORMAT(
                DATE_ADD(TO_DATE(CAST(fj.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 30),
                'yyyyMMdd'
            ) AS INT
        ) AS FirstJourneyDateID_30D
    FROM FirstJourney fj
),

MonthlyPanelData AS (
    -- 2. Monthly panel snapshot
    SELECT
        CID,
        NewMarketingRegion,
        ClusterDetail,
        EOM_Club,
        EOM_Equity,
        CASE WHEN IsEOM_Funded_NEW = 1 THEN 1 ELSE 0 END AS IsFundedFlag
    FROM main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata
    WHERE Active_Month = 202605
),

LoggedUsers AS (
    -- 3. Login flags AFTER each row's first journey date
    SELECT
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID,

        MAX(CASE WHEN le.RealCID IS NOT NULL THEN 1 ELSE 0 END) AS IsLoggedIn,

        MAX(
            CASE
                WHEN le.DateID >= p.FirstJourneyDateID
                 AND le.DateID <= p.FirstJourneyDateID_7D
                THEN 1 ELSE 0
            END
        ) AS IsLoggedIn_7D,

        MAX(
            CASE
                WHEN le.DateID >= p.FirstJourneyDateID
                 AND le.DateID <= p.FirstJourneyDateID_14D
                THEN 1 ELSE 0
            END
        ) AS IsLoggedIn_14D,

        MAX(
            CASE
                WHEN le.DateID >= p.FirstJourneyDateID
                 AND le.DateID <= p.FirstJourneyDateID_30D
                THEN 1 ELSE 0
            END
        ) AS IsLoggedIn_30D

    FROM pop p
    LEFT JOIN (
        SELECT
            dc.RealCID,
            l.DateID
        FROM main.mixpanel.login_events l
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
            ON l.GCID = dc.GCID
        WHERE dc.IsValidCustomer = 1

        UNION ALL

        SELECT
            fca.RealCID,
            fca.DateID
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
        WHERE fca.ActionTypeID = 14
    ) le
        ON p.RealCID = le.RealCID
       AND le.DateID >= p.FirstJourneyDateID
    GROUP BY
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID
),

ActionFlags AS (
    -- 4. Position-based flags AFTER each row's first journey date
    SELECT
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID,

        MAX(
            CASE
                WHEN COALESCE(dp.IsAirDrop, 0) = 1
                 AND dp.CloseDateID IS NOT NULL
                 AND dp.CloseDateID >= p.FirstJourneyDateID
                THEN 1 ELSE 0
            END
        ) AS HasClosedAirdrop,

        MAX(
            CASE
                WHEN COALESCE(dp.IsAirDrop, 0) = 0
                 AND dp.OpenDateID >= p.FirstJourneyDateID
                THEN 1 ELSE 0
            END
        ) AS HasOpenedNonAirdrop,

        MAX(
            CASE
                WHEN COALESCE(dp.IsAirDrop, 0) = 0
                 AND dp.OpenDateID >= p.FirstJourneyDateID
                 AND dp.OpenDateID <= p.FirstJourneyDateID_7D
                THEN 1 ELSE 0
            END
        ) AS HasOpenedNonAirdrop_7D,

        MAX(
            CASE
                WHEN COALESCE(dp.IsAirDrop, 0) = 0
                 AND dp.OpenDateID >= p.FirstJourneyDateID
                 AND dp.OpenDateID <= p.FirstJourneyDateID_14D
                THEN 1 ELSE 0
            END
        ) AS HasOpenedNonAirdrop_14D,

        MAX(
            CASE
                WHEN COALESCE(dp.IsAirDrop, 0) = 0
                 AND dp.OpenDateID >= p.FirstJourneyDateID
                 AND dp.OpenDateID <= p.FirstJourneyDateID_30D
                THEN 1 ELSE 0
            END
        ) AS HasOpenedNonAirdrop_30D

    FROM pop p
    LEFT JOIN main.dwh.dim_position dp
        ON p.RealCID = dp.CID
    GROUP BY
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID
),

TxnFlags AS (
    -- 5. Deposit / cashout flags AFTER each row's first journey date
    SELECT
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID,

        MAX(
            CASE
                WHEN fca.ActionTypeID = 7
                 AND fca.DateID >= p.FirstJourneyDateID
                THEN 1 ELSE 0
            END
        ) AS HasDeposited,

        MAX(
            CASE
                WHEN fca.ActionTypeID = 7
                 AND fca.DateID >= p.FirstJourneyDateID
                 AND fca.DateID <= p.FirstJourneyDateID_7D
                THEN 1 ELSE 0
            END
        ) AS HasDeposited_7D,

        MAX(
            CASE
                WHEN fca.ActionTypeID = 7
                 AND fca.DateID >= p.FirstJourneyDateID
                 AND fca.DateID <= p.FirstJourneyDateID_14D
                THEN 1 ELSE 0
            END
        ) AS HasDeposited_14D,

        MAX(
            CASE
                WHEN fca.ActionTypeID = 7
                 AND fca.DateID >= p.FirstJourneyDateID
                 AND fca.DateID <= p.FirstJourneyDateID_30D
                THEN 1 ELSE 0
            END
        ) AS HasDeposited_30D,

        MAX(
            CASE
                WHEN fca.ActionTypeID = 8
                 AND fca.DateID >= p.FirstJourneyDateID
                THEN 1 ELSE 0
            END
        ) AS HasCashedOut

    FROM pop p
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
        ON p.RealCID = fca.RealCID
    GROUP BY
        p.RealCID,
        p.Journey_Name,
        p.Amount,
        p.FirstJourneyDateID
),

-- RevenueBuckets commented out due to Azure storage firewall blocking access to main.bi_output.bi_output_vg_revenue
 RevenueBuckets AS (
     -- 6. Revenue within 7 / 14 / 30 days and total AFTER each row's first journey date
     SELECT
         p.RealCID,
         p.Journey_Name,
         p.Amount,
         p.FirstJourneyDateID,
         SUM(CASE
                 WHEN b.DateID >= p.FirstJourneyDateID
                  AND b.DateID <= CAST(DATE_FORMAT(DATE_ADD(TO_DATE(CAST(p.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 7), 'yyyyMMdd') AS INT)
                 THEN b.Amount ELSE 0
             END) AS Revenue_7d,
         SUM(CASE
                 WHEN b.DateID >= p.FirstJourneyDateID
                  AND b.DateID <= CAST(DATE_FORMAT(DATE_ADD(TO_DATE(CAST(p.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 14), 'yyyyMMdd') AS INT)
                 THEN b.Amount ELSE 0
             END) AS Revenue_14d,
         SUM(CASE
                 WHEN b.DateID >= p.FirstJourneyDateID
                  AND b.DateID <= CAST(DATE_FORMAT(DATE_ADD(TO_DATE(CAST(p.FirstJourneyDateID AS STRING), 'yyyyMMdd'), 30), 'yyyyMMdd') AS INT)
                 THEN b.Amount ELSE 0
             END) AS Revenue_30d,
         SUM(CASE
                 WHEN b.DateID >= p.FirstJourneyDateID
                 THEN b.Amount ELSE 0
             END) AS TotalRevenue
     FROM pop p
     LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions b
         ON p.RealCID = b.RealCID
        AND b.IncludedInTotalRevenue = TRUE
     GROUP BY
         p.RealCID,
         p.Journey_Name,
         p.Amount,
         p.FirstJourneyDateID
 )

-- Final Select Statement
SELECT
    p.RealCID AS CID,
    p.Journey_Name,
    p.Amount,
    p.FirstJourneyDateID,  -- keep for QA; remove later if not needed
    mpd.NewMarketingRegion,
    mpd.ClusterDetail,
    mpd.EOM_Club,
    mpd.EOM_Equity,
    COALESCE(lu.IsLoggedIn, 0) AS IsLoggedIn,
    COALESCE(lu.IsLoggedIn_7d, 0) AS IsLoggedIn_7d,
    COALESCE(lu.IsLoggedIn_14d, 0) AS IsLoggedIn_14d,
    COALESCE(lu.IsLoggedIn_30d, 0) AS IsLoggedIn_30d,
    COALESCE(af.HasClosedAirdrop, 0) AS HasClosedAirdrop,
    COALESCE(af.HasOpenedNonAirdrop, 0) AS HasOpenedNonAirdrop,
    COALESCE(af.HasOpenedNonAirdrop_7d, 0) AS HasOpenedNonAirdrop_7d,
    COALESCE(af.HasOpenedNonAirdrop_14d, 0) AS HasOpenedNonAirdrop_14d,
    COALESCE(af.HasOpenedNonAirdrop_30d, 0) AS HasOpenedNonAirdrop_30d,
    COALESCE(tf.HasDeposited, 0) AS HasDeposited,
    COALESCE(tf.HasDeposited_7d, 0) AS HasDeposited_7d,
    COALESCE(tf.HasDeposited_14d, 0) AS HasDeposited_14d,
    COALESCE(tf.HasDeposited_30d, 0) AS HasDeposited_30d,
    COALESCE(tf.HasCashedOut, 0) AS HasCashedOut,
    COALESCE(rv.Revenue_7d, 0) AS Revenue_7d,
    COALESCE(rv.Revenue_14d, 0) AS Revenue_14d,
    COALESCE(rv.Revenue_30d, 0) AS Revenue_30d,
    COALESCE(rv.TotalRevenue, 0) AS TotalRevenue,
    COALESCE(mpd.IsFundedFlag, 0) AS IsFunded
FROM pop p
LEFT JOIN MonthlyPanelData mpd
    ON p.RealCID = mpd.CID
LEFT JOIN LoggedUsers lu
    ON p.RealCID = lu.RealCID
   AND p.Journey_Name = lu.Journey_Name
   AND p.Amount = lu.Amount
   AND p.FirstJourneyDateID = lu.FirstJourneyDateID
LEFT JOIN ActionFlags af
    ON p.RealCID = af.RealCID
   AND p.Journey_Name = af.Journey_Name
   AND p.Amount = af.Amount
   AND p.FirstJourneyDateID = af.FirstJourneyDateID
LEFT JOIN TxnFlags tf
    ON p.RealCID = tf.RealCID
   AND p.Journey_Name = tf.Journey_Name
   AND p.Amount = tf.Amount
   AND p.FirstJourneyDateID = tf.FirstJourneyDateID
LEFT JOIN RevenueBuckets rv
    ON p.RealCID = rv.RealCID
   AND p.Journey_Name = rv.Journey_Name
   AND p.Amount = rv.Amount
   AND p.FirstJourneyDateID = rv.FirstJourneyDateID
WHERE p.Amount IN (10, 15, 25, 50, 100, 200)