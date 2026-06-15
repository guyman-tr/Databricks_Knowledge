select
 child.ID 
,0 ParentID
,child.ID  ChildID
,Occurred 
,DateID 
,RealCID
,child.CountryID
,child.ActionTypeID
,CASE WHEN child.ActionTypeID IN (16, 18,4) THEN 'MoneyOut'
WHEN child.ActionTypeID IN (15, 17,1) THEN 'MoneyIn'
else dat.Name END AS 'MI/MO'
,dat.Name ActionTypeName
,CASE WHEN child.MirrorID>0 THEN 
CASE WHEN dmt.MirrorTypeID IN (1, 2) THEN 'Copy Trading'
WHEN dmt.MirrorTypeID = 4 THEN 'Copy Portfolio'
ELSE dmt.MirrorTypeName END  
WHEN child.ActionTypeID IN (7,8) THEN dat.Name
ELSE  di.InstrumentType END  InstrumentType
,CASE WHEN child.MirrorID>0 THEN dm.ParentUserName 
WHEN child.ActionTypeID IN (7,8) THEN dat.Name 
ELSE  di.InstrumentDisplayName END  ParentUserName
,child.MirrorID
,dm.OpenOccurred StartCopy
,ABS(child.Amount) AS Amount
,ActionRank
,child.Club
,child.Country
,child.Region
FROM
(SELECT 
Parent.ID
,Parent.Date  ParentDate
,Parent.MirrorID ParentMirrorID
,fca.Occurred 
,fca.DateID 
,fca.RealCID
,fca.ActionTypeID 
,fca.MirrorID
,fca.Amount
,fca.InstrumentID
,Parent.CountryID
,ROW_NUMBER() OVER(PARTITION BY Parent.ID ORDER BY fca.Occurred desc) ActionRank 
 ,MarketingRegionManualName Region 
 ,dc1.Name Country
 ,dp.Name Club
FROM  #Parent Parent
 join DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
 ON fca.RealCID=Parent.RealCID 
AND fca.Occurred>=DATEADD(dd,-7,Parent.[Date])
AND fca.Occurred<=Parent.Date
AND Parent.ActionTypeID IN (15, 17)
join DWH_dbo.Dim_Customer dc
 ON fca.RealCID = dc.RealCID
 join [DWH_dbo].[Dim_Country] dc1
 on dc.CountryID = dc1.CountryID
 JOIN [DWH_dbo].[Dim_PlayerLevel] dp
 on dp.PlayerLevelID = dc.PlayerLevelID
WHERE  fca.ActionTypeID IN (4,16,18,7) 
UNION
SELECT 
	Parent.ID
,Parent.Date ParentDate
,Parent.MirrorID ParentMirrorID
,fca.Occurred 
,fca.DateID 
,fca.RealCID
,fca.ActionTypeID 
,fca.MirrorID
,fca.Amount
,fca.InstrumentID
,Parent.CountryID
,ROW_NUMBER() OVER(PARTITION BY Parent.ID ORDER BY fca.Occurred) ActionRank 
 ,MarketingRegionManualName Region 
 ,dc1.Name Country
 ,dp.Name Club
FROM  #Parent Parent
 join DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
 ON fca.RealCID=Parent.RealCID 
AND fca.Occurred>=Parent.Date
AND fca.Occurred<=DATEADD(dd,7,Parent.Date) 
AND Parent.ActionTypeID IN (16, 18)
join DWH_dbo.Dim_Customer dc
 ON fca.RealCID = dc.RealCID
 join [DWH_dbo].[Dim_Country] dc1
 on dc.CountryID = dc1.CountryID
 JOIN [DWH_dbo].[Dim_PlayerLevel] dp
 on dp.PlayerLevelID = dc.PlayerLevelID

WHERE  fca.ActionTypeID IN (1,15,17,8) 
)child
LEFT JOIN DWH_dbo.Dim_Instrument di WITH (NOLOCK)
ON child.InstrumentID = di.InstrumentID
LEFT JOIN DWH_dbo.Dim_Mirror dm
ON child.MirrorID = dm.MirrorID
LEFT JOIN DWH_dbo.Dim_MirrorType dmt
ON dm.MirrorTypeID = dmt.MirrorTypeID
LEFT join DWH_dbo.Dim_ActionType dat
ON dat.ActionTypeID=child.ActionTypeID