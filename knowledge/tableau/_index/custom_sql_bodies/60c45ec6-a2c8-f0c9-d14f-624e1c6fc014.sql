SELECT a.Club
      ,CAST(a.eMoneyUsers AS FLOAT) / CAST(a.TargetPopulation AS FLOAT) AS 'Percentage'
FROM( 
SELECT Club
	  ,SUM(CASE WHEN FunnelStage = 'IseMoneyAccount' THEN FunnelCount ELSE 0 END) AS 'eMoneyUsers'
	  ,SUM(CASE WHEN FunnelStage = 'IsVerifiedFTDPlus2Weeks' THEN FunnelCount ELSE 0 END) AS 'TargetPopulation'
FROM eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated WITH(NOLOCK)
WHERE Club IS NOT NULL
GROUP BY Club) a