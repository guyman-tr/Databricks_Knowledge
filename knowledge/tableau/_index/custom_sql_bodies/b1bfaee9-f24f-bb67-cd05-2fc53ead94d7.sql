SELECT fm.ActiveDate 
, fm.CID
, fm.AccountManager
, fm.EOM_Club Club
, fm.Country
, fm.ClusterDetail
, f5a.FirstActionDate
, f5a.FirstAction
--, MAX(fm.ActiveOpen) OVER (PARTITION BY f5a.CID) ActiveOpen
, fm.ActiveOpen
, fm.Revenue_Total
, sfu.Manager
, sfu.Department
, sfu.Desk_CS
, syn.desk Desk
,vl.RealizedEquity
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
LEFT JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK) 
ON fm.AccountManager = dm1.FirstName +' '+dm1.LastName 
LEFT JOIN [BI_DB].[dbo].[BI_DB_First5Actions] f5a WITH (NOLOCK)
ON fm.CID = f5a.CID
LEFT JOIN BI_DB.dbo.BI_DB_SF_Users  sfu WITH (NOLOCK)
ON dm1.ManagerID = sfu.AccountManagerID
LEFT JOIN [BI_DB].[dbo].[BI_DB_AccountManagers_List] syn WITH (NOLOCK)
ON dm1.ManagerID = syn.manager_id
LEFT JOIN [DWH].[dbo].[V_Liabilities] vl WITH (NOLOCK)
ON fm.CID = vl.CID 
AND vl.DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
WHERE fm.ActiveDate >=DATEFROMPARTS(YEAR(DATEADD(MONTH,-2,GETDATE()-1)), MONTH(DATEADD(MONTH,-3,GETDATE()-1)),1)