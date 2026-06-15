SELECT 
    count(dp.CID) as TotalClients,
    to_date(dp.ModificationDate) as FirstDepositDate,
    us.IsOngoingCase,
    c.VerificationLevelID,
    pl.Name as Club,
    r.Name as Regulation,
    cast(us.LastUpdateDate as date) as ScreeningStatus_UpdateDate,
    co.Name as Country,c.VerificationLevelID
FROM 
    main.billing.bronze_etoro_billing_deposit dp
LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c on dp.CID = c.RealCID
LEFT JOIN 
    main.bi_db.bronze_screeningservice_screening_userscreening us on us.CID = c.RealCID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on c.PlayerLevelID = pl.PlayerLevelID
LEFT JOIN 
    main.general.bronze_etoro_dictionary_regulation r on c.RegulationID = r.ID

LEFT JOIN 
    main.general.bronze_etoro_dictionary_country co on c.CountryID = co.CountryID
WHERE 
    dp.IsFTD = true
    and dp.ModificationDate >= '2025-01-01'
    and c.PlayerStatusID not in (2,4)
GROUP BY 
    to_date(dp.ModificationDate),
    us.IsOngoingCase,
    c.VerificationLevelID,
    pl.Name,
    r.Name,
    co.Name,
    cast(us.LastUpdateDate as date)