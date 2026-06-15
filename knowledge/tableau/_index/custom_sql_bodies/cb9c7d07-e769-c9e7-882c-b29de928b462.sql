SELECT 
    COUNT(DISTINCT bdsr.GCID) as TargetedUsers,
    s.TotalOptOuts,
    s.NewOptOuts,
    COUNT(DISTINCT bdsr.CampaignNumber) as UniqueCampaigns,
    LEFT(bdsr.SendDateID, 6) as YearMonth,
    u.TotalUsers
FROM main.bi_output.bi_output_marketing_sfmc_sfmc_report bdsr
LEFT JOIN  

(
    SELECT CONCAT(LEFT(dc.BeginDate, 4), SUBSTRING(dc.BeginDate, 6,2)) as YearMonth ,
            COUNT(*) AS NewOptOuts,
            SUM(COUNT(*)) OVER (ORDER BY CONCAT(LEFT(dc.BeginDate, 4), SUBSTRING(dc.BeginDate, 6,2))) AS TotalOptOuts
        FROM main.general.bronze_settingsdb_settings_customerdata dc 
        WHERE ResourceId = 5564
            AND SelectedValue IN (2, 4)
        GROUP BY CONCAT(LEFT(dc.BeginDate, 4), SUBSTRING(dc.BeginDate, 6,2))
) s

ON  s.YearMonth = LEFT(bdsr.SendDateID, 6)


            --    (
            --       SELECT 
            --        Gcid,
            --        CONCAT(LEFT(BeginDate, 4),SUBSTRING(BeginDate, 6,2)) as YearMonth 
            --        FROM main.general.bronze_settingsdb_settings_customerdata
            --        WHERE ResourceId = 5564
            --        AND SelectedValue IN (2, 4)
            --    ) s
            --    ON bdsr.GCID = s.Gcid
            --        AND s.YearMonth = LEFT(bdsr.SendDateID, 6)
JOIN 
(
    SELECT YearMonth, NewUsers, TotalUsers
    FROM (
        SELECT
            
            CONCAT(LEFT(dc.RegisteredReal, 4), SUBSTRING(dc.RegisteredReal, 6,2)) as YearMonth ,
            COUNT(*) AS NewUsers,
            SUM(COUNT(*)) OVER (ORDER BY CONCAT(LEFT(dc.RegisteredReal, 4), SUBSTRING(dc.RegisteredReal, 6,2))) AS TotalUsers
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
        WHERE dc.IsValidCustomer=1
        GROUP BY CONCAT(LEFT(dc.RegisteredReal, 4), SUBSTRING(dc.RegisteredReal, 6,2))
    ) a
) u
ON u.YearMonth = LEFT(bdsr.SendDateID, 6)
WHERE 
    bdsr.etr_ym >= dateadd(month, -6, current_date())
AND bdsr.etr_ym >='2024-01'
GROUP BY     
    s.TotalOptOuts,
    s.NewOptOuts,
    LEFT(bdsr.SendDateID, 6),
    u.TotalUsers