select * 
from BI_DB_dbo.BI_DB_Crypto_NOP_CID nc
JOIN 
(
SELECT fsc.RealCID, fsc.CountryID, dc.Name AS CountryName
FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Country dc
	ON fsc.CountryID = dc.CountryID
) fsc 
	ON nc.CID = fsc.RealCID
where Date = <[Parameters].[Parameter 2]>