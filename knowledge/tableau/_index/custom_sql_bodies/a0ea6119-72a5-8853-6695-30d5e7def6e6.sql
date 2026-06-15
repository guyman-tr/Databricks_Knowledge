SELECT  fca.Occurred
       ,dm.CID
       ,AM
	   ,-1*fca.Amount MoneyIn
	   ,Name ClubTier
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dc.RealCID = dm.CID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl WITH (NOLOCK)
ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN #man m
ON dc.AccountManagerID = m.ManagerID
INNER JOIN DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
ON dc.RealCID=fca.RealCID
and dm.MirrorID = fca.MirrorID
WHERE dm.ParentCID IN (11132144)--,14959563
AND fca.ActionTypeID IN (15,17)
AND fca.DateID >20240107
AND dc.IsValidCustomer = 1