SELECT 
    rol.Region,
    di.SellCurrencyID, 
    di.InstrumentType, 
    cus.AccountTypeID, 
    dp.IsSettled, 
    dp.CID, 
    CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END AS Has_IBAN_Account,    
    CAST(dp.OpenOccurred AS date) AS Date_,
    'OpenDataFlag' AS position_event_flag,
    SUM(dp.Amount) AS Amount_Total, 
    SUM(CASE WHEN oi.PositionID IS NOT NULL THEN dp.Amount END) AS Amount_lc, 
    COUNT(*) AS num_position_open_total, 
    COUNT(CASE WHEN oi.PositionID IS NOT NULL THEN dp.PositionID END) AS num_position_open_lc
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Dim_Customer cus ON dp.CID = cus.RealCID
INNER JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
INNER JOIN DWH_dbo.Dim_AccountType actype ON cus.AccountTypeID = actype.AccountTypeID
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout rol ON cus.CountryID = rol.CountryID
LEFT JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE GCID_Unique_Count = 1 AND IsValidETM = 1
) mda ON dp.CID = mda.CID 
LEFT JOIN BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN oi ON dp.PositionID = oi.PositionID
WHERE dp.OpenDateID >= 20240401
    AND (dp.IsPartialCloseChild = 0 OR dp.IsPartialCloseChild IS NULL)
GROUP BY 
    dp.CID,
    CAST(dp.OpenOccurred AS date), 
    rol.Region,
    dp.IsSettled,  
    di.SellCurrencyID, 
    di.InstrumentType, 
    cus.AccountTypeID,   
    CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END

UNION ALL

SELECT 
    rol.Region,
    di.SellCurrencyID, 
    di.InstrumentType, 
    cus.AccountTypeID, 
    dp.IsSettled, 
    dp.CID, 
    CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END AS Has_IBAN_Account,    
    CAST(dp.CloseOccurred AS date) AS Date_,
    'CloseDataFlag' AS position_event_flag,
    SUM(dp.Amount) AS Amount_Total, 
    SUM(CASE WHEN ci.PositionID IS NOT NULL THEN dp.Amount END) AS Amount_lc, 
    COUNT(*) AS num_position_open_total, 
    COUNT(CASE WHEN ci.PositionID IS NOT NULL THEN dp.PositionID END) AS num_position_open_lc
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Dim_Customer cus ON dp.CID = cus.RealCID
INNER JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
INNER JOIN DWH_dbo.Dim_AccountType actype ON cus.AccountTypeID = actype.AccountTypeID
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout rol ON cus.CountryID = rol.CountryID
LEFT JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE GCID_Unique_Count = 1 AND IsValidETM = 1
) mda ON dp.CID = mda.CID 
LEFT JOIN BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN ci ON dp.PositionID = ci.PositionID
WHERE dp.OpenDateID >= 20240401
    AND (dp.IsPartialCloseChild = 0 OR dp.IsPartialCloseChild IS NULL)
GROUP BY 
    dp.CID,
    CAST(dp.CloseOccurred AS date), 
    rol.Region,
    dp.IsSettled,  
    di.SellCurrencyID, 
    di.InstrumentType, 
    cus.AccountTypeID,   
    CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END