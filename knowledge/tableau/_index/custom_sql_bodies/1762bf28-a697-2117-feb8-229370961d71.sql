SELECT a.Club
      ,CAST(a.eMoneyUsers AS FLOAT) / CAST(a.TargetPopulation AS FLOAT) AS 'Percentage'
FROM( 
SELECT Club
	  ,SUM(CASE WHEN FunnelStage = 'IseMoneyAccount' THEN FunnelCount ELSE 0 END) AS 'eMoneyUsers'
	  ,SUM(CASE WHEN FunnelStage = 'IsVerifiedFTDPlus2Weeks' THEN FunnelCount ELSE 0 END) AS 'TargetPopulation'
FROM eMoney_DEV.dbo.eMoney_Acquisition_Funnel_Aggregated
WHERE Club IS NOT NULL AND Country = 'United Kingdom'
GROUP BY Club) a