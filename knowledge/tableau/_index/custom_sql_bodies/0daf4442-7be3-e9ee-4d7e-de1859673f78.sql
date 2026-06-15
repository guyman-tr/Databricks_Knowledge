SELECT
    c.Name AS KYCCountry,
    CAST(dc.Registered AS DATE) as RegisteredReal,
    v.VerificationLevelID,
    c1.Name as CountryByIP,
    COUNT(DISTINCT dc.CID) AS `#ofRegs`
  
FROM 
    general.bronze_etoro_customer_customer_masked dc
JOIN 
    general.bronze_etoro_backoffice_customer v ON v.CID = dc.CID
LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c ON c.CountryID = dc.CountryID
LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c1 ON c1.CountryID = dc.CountryIDByIP
WHERE 
    CAST(dc.Registered AS DATE) >= date_add(current_date(), -60)
GROUP BY 
    c.Name,
    CAST(dc.Registered AS DATE),
    c1.Name,
    v.VerificationLevelID