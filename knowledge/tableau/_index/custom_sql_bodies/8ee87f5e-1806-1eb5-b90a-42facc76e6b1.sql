SELECT
    c.Name AS Country,
    Cast(dc.RegisteredReal AS DATE) AS RegisteredReal,
    ss.Name as ScreeningStatus,
    COUNT(DISTINCT dc.RealCID) AS TotalUsers
  
FROM dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c ON c.CountryID = dc.CountryID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ss on ss.ScreeningStatusID = dc.ScreeningStatusID
WHERE 
    CAST(dc.RegisteredReal AS DATE) >= date_add(current_date(), -60)
    and dc.VerificationLevelID in (2,3)
    and dc.IsValidCustomer = 1
GROUP BY 
    c.Name
    ,Cast(dc.RegisteredReal AS DATE)
    ,ss.Name