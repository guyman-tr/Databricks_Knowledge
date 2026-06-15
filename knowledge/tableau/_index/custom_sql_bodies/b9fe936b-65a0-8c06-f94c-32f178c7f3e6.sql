SELECT Date,DateID,
CASE WHEN bddpc.Country='United States' THEN 1 ELSE 0 END AS USA_IND
,GuruStatus
,COUNT(CID) AS 'NumPIs'
,SUM(ISNULL(bddpc.NumOfCopiers,0)) NumOfCopiers
,SUM(ISNULL(bddpc.CopyAUC,0)) CopyAUC
,SUM(isnull(fml.NumfFirstCopy,0)) NumfFirstCopy
FROM BI_DB_dbo.BI_DB_DailyPanel_Copy bddpc
LEFT JOIN 
(SELECT   dm.ParentCID
,COUNT(dm.CID) NumfFirstCopy
FROM DWH_dbo.Dim_Mirror dm WITH (NOLOCK)
INNER JOIN 
(SELECT CID
,MIN(MirrorID) MirrorID
FROM DWH_dbo.Dim_Mirror
GROUP BY CID) fm
ON dm.CID = fm.CID
AND dm.MirrorID = fm.MirrorID
WHERE OpenDateID BETWEEN  
cast(format(DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0),'yyyyMMdd') as int) 
AND cast(format(EOMONTH(GETDATE(),-1),'yyyyMMdd') as int)
GROUP BY dm.ParentCID
) fml
ON fml.ParentCID=bddpc.CID
WHERE  bddpc.DateID=cast(format(EOMONTH(GETDATE(),-1),'yyyyMMdd') as int)
AND bddpc.GuruStatusID>=2
GROUP BY Date,DateID
,CASE WHEN bddpc.Country='United States' THEN 1 ELSE 0 END 
,GuruStatus