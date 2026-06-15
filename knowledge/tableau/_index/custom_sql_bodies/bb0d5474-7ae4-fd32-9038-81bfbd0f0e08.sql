SELECT Date
,ParentUserName
,frst.NewMarketingRegion
,CASE WHEN InstrumentType='Copy Portfolio' THEN 'Portfolio'
WHEN InstrumentType='Copy Trading' AND GuruStatusID >= 2 THEN 'PI'
WHEN InstrumentType='Copy Trading' AND GuruStatusID < 2 THEN 'Non-PI' END as CopyType 
,InstrumentType
,sum([MoneyIn]) AS MoneyIn
,sum([MoneyOut]) AS MoneyOut
,sum([MoneyIn] - [MoneyOut]) AS NetMI
,id.UpdateDate
,ISNULL(id.IsDepositor, 0) isDepositor

from BI_DB_dbo.BI_DB_InvestorsDetail  id
Left JOIN DWH_dbo.Dim_Customer dc1 WITH (NOLOCK) ON id.ParentUserName = dc1.UserName
Left JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst ON frst.CID = id.RealCID

where [DateID]>=20240101
--CAST(CONVERT(VARCHAR(8), CAST(DATEFROMPARTS(YEAR(DATEADD(YEAR, -1, GETDATE())), 1, 1) AS DATE), 112) AS INT)
AND InstrumentType IN ('Copy Trading','Copy Portfolio')
group by  Date
,ParentUserName
,frst.NewMarketingRegion
,CASE WHEN InstrumentType='Copy Portfolio' THEN 'Portfolio'
WHEN InstrumentType='Copy Trading' AND GuruStatusID >= 2 THEN 'PI'
WHEN InstrumentType='Copy Trading' AND GuruStatusID < 2 THEN 'Non-PI' END 
,InstrumentType
,id.UpdateDate
,ISNULL(id.IsDepositor, 0)