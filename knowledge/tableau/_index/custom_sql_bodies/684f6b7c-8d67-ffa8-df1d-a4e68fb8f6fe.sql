Select cr.CID, UserName, cr.Occurred,
CASE WHEN cr.std< 0.00034 then 1
WHEN cr.std< 0.00068 then 2
WHEN cr.std< 0.00204 then 3 
WHEN cr.std< 0.00340 then 4
WHEN cr.std< 0.00544 then 5
WHEN cr.std< 0.00816 then 6
WHEN cr.std< 0.01361 then 7
WHEN cr.std< 0.02722 then 8
WHEN cr.std< 0.04763 then 9
WHEN cr.std>=0.04763 then 10 else 0 end as RiskScore
From BI_DB.dbo.DWH_CIDsRisk cr
Where Occurred >= DateAdd(Month,-2,GetDate()) and GuruStatusID IN (2,3,4,5)