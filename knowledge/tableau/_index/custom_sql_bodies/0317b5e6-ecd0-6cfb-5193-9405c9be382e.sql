SELECT DISTINCT 
    a.Date, 
    a.CID,
    a.DateID,
    a.BonusCredit,
    a.RealizedEquity,
    a.TotalPositionsAmount,
    a.TotalCash,
    a.TotalMirrorPositionsAmount,
    a.TotalMirrorCash,
    a.Credit,
    a.CopyPositionPnL,
    a.All_Positions_PNL,
    a.CountryID,
    a.Country,
    a.etr_ymd,
    a.etr_y,
    a.etr_ym
FROM main.trading.gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report AS a
JOIN main.general.bronze_etoro_backoffice_customer AS bc 
    ON a.CID = bc.CID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS d 
    ON a.CID = d.RealCID
WHERE 
    (a.CountryID = 250 OR a.CountryID = 219)
    AND d.PlayerStatusID = 10
    AND (bc.AccountTypeID = 7 OR bc.AccountTypeID = 13)
    AND bc.MasterAccountCID = 10717251