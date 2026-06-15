SELECT
	pan.CID
   ,pan.FTD_Month
   ,pan.FirstAction
   ,pan.Country
   ,pan.[Region]
   ,[dc].[City]

   , (CASE WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('ne', 'ca', 'dh', 'sr', 'ts', 'dl') THEN 'North East' 
  WHEN (lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('la', 'fy', 'pr', 'bb', 'hx', 'ol', 'bl', 'wn', 'la', 'wa', 'sk', 'cw', 'im') OR lower(substring(REPLACE(dc.Zip, ' ', ''),1,1)) = 'm') THEN 'North West' 
  WHEN (lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('bd', 'hg', 'ls', 'wf', 'hd', 'dn', 'hu', 'yo') OR lower(substring(REPLACE(dc.Zip, ' ', ''),1,1)) = 's') THEN 'Yorkshire & Humber' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('de', 'ng', 'ln', 'le', 'nn', 'ox', 'hp', 'rg') THEN 'East Midlands' 
  WHEN (lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('st', 'tf', 'wv', 'ws', 'dy', 'cv', 'wr', 'hr') OR lower(substring(REPLACE(dc.Zip, ' ', ''),1,1)) = 'b') THEN 'West Midlands' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('pe', 'nr', 'ip', 'mk', 'sg', 'cb', 'co', 'cm', 'lu') THEN 'East of England' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('gu','rh','bn','tn','me','ct') THEN 'South West' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('gl', 'bs', 'sn', 'ba', 'sp', 'so ', 'po', 'bh', 'dt', 'ta', 'ex', 'tq ', 'pl', 'tr') THEN 'South East' 
  WHEN (lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('wc', 'ec', 'sw', 'sw', 'nw', 'se', 'ss', 'rm', 'da', 'br', 'ig', 'cr', 'sm', 'kt', 'tw', 'sl', 'ub', 'ha', 'wd', 'al', 'en') OR lower(substring(REPLACE(dc.Zip, ' ', ''),1,1)) IN ('n','w', 'e')) THEN 'London' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('ll','ch','sy','ld','sa','cf','np') THEN 'Wales' 
  WHEN (lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) IN ('dg','td','eh','ml','ka','pa','fk','ky','ph','dd','ab','iv','kw','ze') OR lower(substring(REPLACE(dc.Zip, ' ', ''),1,1)) = 'g') THEN 'Scotland' 
  WHEN lower(substring(REPLACE(dc.Zip, ' ', ''),1,2)) = 'bt' THEN 'East Midlands' 
  ELSE 'N/A' END) AS RegionInUK

   ,fd.Manager
   ,fd.Club
   ,pan.Active_Month RevenueMonth
   ,[Revenue_Total]
   ,fd.RealizedEquity
   ,dcl.ClusterDetail

FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] pan WITH (NOLOCK)
LEFT JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
	ON fd.CID = pan.CID
LEFT JOIN [BI_DB_dbo].[BI_DB_CID_DailyCluster] dcl WITH (NOLOCK)
	ON pan.CID = dcl.CID
		AND dcl.IsLastCluster = 1
JOIN [DWH_dbo].Dim_Customer dc WITH (NOLOCK)
	ON pan.CID = dc.RealCID
WHERE pan.Region IN ('UK', 'German')
AND pan.ActiveDate >= DATEADD(MONTH, -4, GETDATE())
AND [Revenue_Total] >= 10