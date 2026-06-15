WITH latest_stocks AS (
    SELECT 
        sfmc.GCID,
        sfmc.Journey_Name AS Stock_Journey,
        sfmc.Message AS Last_Stock_Picked,
        sfmc.etr_ymd AS Last_Stock_Picked_Date,
        ROW_NUMBER() OVER (
            PARTITION BY sfmc.GCID 
            ORDER BY sfmc.etr_ymd DESC
        ) as rn
    FROM main.sfmc.silver_sfmc_accountjourneylogtracking sfmc
    WHERE sfmc.Journey_Name = 'TriggeredSendDataExtension - 10778470275_NewYearTieredBonus_StockSelected'
      AND sfmc.Action = 'StockPicked'
),

first_journey_segment AS (
    -- Identify the first journey for EVERY user, but segment ONLY Test/Control
    SELECT 
        sfmc.GCID,
        sfmc.Journey_Name AS First_Journey,
        -- Segment logic is now isolated here
        CASE 
            WHEN sfmc.Message LIKE '%Control%' THEN 'Control'
            WHEN sfmc.Message LIKE '%Test%' THEN 'Test'
            ELSE NULL 
        END AS Segment,
        ROW_NUMBER() OVER (
            PARTITION BY sfmc.GCID 
            ORDER BY sfmc.etr_ymd ASC
        ) as rn_first
    FROM main.sfmc.silver_sfmc_accountjourneylogtracking sfmc
    WHERE (sfmc.Journey_Name LIKE '%NewYearTieredBonus%'
        OR sfmc.Journey_Name LIKE '10875638955_%')
    -- Filter on Action is REMOVED from here to capture all users
),

base_with_details AS (
    SELECT 
        ls.GCID,
        ls.Stock_Journey,
        ls.Last_Stock_Picked,
        ls.Last_Stock_Picked_Date,
        fjs.First_Journey,
        fjs.Segment,
        dcm.RealCID AS CID 
    FROM latest_stocks ls
    LEFT JOIN first_journey_segment fjs 
      ON ls.GCID = fjs.GCID AND fjs.rn_first = 1
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcm 
      ON ls.GCID = dcm.GCID
    WHERE ls.rn = 1
),

deposits AS (
    SELECT
        b.GCID,
        SUM(mp.ACC_TotalDeposits) AS Total_Deposit_Amount
    FROM base_with_details b
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata mp 
      ON b.CID = mp.CID
    GROUP BY b.GCID
)

SELECT
    u.GCID,
    u.First_Journey,
    u.Segment,
    u.Stock_Journey AS Journey_Name,
    u.Last_Stock_Picked,
    u.Last_Stock_Picked_Date,
    COALESCE(d.Total_Deposit_Amount, 0) AS Total_Deposit_Amount,
    
    CASE
        WHEN d.Total_Deposit_Amount < 200 THEN '< $ 200'
        WHEN d.Total_Deposit_Amount < 500 THEN '$ 200 - $ 499'
        WHEN d.Total_Deposit_Amount < 2500 THEN '$ 500 - $ 2,499'
        WHEN d.Total_Deposit_Amount < 5000 THEN '$ 2,500 - $ 4,999'
        WHEN d.Total_Deposit_Amount >= 5000 THEN '$ 5000+'
        ELSE 'No Deposit'
    END AS Deposit_Amount_Tier,

    CASE
        WHEN d.Total_Deposit_Amount >= 200 AND d.Total_Deposit_Amount < 500 THEN '10'
        WHEN d.Total_Deposit_Amount >= 500 AND d.Total_Deposit_Amount < 2500 THEN '30'
        WHEN d.Total_Deposit_Amount >= 2500 AND d.Total_Deposit_Amount < 5000 THEN '200'
        WHEN d.Total_Deposit_Amount >= 5000 THEN '500'
        ELSE 'Not Eligible'
    END AS Eligible_Amount
FROM base_with_details u
LEFT JOIN deposits d ON u.GCID = d.GCID