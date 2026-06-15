SELECT 
dems.EvMatchStatusName,
CASE WHEN (dems.EvMatchStatusName='None' OR  dems.EvMatchStatusName IS NULL) THEN 'Manual Verification'
WHEN (dems.EvMatchStatusName='NotVerified' OR dems.EvMatchStatusName='PartiallyVerified') THEN 'Not Fully Verified'
else 'EV Check' END AS EVCheck_ind,

DATEFROMPARTS(YEAR(bdcd.VerificationLevel2Date),MONTH(bdcd.VerificationLevel2Date),1) AS  Date,
bdcd.NewMarketingRegion AS NewMarketingRegion,

SUM(CASE WHEN dc.IsDepositor=1 THEN 1 else 0 end) AS depositors,
COUNT(dc.RealCID) AS clients_amount, GETDATE() AS 'Update_date'
FROM  DWH.dbo.Dim_Customer dc with (nolock) 
LEFT JOIN DWH.dbo.Dim_EvMatchStatus dems 
ON dems.EvMatchStatusID=dc.EvMatchStatus
LEFT JOIN DWH.dbo.Dim_Country dcc ON dcc.CountryID=dc.CountryID
INNER JOIN BI_DB.dbo.BI_DB_CIDFirstDates bdcd 
  ON dc.RealCID=bdcd.CID 
					AND		CAST(bdcd.VerificationLevel2Date AS date) > EOMONTH(DATEADD(MONTH,-7,GETDATE())+1) AND  CAST(bdcd.VerificationLevel2Date AS date)   <= EOMONTH(DATEADD(MONTH,-1,GETDATE())+1)
WHERE dc.IsValidCustomer = 1
-- CAST(dc.RegisteredReal AS date) > EOMONTH(DATEADD(MONTH,-7,GETDATE())+1) AND  CAST(dc.RegisteredReal AS date)   <= EOMONTH(DATEADD(MONTH,-1,GETDATE())+1)
GROUP BY EvMatchStatusName,
CASE WHEN (dems.EvMatchStatusName='None' OR  dems.EvMatchStatusName IS NULL) THEN 'Manual Verification'
WHEN (dems.EvMatchStatusName='NotVerified' OR dems.EvMatchStatusName='PartiallyVerified') THEN 'Not Fully Verified'
else 'EV Check' END,
DATEFROMPARTS(YEAR(bdcd.VerificationLevel2Date),MONTH(bdcd.VerificationLevel2Date),1) ,
bdcd.NewMarketingRegion