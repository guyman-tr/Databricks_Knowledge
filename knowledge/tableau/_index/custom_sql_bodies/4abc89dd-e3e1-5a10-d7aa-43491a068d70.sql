SELECT 	
      dm.CID
	 ,dm.ParentCID
	 ,dps.Name AS PlayerStatus 
	 ,MAX(CASE WHEN dp.CID IS NULL THEN 0 ELSE 1 END) AS ActiveOpen
	 ,MAX(CASE WHEN dm1.CID IS NULL THEN 0 ELSE 1 END) AS ActiveOpen_Copy
	 ,MAX(CASE WHEN Active_Real_Stocks=1 
		OR Active_CFD_Stocks=1 
		OR Active_Real_Crypto=1 
		OR Active_CFD_Crypto=1  
		OR[Active_FX/Comm/Ind]=1 THEN 1 ELSE 0 END) AS Active_Manual
	FROM DWH_dbo.Dim_Mirror dm WITH (NOLOCK)
	JOIN DWH_dbo.Dim_Customer dc1
	ON dm.CID=dc1.RealCID 
	JOIN DWH_dbo.Dim_PlayerStatus dps
	ON dc1.PlayerStatusID = dps.PlayerStatusID
	LEFT JOIN DWH_dbo.Dim_Position dp  WITH(NOLOCK)
	ON dp.CID=dm.CID
	AND ISNULL(dp.IsPartialCloseChild,0)=0 AND dp.MirrorID  = 0 AND dp.OpenDateID>=CONVERT(CHAR(8),DATEADD(M,-6,GETDATE()-1),112)
	LEFT JOIN DWH_dbo.Dim_Mirror dm1 WITH (NOLOCK)
	ON  dm.CID=dm1.CID and dm1.OpenDateID>=CONVERT(CHAR(8),DATEADD(M,-6,GETDATE()-1),112)
	 JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd 
	ON bdcmpfd.CID=dm.CID
	WHERE dc1.IsValidCustomer = 1 AND IsDepositor=1
	AND dm.CloseDateID=0
	AND  bdcmpfd.ActiveDate>=DATEADD(M,-6,GETDATE()-1)
	GROUP BY dm.CID
	,dm.ParentCID
	,dps.Name