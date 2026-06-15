SELECT  a.*, 
COUNT(DISTINCT dm.CID) num_Copiers, 
COUNT(dm.ParentCID) num_Copied_for_Avg ,
COUNT(DISTINCT CASE WHEN (mp.Active_Copy>0 OR [ActiveOpen_Copy]>0) 
     AND [Active_Real_Stocks]=0 AND [Active_CFD_Stocks] =0 AND [Active_Real_Crypto]=0 AND [Active_CFD_Crypto] =0 AND [Active_FX/Comm/Ind]=0
	 AND [ActiveOpen_Real_Stocks]=0 AND [ActiveOpen_CFD_Stocks] =0 AND [ActiveOpen_Real_Crypto]=0 AND [ActiveOpen_CFD_Crypto] =0 AND [ActiveOpen_FX/Comm/Ind] =0
	 THEN mp.CID END ) only_copy
FROM 
(SELECT a.Date,  COUNT(DISTINCT a.CID) num_Copied, COUNT(CASE WHEN a.CopyType='PI' THEN a.CID END)  num_Copie_PI 
FROM BI_DB.dbo.BI_DB_CopyDailyData a
WHERE a.Date=EOMONTH(a.Date)
AND a.Date>='2021-01-01' 
AND a.NumOfCopiers>0
GROUP BY  a.Date) a
LEFT JOIN [DWH].[dbo].Dim_Mirror dm
ON (a.Date between CAST(dm.OpenOccurred AS DATE) AND CAST(dm.CloseOccurred AS DATE)
    OR a.Date >= CAST(dm.OpenOccurred AS DATE) AND dm.IsActive=1)
LEFT JOIN BI_DB.dbo.BI_DB_CID_MonthlyPanel_FullData mp
ON mp.CID = dm.CID
AND DATEADD(mm, DATEDIFF(mm, 0, a.Date), 0)=mp.ActiveDate
GROUP BY a.Date, num_Copied, num_Copie_PI