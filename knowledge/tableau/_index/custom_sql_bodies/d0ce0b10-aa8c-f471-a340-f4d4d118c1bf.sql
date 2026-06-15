SELECT
	fca.RealCID CID
	,dc.GCID
	,dc.UserName
	,dc.FirstName
	,dc.LastName
	,Email
	,dm.ParentUserName
	,fca.MirrorID
	,fca.DateID 
	,fca.Occurred Date
    ,SUM(CASE WHEN fca.ActionTypeID IN (16, 18) THEN (-1*fca.Amount) ELSE 0 END) AS 'MoneyOut'
    ,SUM(CASE WHEN fca.ActionTypeID IN (15, 17) THEN (-1*fca.Amount) ELSE 0 END) AS 'MoneyIn'
	--,sum( case WHEN fca.ActionTypeID  = 35 THEN fca.Amount ELSE 0 END ) AS 'Dividend'
	,dc2.Name AS Country
	,dc2.MarketingRegionManualName AS Region
	,dpl.Name AS Club
        ,dm1.ManagerID
	,dm1.FirstName + ' ' + dm1.LastName AS Manager
	,vl.Credit  'Credit_30.04.24'
	,sum(bdppl.PositionPnL) PnL
	,SUM(dm.RealziedPnL) RealizedPnL
	,sum(bdppl.PositionPnL) AS  CopyPnL
	,dm.OpenOccurred
	,dm.CloseOccurred
    ,dm.CloseDateID
	,reg.Name AS Regulation
	,dc.IsCreditReportValidCB
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
	LEFT JOIN (
	SELECT bdppl.MirrorID, sum(bdppl.PositionPnL) PositionPnL, SUM(bdppl.Amount) Amount
	FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
	WHERE  bdppl.Date = cast((GETDATE() -1) AS DATE)
	GROUP BY bdppl.MirrorID
	) bdppl	ON bdppl.MirrorID = dm.MirrorID
	INNER JOIN DWH_dbo.Dim_Regulation reg WITH (NOLOCK)
	ON dc.RegulationID = reg.ID
	WHERE  
	 fca.DateID>= 20240520 
	AND fca.ActionTypeID IN (15, 16, 17, 18) --35
	AND dm.ParentCID  = 37890645
   AND dc.IsValidCustomer=1 
   GROUP BY fca.RealCID 
	,dc.GCID
	,dc.UserName
	,dc.FirstName
	,dc.LastName
	,Email
	,dm.ParentUserName
	,fca.MirrorID
	,fca.DateID 
	,fca.Occurred 
	,dc2.Name 
	,dc2.MarketingRegionManualName 
	,dpl.Name
	,dm1.ManagerID
	,dm1.FirstName + ' ' + dm1.LastName
	,vl.Credit 
	,dm.OpenOccurred
	,dm.CloseOccurred
	,dm.CloseDateID
	,reg.Name
	,dc.IsCreditReportValidCB