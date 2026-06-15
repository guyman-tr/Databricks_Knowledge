SELECT EOMONTH (bddftvaa.Date) AS 'Date' ,
YEAR(bddftvaa.Date) * 100 + MONTH(bddftvaa.Date) AS Year_Month,
CASE
WHEN InstrumentTypeID IN (10) THEN 'Crypto'
ELSE 'ECC'
END AS InstrumentGroup,
bddftvaa.InstrumentTypeID,
CASE WHEN IsCopy=1 THEN 'Copy' ELSE 'Manual' END AS ActionType,
SUM(bddftvaa.VolumeOpen)VolumeOpen,
SUM(bddftvaa.VolumeClose)VolumeClose,
SUM(bddftvaa.TotalVolume)TotalVolume,
CAST(GETDATE() AS DATE) AS LoadDate
FROM  BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts bddftvaa
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
ON bddftvaa.RealCID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
ON fsc.DateRangeID = dr.DateRangeID
AND bddftvaa.DateID BETWEEN dr.FromDateID AND dr.ToDateID  
WHERE bddftvaa.DateID>=20220101
AND fsc.IsValidCustomer = 1    
GROUP BY EOMONTH (bddftvaa.Date),
YEAR(bddftvaa.Date) * 100 + MONTH(bddftvaa.Date),
CASE
WHEN InstrumentTypeID IN (10) THEN 'Crypto'
ELSE 'ECC'
END ,
bddftvaa.InstrumentTypeID,
CASE WHEN IsCopy=1 THEN 'Copy' ELSE 'Manual' END