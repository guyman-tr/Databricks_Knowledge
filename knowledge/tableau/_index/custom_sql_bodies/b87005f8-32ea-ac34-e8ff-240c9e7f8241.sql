SELECT 
ROW_NUMBER() OVER( ORDER BY fca.Occurred ,fca.MirrorID) ID 
,ROW_NUMBER() OVER( ORDER BY fca.Occurred ,fca.MirrorID) ParentID
,0 ChildID
,fca.Occurred Date
,fca.DateID
,fca.RealCID
,CountryID
,fca.ActionTypeID
,CASE WHEN fca.ActionTypeID IN (16, 18) THEN 'MoneyOut'
WHEN fca.ActionTypeID IN (15, 17) THEN 'MoneyIn' END AS 'MI/MO'
,dat.Name ActionTypeName
,CASE WHEN dmt.MirrorTypeID IN (1, 2) THEN 'Copy Trading'
WHEN dmt.MirrorTypeID = 4 THEN 'Copy Portfolio'
ELSE dmt.MirrorTypeName END InstrumentType
,dm.ParentUserName
,fca.MirrorID
,dm.OpenOccurred StartCopy
,(-1*fca.Amount) Amount
FROM DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
inner join DWH_dbo.Dim_ActionType dat
ON dat.ActionTypeID=fca.ActionTypeID
INNER JOIN DWH_dbo.Dim_Mirror dm
ON fca.MirrorID = dm.MirrorID
INNER JOIN DWH_dbo.Dim_MirrorType dmt
ON dm.MirrorTypeID = dmt.MirrorTypeID
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
ON fca.RealCID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr1
ON fsc.DateRangeID = dr1.DateRangeID
AND dr1.FromDateID<=DateID
AND dr1.ToDateID >=DateID
WHERE fca.DateID >=CONVERT(CHAR(8),DATEADD(mm,-6, GETDATE()-1),112)
AND fca.DateID <=CONVERT(CHAR(8), GETDATE()-1, 112)
AND fca.ActionTypeID IN (15, 16, 17, 18)
AND IsValidCustomer=1
AND IsDepositor=1