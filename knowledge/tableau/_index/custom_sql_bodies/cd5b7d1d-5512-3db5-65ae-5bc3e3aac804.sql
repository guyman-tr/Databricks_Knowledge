SELECT bdccd.*,x.Daily_CO_Amount
FROM BI_DB_dbo.BI_DB_CO_Cluster_Daily bdccd
LEFT JOIN (
SELECT fca.RealCID,fca.DateID,SUM(fca.Amount) Daily_CO_Amount
FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.ActionTypeID=8 AND fca.DateID>=20240101 AND fca.DateID<20250701
GROUP BY fca.RealCID,fca.DateID) x ON x.RealCID=bdccd.CID AND bdccd.Report_Date_ID=x.DateID