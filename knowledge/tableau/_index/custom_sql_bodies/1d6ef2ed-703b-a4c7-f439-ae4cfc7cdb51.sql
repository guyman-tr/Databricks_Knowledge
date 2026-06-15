select t.* 
,CASE WHEN t.EOM_Club IN ('LowBronze','HighBronze') THEN 'Bronze' ELSE t.EOM_Club END AS EOM_Club_New
,LAG(t.IsEOM_Funded_NEW,1) OVER (PARTITION BY t.CID ORDER BY ActiveDate) AS Lag_IsEOM_Funded_NEW
,bdcd.FirstNewFundedDate
,ISNULL(bdcd.Gender,'M') Gender
,dc1.MarketingRegionManualName
,dc1.Name AS CountryName
from BI_DB_dbo.[BI_DB_CID_MonthlyPanel_FullData] t with (nolock)
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd with (nolock)
ON t.CID = bdcd.CID 
JOIN DWH_dbo.Dim_Customer dc with (nolock)
ON dc.RealCID= t.CID
JOIN DWH_dbo.Dim_Country dc1 with (nolock)
ON dc.CountryID = dc1.CountryID
WHERE ActiveDate >= CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -6,GETDATE())), 0) AS DATE)
and ActiveDate <= CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0) AS DATE)
AND dc.IsDepositor=1