SELECT *
FROM (
SELECT p.Date
		,EOMONTH(p.Date) EndOfMonth
		,dsp.Currency
		,sum(p.NOP) AS Total_Holdings_USD
		,sum(p.AmountInUnitsDecimal) AS Total_Holdings_Units
		,o.OptedInUnits AS Total_Eligible_Units_Opted_In
		,o.Units_AvailableForStaking AS Total_Staked_Units
		,o.Units_AvailableForStaking / sum(p.AmountInUnitsDecimal)  AS Staking_Ratio_Of_Total_Holdings
		,o.Units_AvailableForStaking / o.OptedInUnits AS Staking_Ratio_Of_Eligible
FROM BI_DB_dbo.BI_DB_PositionPnL p
JOIN Dealing_dbo.Dealing_Staking_Parameters_US dsp
 ON p.InstrumentID = dsp.InstrumentID
LEFT JOIN DWH_dbo.Dim_Customer dc
 ON dc.RealCID = p.CID
LEFT JOIN (SELECT Date
				,InstrumentID
				,sum(OptedInUnits) OptedInUnits
				,sum(Units_AvailableForStaking) Units_AvailableForStaking
			FROM Dealing_dbo.Dealing_Staking_OptedOut_US
			WHERE Date >= dateadd(d,-32,getdate())
			GROUP BY Date
					, InstrumentID) o
 ON p.Date = o.Date AND p.InstrumentID = o.InstrumentID
WHERE p.DateID >= CAST(CONVERT(VARCHAR(8), dateadd(d,-32,getdate()), 112) AS INT)
	AND p.IsSettled = 1
	AND dc.IsValidCustomer = 1
        AND p.MirrorID = 0 -- NO Copy 
        AND dc.RegulationID = 8 --FINCEN+FINRA
GROUP BY p.Date
		,dsp.Currency
		,o.OptedInUnits
		,o.Units_AvailableForStaking
		) a
		WHERE a.Date = a.EndOfMonth