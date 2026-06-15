WITH JourneyBase AS (
    -- Base journey population with airdrop amount
    SELECT
        sfmc.GCID,
        dc.RealCID,
        sfmc.Journey_Name,
        CAST(sfmc.etr_ymd AS TIMESTAMP) AS JourneyTS,
        dp.Amount AS Airdrop_Amount
    FROM main.sfmc.silver_sfmc_accountjourneylogtracking sfmc
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON sfmc.GCID = dc.GCID
    LEFT JOIN main.dwh.dim_position dp
        ON dp.CID = dc.RealCID
       AND dp.IsAirDrop = 1
       AND dp.OpenDateID = CAST(date_format(CAST(sfmc.etr_ymd AS TIMESTAMP), 'yyyyMMdd') AS INT)
    WHERE sfmc.Journey_Name in ('202507039328_InjectAirdrop_270426',
    '202507039328_InjectAirdrop_140526')
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY sfmc.GCID
        ORDER BY sfmc.etr_ymd, dp.OpenDateID
    ) = 1
),

LoginEvents AS (
    -- Unified login timestamps
    SELECT
        dc.RealCID,
        l.TimeStamp AS LoginTS
    FROM main.mixpanel.login_events l
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON l.GCID = dc.GCID
    WHERE dc.IsValidCustomer = 1

    UNION ALL

    SELECT
        fca.RealCID,
        fca.Occurred AS LoginTS
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
    WHERE fca.ActionTypeID = 14
),

FirstLogin AS (
    -- First login AFTER journey timestamp
    SELECT
        jb.RealCID,
        MIN(le.LoginTS) AS FirstLoginTS
    FROM JourneyBase jb
    LEFT JOIN LoginEvents le
        ON le.RealCID = jb.RealCID
       AND le.LoginTS > jb.JourneyTS
    GROUP BY jb.RealCID
),

FirstNonAirdropOP AS (
    -- First non-airdrop position opened AFTER journey timestamp
    SELECT
        jb.RealCID,
        MIN(to_timestamp(CAST(dp.OpenDateID AS STRING), 'yyyyMMdd')) AS FirstNonAirdropTS
    FROM JourneyBase jb
    LEFT JOIN main.dwh.dim_position dp
        ON dp.CID = jb.RealCID
       AND COALESCE(dp.IsAirDrop, 0) = 0
       AND dp.OpenDateID > CAST(date_format(jb.JourneyTS, 'yyyyMMdd') AS INT)
    GROUP BY jb.RealCID
),

FirstDeposit AS (
    -- First deposit AFTER journey timestamp
    SELECT
        jb.RealCID,
        MIN(fca.Occurred) AS FirstDepositTS
    FROM JourneyBase jb
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
        ON fca.RealCID = jb.RealCID
       AND fca.ActionTypeID = 7
       AND fca.Occurred > jb.JourneyTS
    GROUP BY jb.RealCID
),

Final AS (
    SELECT
        jb.GCID,
        jb.Journey_Name,
        jb.JourneyTS                    AS Journey_Timestamp,
        jb.Airdrop_Amount,
        fl.FirstLoginTS                 AS First_Login_After_Journey,
        fop.FirstNonAirdropTS           AS First_NonAirdrop_OP_After_Journey,
        fd.FirstDepositTS               AS First_Deposit_After_Journey
    FROM JourneyBase jb
    LEFT JOIN FirstLogin fl        ON jb.RealCID = fl.RealCID
    LEFT JOIN FirstNonAirdropOP fop ON jb.RealCID = fop.RealCID
    LEFT JOIN FirstDeposit fd      ON jb.RealCID = fd.RealCID
)

SELECT * FROM Final