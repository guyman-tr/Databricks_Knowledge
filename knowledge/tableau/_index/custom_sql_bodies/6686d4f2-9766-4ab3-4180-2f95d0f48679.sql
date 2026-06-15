WITH journeys_dedup AS (
    SELECT
        GCID,
        Journey_Name,
        Action,
        etr_ymd AS Journey_Entry_Date
    FROM (
        SELECT
            sfmc.GCID,
            sfmc.Journey_Name,
            sfmc.Action,
            sfmc.etr_ymd,
            ROW_NUMBER() OVER (
                PARTITION BY sfmc.GCID
                ORDER BY
                    
                    CASE
                        WHEN sfmc.Journey_Name = 'TriggeredSendDataExtension - 10778470275_NewYearTieredBonus_StockSelected'
                            THEN 1
                        ELSE 2
                    END,
                  
                    sfmc.etr_ymd ASC,
                   
                    CASE
                        WHEN sfmc.Action LIKE '%Test%' THEN 1
                        WHEN sfmc.Action LIKE '%Control%' THEN 1
                        WHEN sfmc.Action = 'Email' THEN 2
                        ELSE 3
                    END
            ) AS rn
        FROM main.sfmc.silver_sfmc_accountjourneylogtracking sfmc
        WHERE sfmc.Journey_Name like '%NewYearTieredBonus%'
    )
    WHERE rn = 1
),

journeys_with_cid AS (
    SELECT
        j.GCID,
        dcm.RealCID AS CID,
        j.Journey_Name,
        j.Action,
        j.Journey_Entry_Date
    FROM journeys_dedup j
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcm
        ON j.GCID = dcm.GCID
),

deposits AS (
    SELECT
        j.GCID,
        j.CID,
        MAX(mp.RegMonth) AS RegMonth,
        SUM(mp.ACC_TotalDeposits) AS Total_Deposit_Amount
    FROM journeys_with_cid j
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata mp
        ON j.CID = mp.CID
    GROUP BY j.GCID, j.CID
),

last_position AS (
    SELECT
        GCID,
        CID,
        InstrumentID AS Last_Stock_Instrument,
        OpenDateID AS Last_Stock_Picked_Date
    FROM (
        SELECT
            j.GCID,
            j.CID,
            p.InstrumentID,
            p.OpenDateID,
            ROW_NUMBER() OVER (
                PARTITION BY j.GCID
                ORDER BY p.OpenDateID DESC
            ) AS rn
        FROM journeys_with_cid j
        LEFT JOIN main.dwh.dim_position p
            ON j.CID = p.CID
           AND p.OpenDateID >= CAST(REPLACE(j.Journey_Entry_Date, '-', '') AS INT)
    )
    WHERE rn = 1
)


SELECT
    j.GCID,
    j.CID,
    j.Journey_Name,
    --d.Total_Deposit_Amount,
        CASE
         WHEN d.Total_Deposit_Amount <=200  THEN '< $ 200'
        WHEN d.Total_Deposit_Amount < 500  AND d.Total_Deposit_Amount >= 200  THEN '$ 200 - $ 499'
        WHEN d.Total_Deposit_Amount < 2500 AND d.Total_Deposit_Amount >= 500  THEN '$ 500 - $ 2,499'
        WHEN d.Total_Deposit_Amount < 5000 AND d.Total_Deposit_Amount >= 2500 THEN '$ 2,500 - $ 4,999'
        WHEN d.Total_Deposit_Amount >= 5000 THEN '$ 5000+'
        ELSE NULL
    END AS Deposit_Amount_Tier,
    CASE
        WHEN j.Action LIKE '%Control%' THEN 'Control'
        ELSE 'Test'
    END AS Segment,
    lp.Last_Stock_Instrument,
    di.InstrumentTypeID,
    di.InstrumentType,
    di.Name,
    di.Symbol,
    CASE
        WHEN d.Total_Deposit_Amount < 500  AND d.Total_Deposit_Amount >= 200  THEN '10'
        WHEN d.Total_Deposit_Amount < 2500 AND d.Total_Deposit_Amount >= 500  THEN '30'
        WHEN d.Total_Deposit_Amount < 5000 AND d.Total_Deposit_Amount >= 2500 THEN '200'
        WHEN d.Total_Deposit_Amount >= 5000 THEN '500'
        ELSE 'Not Eligible'
    END AS Eligible_Amount,
    lp.Last_Stock_Picked_Date,
    j.Journey_Entry_Date
FROM journeys_with_cid j
LEFT JOIN deposits d
    ON j.GCID = d.GCID
LEFT JOIN last_position lp
    ON j.GCID = lp.GCID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON lp.Last_Stock_Instrument = di.InstrumentID