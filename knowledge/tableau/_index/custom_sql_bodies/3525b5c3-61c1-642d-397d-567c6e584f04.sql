SELECT DISTINCT dss.StakingMonthID
		,dss.StakingMonth
		,dss.StakingYear
		,(CASE WHEN a.Count_Null >= 1 THEN 'Check results' ELSE 'OK' END) Flag
FROM Dealing_dbo.Dealing_Staking_Summary dss
LEFT JOIN (SELECT r.StakingMonthID
		,r.ActualCompensationType
		,r.FailReasonID
       ,count(*) Count_Null
from Dealing_dbo.Dealing_Staking_Results r
GROUP BY r.StakingMonthID
		,r.ActualCompensationType
		,r.FailReasonID
HAVING r.ActualCompensationType IS NULL AND r.FailReasonID IS NULL
) a
ON a.StakingMonthID = dss.StakingMonthID