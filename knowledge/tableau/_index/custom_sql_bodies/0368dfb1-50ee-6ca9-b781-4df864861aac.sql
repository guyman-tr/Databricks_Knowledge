SELECT DATEFROMPARTS(YEAR(bdi.Date),MONTH(bdi.Date),1) ActiveDate
      ,SUM(bdi.AUM_AUA) AUM
FROM BI_DB_dbo.BI_DB_Investors_Unclustered bdi
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
ON bdi.DateID = dd.DateKey
WHERE (dd.IsLastDayOfMonth = 'Y' OR bdi.DateID = CAST(CONVERT(CHAR(8),getdate()-1,112) AS INT))
AND bdi.InstrumentType IN ('Copy Trading','Copy Portfolio')
AND bdi.DateID >=20220101
GROUP BY DATEFROMPARTS(YEAR(bdi.Date),MONTH(bdi.Date),1)