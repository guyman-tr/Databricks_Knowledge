SELECT 
	ActiveDate, Country, EOM_Club, n_Month_Retention,
    SUM(Opened_Copy)    Opened_Copy,
    SUM(Opened_Stocks)  Opened_Stocks,
    SUM(Opened_Crypto)  Opened_Crypto,
    SUM(Retained_Copy)  Retained_Copy,
    SUM(Retained_Stocks) Retained_Stocks,
    SUM(Retained_Crypto) Retained_Crypto
  FROM 
  (SELECT 
      f.CID, f.ActiveDate, f.Country, f.EOM_Club, DATEDIFF(MONTH, f.ActiveDate, f2.ActiveDate) n_Month_Retention,
      f.IsOpen_Copy Opened_Copy,  
CASE WHEN f.ActiveOpen_Real_Stocks>f.ActiveOpen_CFD_Stocks THEN f.ActiveOpen_Real_Stocks ELSE f.ActiveOpen_CFD_Stocks END AS Opened_Stocks,
CASE WHEN f.ActiveOpen_Real_Crypto > f.ActiveOpen_CFD_Crypto THEN f.ActiveOpen_Real_Crypto ELSE f.ActiveOpen_CFD_Crypto END AS Opened_Crypto,
CASE WHEN f.IsOpen_Copy = 1 THEN f2.Active_Copy END Retained_Copy,  
CASE WHEN (CASE WHEN f.ActiveOpen_Real_Stocks > f.ActiveOpen_CFD_Stocks THEN f.ActiveOpen_Real_Stocks ELSE f.ActiveOpen_CFD_Stocks end )=1
THEN (CASE WHEN f2.Active_CFD_Stocks > f2.Active_Real_Stocks THEN f2.Active_CFD_Stocks ELSE f2.Active_Real_Stocks END) END Retained_Stocks,
CASE WHEN (CASE WHEN f.ActiveOpen_Real_Crypto > f.ActiveOpen_CFD_Crypto THEN f.ActiveOpen_Real_Crypto ELSE f.ActiveOpen_CFD_Crypto END )=1
THEN (CASE WHEN f2.Active_CFD_Crypto > f2.Active_Real_Crypto THEN f2.Active_CFD_Crypto ELSE f2.Active_Real_Crypto END) END Retained_Crypto  
  FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] f
  JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] f2 
	ON f.CID = f2.CID AND f2.ActiveDate BETWEEN dateADD(MONTH,1,f.ActiveDate) AND dateADD(MONTH,6,f.ActiveDate) 
    AND f2.ActiveDate BETWEEN dateADD(MONTH,-12,GETDATE()) AND  dateADD(MONTH,-1,GETDATE())
  WHERE 
    f.ActiveDate BETWEEN DATEADD(MONTH,-13,GETDATE()) AND  DATEADD(MONTH,-2,GETDATE())
	) as user_data 
  GROUP BY ActiveDate, Country, EOM_Club, n_Month_Retention