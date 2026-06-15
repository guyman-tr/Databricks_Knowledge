SELECT
	fca.RealCID CID
	,dc.GCID
	,dc.UserName
	,dc.FirstName
	,dc.LastName
	,Email
	,dm.ParentUserName
	,fca.DateID 
	,fca.Occurred Date
    ,SUM(CASE WHEN fca.ActionTypeID IN (16, 18) THEN (-1*fca.Amount) ELSE 0 END) AS 'MoneyOut'
    ,SUM(CASE WHEN fca.ActionTypeID IN (15, 17) THEN (-1*fca.Amount) ELSE 0 END) AS 'MoneyIn'
	,dc2.Name AS Country
	,dc2.MarketingRegionManualName AS Region
	,dpl.Name AS Club
	,dm1.FirstName + ' ' + dm1.LastName AS Manager
	,vl.Credit  'Credit_30.04.24'
	,SUM(ISNULL(gc.PnL, 0) + ISNULL(gc.DetachedPosInvestment, 0) + ISNULL(gc.Dit_PnL, 0)) AS CopyPnL 
	,dm.OpenOccurred
	,dm.CloseOccurred
        ,dm.CloseDateID
	FROM  DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
	INNER JOIN DWH_dbo.Dim_Mirror dm
	ON fca.MirrorID = dm.MirrorID
	INNER JOIN DWH_dbo.Dim_MirrorType dmt
	ON dm.MirrorTypeID = dmt.MirrorTypeID
	INNER JOIN [DWH_dbo].Dim_Customer dc WITH (NOLOCK)
	ON dc.RealCID=fca.RealCID
	INNER JOIN DWH_dbo.Dim_Country dc2 WITH (NOLOCK)
	ON dc.CountryID = dc2.CountryID
	INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
	ON dc.PlayerLevelID = dpl.PlayerLevelID
	INNER JOIN DWH_dbo.Dim_Manager dm1 WITH (NOLOCK)
	ON dc.AccountManagerID = dm1.ManagerID
	LEFT JOIN DWH_dbo.V_Liabilities vl WITH (NOLOCK)
	ON vl.CID=fca.RealCID AND vl.DateID=20240430
	LEFT JOIN general.etoroGeneral_History_GuruCopiers gc WITH (NOLOCK)
	ON  dm.ParentCID=gc.ParentCID AND dm.CID=gc.CID AND gc.Timestamp=CONVERT (date,GETDATE())
	WHERE  
	 fca.DateID>= 20240401 
	AND fca.ActionTypeID IN (15, 16, 17, 18)
	AND dm.ParentCID  = 37890645
   --AND dc.IsValidCustomer=1 
   GROUP BY fca.RealCID 
	,dc.GCID
	,dc.UserName
	,dc.FirstName
	,dc.LastName
	,Email
	,dm.ParentUserName
	,fca.DateID 
	,fca.Occurred 
	,dc2.Name 
	,dc2.MarketingRegionManualName 
	,dpl.Name
	,dm1.FirstName + ' ' + dm1.LastName
	,vl.Credit 
        ,dm.OpenOccurred
	,dm.CloseOccurred
        ,dm.CloseDateID