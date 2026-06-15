SELECT r.StakingMonthID
		,r.StakingMonth
		,r.StakingYear
		,r.InstrumentID
		,r.Currency
		,COUNT(DISTINCT r.CID) AS NumberOfCIDs
		,r.ActualCompensationType
        ,sum(r.Client_Airdrop) as Airdrop_Units
        ,max(r.UpdateDate) as UpdateDate
		,CASE WHEN r.ActualCompensationType = 'Airdrop' then a.USD_Value
			  WHEN r.ActualCompensationType = 'Cash' THEN sum(r.USD_Compensation) END USD_Value
FROM 
( --New 05.04.2026 -- Added case  r.ActualCompensationType IS NULL ...
SELECT  r.StakingMonthID
		,r.StakingMonth
		,r.StakingYear
		,r.InstrumentID
		,r.Currency
		,r.CID
		,CASE WHEN r.ActualCompensationType IS NULL THEN 'Airdrop' ELSE r.ActualCompensationType END AS ActualCompensationType 
		,r.Client_Airdrop
		,r.UpdateDate
		,r.USD_Compensation
FROM Dealing_dbo.Dealing_Staking_Results_US AS r 
--WHERE exists (SELECT top 1* FROM Dealing_dbo.Dealing_Staking_Compensation_US c WHERE c.StakingMonthID = r.StakingMonthID) --New 09.04.2026
) as r

LEFT JOIN (
			SELECT LEFT(CAST(CONVERT(VARCHAR(8), DATEADD(MONTH, -1, dp.OpenOccurred), 112) AS INT),6) AS MonthBeforeOpenID
				,dp.InstrumentID
				,sum(dp.InitialAmountCents/100) AS USD_Value
			FROM DWH_dbo.Dim_Position AS dp
			WHERE dp.OpenDateID >= 20251101
			 AND dp.InstrumentID IN (SELECT DISTINCT dss.InstrumentID FROM Dealing_dbo.Dealing_Staking_Summary_US dss)
			 AND dp.IsAirDrop = 1
			 AND dp.CID IN (SELECT DISTINCT CID FROM Dealing_dbo.Dealing_Staking_Results_US) --New 16.11.25
			 AND dp.OpenPositionReasonID=11 --new 05.04.2026 
			GROUP BY dp.InstrumentID, LEFT(CAST(CONVERT(VARCHAR(8), DATEADD(MONTH, -1, dp.OpenOccurred), 112) AS INT),6)
			) a
 ON r.StakingMonthID = a.MonthBeforeOpenID 
 AND r.InstrumentID = a.InstrumentID 
 AND r.ActualCompensationType = 'Airdrop'
--WHERE exists (SELECT top 1* FROM Dealing_dbo.Dealing_Staking_Compensation_US c WHERE c.StakingMonthID = r.StakingMonthID) --New 09.04.2026
GROUP BY r.StakingMonthID
		,r.StakingMonth
		,r.StakingYear
        ,r.InstrumentID
		,r.Currency
		,r.ActualCompensationType
        ,a.USD_Value