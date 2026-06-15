SELECT 
    r.RedeemID,
    r.CID,
    r.AmountOnRequest,
    i.InstrumentDisplayName AS Instrument,
    r.LastModificationDate,
    pl.Name AS PlayerLevel,
    rs.DisplayName AS RedeemStatus,
    v.ActualNWA,
    p.InitialUnits AS Units,
    re.Name AS Regulation,
    COALESCE(COALESCE(p.Amount, 0) + COALESCE(p.PnLInDollars, 0), 0) AS CurrentValue
FROM 
    main.billing.bronze_etoro_billing_redeem r
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.RealCID = r.CID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl ON pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation re ON re.ID = dc.RegulationID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities v ON v.CID = r.CID 
    AND v.DateID = DATE_FORMAT(CURRENT_DATE() - INTERVAL 1 DAY, 'yyyyMMdd')
LEFT JOIN 
    main.dwh.dim_position p ON p.PositionID = r.PositionID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument i ON i.InstrumentID = p.InstrumentID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus rs ON rs.RedeemStatusID = r.RedeemStatusID
WHERE 
    TO_DATE(r.LastModificationDate) >= DATE_SUB(CURRENT_DATE(), 30)
    AND TO_DATE(r.LastModificationDate) <= CURRENT_DATE()
    AND r.RedeemStatusID = 1
    AND i.InstrumentDisplayName IS NOT NULL